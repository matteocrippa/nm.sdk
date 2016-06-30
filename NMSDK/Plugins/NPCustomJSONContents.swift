//
//  NPCustomJSONContents.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 30/06/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPCustomJSONContents: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.CustomJSONObjects.name
    }
    override var version: String {
        return "0.1"
    }
    override var commands: [String: RunHandler] {
        return ["sync": sync, "index": index, "read": read, "store-online-resource": storeOnlineResource]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["download-reaction": download]
    }
    
    // MARK: Sync
    private func sync(arguments: JSON, sender: String?) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPCustomJSONContents.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPCustomJSONContents.self, text: "Downloading json object reactions...", symbol: .Download)
        APRecipeReactions.getJSONObjects { (objects, status) in
            if status != .OK {
                Console.error(NPCustomJSONContents.self, text: "Cannot download json object reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadCustomJSONObjectReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
                return
            }
            
            Console.info(NPCustomJSONContents.self, text: "Saving json object reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for content in objects {
                Console.infoLine(content.id, symbol: .Add)
                
                self.hub?.cache.store(content, inCollection: "Reactions", forPlugin: self)
            }
            Console.infoLine("json object reactions saved: \(objects.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
        }
        
        return PluginResponse.ok(command: "sync")
    }
    
    // MARK: Read
    private func index(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resources: [APJSONObject] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
            return PluginResponse.ok(JSON(dictionary: ["reactions": [String]()]), command: "index")
        }
        
        var keys = [String]()
        for resource in resources {
            keys.append(resource.id)
        }
        
        return PluginResponse.ok(JSON(dictionary: ["reactions": keys]), command: "index")
    }
    private func read(arguments: JSON, sender: String?) -> PluginResponse {
        guard let id = arguments.string("content-id") else {
            Console.commandError(NPCustomJSONContents.self, command: "read", requiredParameters: ["content-id"])
            return PluginResponse.cannotRun("read", requiredParameters: ["content-id"])
        }
        
        guard let reaction = json(id) else {
            Console.commandWarning(NPCustomJSONContents.self, command: "read", cause: "JSON \"\(id) \" not found")
            return PluginResponse.warning("JSON \"\(id)\" not found", command: "read")
        }
        
        return PluginResponse.ok(reaction.json, command: "read")
    }
    private func json(id: String) -> APRecipeContent? {
        guard let resource: APRecipeContent = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
    
    // MARK: Store
    private func download(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let pluginHub = hub, id = arguments.string("id"), appToken = arguments.string("app-token") else {
            Console.commandError(NPCustomJSONContents.self, command: "download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        APRecipeReactions.getJSONObject(id) { (object, status) in
            guard let c = object where status.codeClass == .Successful else {
                var error = PluginResponse.cannotRun("download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"], cause: "HTTPStatusCode \(status.rawValue)")
                self.setDownloadResult(status, toResponse: &error)
                
                Console.error(NPCustomJSONContents.self, text: "Cannot download json object \(id)")
                Console.errorLine("HTTPStatusCode: \(status.description)")
                completionHandler?(response: error)
                return
            }
            
            Console.info(NPCustomJSONContents.self, text: "JSON reaction \(c.id) has been downloaded and cached")
            pluginHub.cache.store(c, inCollection: "Reactions", forPlugin: self)
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["id": id, "content": object!.json.dictionary, "result": HTTPSimpleStatusCode.OK.rawValue]), command: "download-reaction"))
        }
    }
    private func setDownloadResult(status: HTTPStatusCode, inout toResponse response: PluginResponse) {
        var dictionary = response.content.dictionary
        dictionary["download-status"] = HTTPSimpleStatusCode(statusCode: status).rawValue
        
        response = PluginResponse(status: response.status, content: JSON(dictionary: dictionary), command: response.command)
    }
    private func storeOnlineResource(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resource = arguments.object("resource") as? APIResource else {
            Console.commandError(NPCustomJSONContents.self, command: "store-online-resource", requiredParameters: ["resource"])
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"])
        }
        
        guard let pluginHub = hub else {
            Console.commandError(NPCustomJSONContents.self, command: "store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
        }
        
        Console.info(NPCustomJSONContents.self, text: "Content reaction \(resource.id) has been stored")
        pluginHub.cache.store(APJSONObject.makeWithResource(resource), inCollection: "Reactions", forPlugin: self)
        return PluginResponse.ok(command: "store-online-resource")
    }
}
