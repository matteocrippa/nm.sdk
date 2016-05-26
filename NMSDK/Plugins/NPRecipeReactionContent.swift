//
//  NPRecipeReactionContent.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPRecipeReactionContent: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.Contents.name
    }
    override var version: String {
        return "0.4"
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
            Console.commandError(NPRecipeReactionContent.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPRecipeReactionContent.self, text: "Downloading content reactions...", symbol: .Download)
        APRecipeReactions.getContents { (contents, status) in
            if status != .OK {
                Console.error(NPRecipeReactionContent.self, text: "Cannot download content reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadContentReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
                return
            }
            
            Console.info(NPRecipeReactionContent.self, text: "Saving content reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for content in contents {
                Console.infoLine(content.id, symbol: .Add)
                
                self.hub?.cache.store(content, inCollection: "Reactions", forPlugin: self)
            }
            Console.infoLine("content reactions saved: \(contents.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
        }
        
        return PluginResponse.ok(command: "sync")
    }
    
    // MARK: Read
    private func index(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resources: [APRecipeContent] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
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
            Console.commandError(NPRecipeReactionContent.self, command: "read", requiredParameters: ["content-id"])
            return PluginResponse.cannotRun("read", requiredParameters: ["content-id"])
        }
        
        guard let reaction = content(id) else {
            Console.commandWarning(NPRecipeReactionContent.self, command: "read", cause: "Content \"\(id) \" not found")
            return PluginResponse.warning("Content \"\(id)\" not found", command: "read")
        }
        
        return PluginResponse.ok(reaction.json, command: "read")
    }
    private func content(id: String) -> APRecipeContent? {
        guard let resource: APRecipeContent = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
    
    // MARK: Store
    private func download(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let pluginHub = hub, id = arguments.string("id"), appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipeReactionContent.self, command: "download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        APRecipeReactions.getContent(id) { (content, status) in
            guard let c = content where status.codeClass == .Successful else {
                var error = PluginResponse.cannotRun("download-reaction", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"], cause: "HTTPStatusCode \(status.rawValue)")
                self.setDownloadResult(status, toResponse: &error)
                
                Console.error(NPRecipeReactionContent.self, text: "Cannot download content \(id)")
                Console.errorLine("HTTPStatusCode: \(status.description)")
                completionHandler?(response: error)
                return
            }
            
            Console.info(NPRecipeReactionContent.self, text: "Content reaction \(c.id) has been downloaded and cached")
            pluginHub.cache.store(c, inCollection: "Reactions", forPlugin: self)
            
            Console.infoLine("Removing images (\(c.imageIdentifiers.count))...")
            if let response = self.hub?.send("remove-images", fromPluginNamed: self.name, toPluginNamed: CorePlugin.ImageCache.name, withArguments: JSON(dictionary: ["identifiers": c.imageIdentifiers])) where response.status == .OK {
                Console.infoLine("OK")
            }
            else {
                Console.warningLine("Cannot remove images (\(c.imageIdentifiers.count))...")
            }
            
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["id": id, "content": content!.json.dictionary, "result": HTTPSimpleStatusCode.OK.rawValue]), command: "download-reaction"))
        }
    }
    private func setDownloadResult(status: HTTPStatusCode, inout toResponse response: PluginResponse) {
        var dictionary = response.content.dictionary
        dictionary["download-status"] = HTTPSimpleStatusCode(statusCode: status).rawValue
        
        response = PluginResponse(status: response.status, content: JSON(dictionary: dictionary), command: response.command)
    }
    private func storeOnlineResource(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resource = arguments.object("resource") as? APIResource, content = APRecipeContent.makeWithResource(resource) else {
            Console.commandError(NPRecipeReactionContent.self, command: "store-online-resource", requiredParameters: ["resource"])
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"])
        }
        
        guard let pluginHub = hub else {
            Console.commandError(NPRecipeReactionContent.self, command: "store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
        }
        
        Console.info(NPRecipeReactionContent.self, text: "Content reaction \(resource.id) has been stored")
        pluginHub.cache.store(content, inCollection: "Reactions", forPlugin: self)
        return PluginResponse.ok(command: "store-online-resource")
    }
}
