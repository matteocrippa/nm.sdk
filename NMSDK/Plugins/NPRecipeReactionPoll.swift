//
//  NPRecipeReactionPoll.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPRecipeReactionPoll: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.Polls.name
    }
    override var version: String {
        return "0.4"
    }
    override var commands: [String: RunHandler] {
        return ["sync": sync, "index": index, "read": read, "store-online-resource": storeOnlineResource]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["post": post, "download-reaction-if-missing": downloadIfMissing]
    }
    
    // MARK: Async
    private func post(arguments: JSON, sender: String?, handler: ((response: PluginResponse) -> Void)?) {
        guard let pollID = arguments.string("notification-id"), answerValue = arguments.int("answer"), answer = APRecipePollAnswer(rawValue: answerValue) else {
            Console.commandError(NPRecipeReactionPoll.self, command: "post", requiredParameters: ["notification-id", "answer"])
            handler?(response: PluginResponse.cannotRun("post", requiredParameters: ["notification-id", "answer"], cause: "\"notification-id\", i.e. the poll identifier, is required, as well as the answer (which can be either 1 or 2)"))
            return
        }
        
        APRecipeReactions.postPollAnswer(answer, withPollID: pollID) { (data, status) in
            handler?(response: (
                status == .Created ?
                    PluginResponse.ok(JSON(dictionary: ["HTTPStatusCode": status.rawValue]), command: "post") :
                    PluginResponse.error("Cannot send answer \(answerValue) for poll \(pollID))", command: "post")))
        }
    }
    
    // MARK: Sync
    private func sync(arguments: JSON, sender: String?) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipeReactionPoll.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPRecipeReactionPoll.self, text: "Downloading poll reactions...", symbol: .Download)
        APRecipeReactions.getPolls { (polls, status) in
            if status != .OK {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot download poll reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadPollReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
                return
            }
            
            Console.info(NPRecipeReactionPoll.self, text: "Saving poll reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for poll in polls {
                Console.infoLine(poll.id, symbol: .Add)
                self.hub?.cache.store(poll, inCollection: "Reactions", forPlugin: self)
            }
            Console.infoLine("polls saved: \(polls.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
        }
        
        return PluginResponse.ok(command: "sync")
    }
    
    // MARK: Read
    private func index(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resources: [APRecipePoll] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
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
            Console.commandError(NPRecipeReactionPoll.self, command: "read", requiredParameters: ["content-id"])
            return PluginResponse.cannotRun("read", requiredParameters: ["content-id"])
        }
        
        guard let reaction = poll(id) else {
            Console.commandWarning(NPRecipeReactionPoll.self, command: "read", cause: "Content \"\(id) \" not found")
            return PluginResponse.warning("Content \"\(id)\" not found", command: "read")
        }
        
        return PluginResponse.ok(reaction.json, command: "read")
    }
    private func poll(id: String) -> APRecipePoll? {
        guard let resource: APRecipePoll = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
    
    // MARK: Store
    private func downloadIfMissing(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let pluginHub = hub, id = arguments.string("id"), appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipeReactionPoll.self, command: "download-reaction-if-missing", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("download-reaction-if-missing", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        if let _: APRecipePoll = pluginHub.cache.resource(id, inCollection: "Reactions", forPlugin: self) {
            Console.info(NPRecipeReactionPoll.self, text: "Cache did contain poll \(id)")
            Console.infoLine("skipping download")
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["id": id, "downloaded": false]), command: "download-reaction-if-missing"))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        APRecipeReactions.getPoll(id) { (poll, status) in
            guard let p = poll where status.codeClass == .Successful else {
                completionHandler?(response: PluginResponse.cannotRun("download-reaction-if-missing", requiredParameters: ["id", "app-token"], optionalParameters: ["timeout-interval"], cause: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPRecipeReactionPoll.self, text: "Poll reaction \(p.id) has been downloaded and cached")
            pluginHub.cache.store(p, inCollection: "Reactions", forPlugin: self)
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["id": id, "downloaded": true]), command: "download-reaction-if-missing"))
        }
    }
    private func storeOnlineResource(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resource = arguments.object("resource") as? APIResource, content = APRecipePoll.makeWithResource(resource) else {
            Console.commandError(NPRecipeReactionPoll.self, command: "store-online-resource", requiredParameters: ["resource"])
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"])
        }
        
        guard let pluginHub = hub else {
            Console.commandError(NPRecipeReactionPoll.self, command: "store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
            return PluginResponse.cannotRun("store-online-resource", requiredParameters: ["resource"], cause: "No plugin hub can be found")
        }
        
        Console.info(NPRecipeReactionPoll.self, text: "Poll reaction \(resource.id) has been stored")
        pluginHub.cache.store(content, inCollection: "Reactions", forPlugin: self)
        return PluginResponse.ok(command: "store-online-resource")
    }
}
