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
        return "0.3"
    }
    override var supportedCommands: Set<String> {
        return Set(["sync", "index", "read", "post"])
    }
    
    override func run(command: String, arguments: JSON, sender: String?) -> PluginResponse {
        switch command {
        case "sync":
            return sync(arguments)
        case "index":
            return PluginResponse.ok(JSON(dictionary: ["reactions": index()]), command: "index")
        case "read":
            return read(arguments.string("content-id"))
        case "post":
            return PluginResponse.warning("Async command", command: "post")
        default:
            Console.commandNotSupportedError(NPRecipeReactionPoll.self, supportedCommands: supportedCommands)
            return PluginResponse.commandNotSupported(command)
        }
    }
    
    override func runAsync(command: String, arguments: JSON, sender: String?, handler: ((response: PluginResponse) -> Void)?) {
        switch command {
        case "sync", "index", "read":
            handler?(response: PluginResponse.warning("Sync command", command: command))
        case "post":
            post(arguments, handler: handler)
        default:
            Console.commandNotSupportedError(NPRecipeReactionPoll.self, supportedCommands: supportedCommands)
            handler?(response: PluginResponse.commandNotSupported(command))
        }
    }
    
    // MARK: Async
    private func post(arguments: JSON, handler: ((response: PluginResponse) -> Void)?) {
        guard let pollID = arguments.string("notification-id"), answerValue = arguments.int("answer"), answer = APRecipePollAnswer(rawValue: answerValue) else {
            Console.commandError(NPRecipeReactionPoll.self, command: "post", requiredParameters: ["notification-id", "answer"])
            handler?(response: PluginResponse.cannotRun("post", requiredParameters: ["notification-id", "answer"], cause: "\"notification-id\", i.e. the poll identifier, is required, as well as the answer (which can be either 1 or 2)"))
            return
        }
        
        APRecipeReactions.postPollNotificationAnswer(answer, withPollID: pollID) { (status) in
            handler?(response: (
                status == .Created ?
                    PluginResponse.ok(JSON(dictionary: ["HTTPStatusCode": status.rawValue]), command: "post") :
                    PluginResponse.error("Cannot send answer \(answerValue) for poll \(pollID))", command: "post")))
        }
    }
    
    // MARK: Sync
    private func sync(arguments: JSON) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipeReactionPoll.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPRecipeReactionPoll.self, text: "Downloading poll reactions...", symbol: .Download)
        APRecipeReactions.getPollNotifications { (polls, status) in
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
    private func index() -> [String] {
        guard let resources: [APRecipePoll] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
            return []
        }
        
        var keys = [String]()
        for resource in resources {
            keys.append(resource.id)
        }
        
        return keys
    }
    private func read(contentID: String?) -> PluginResponse {
        guard let id = contentID else {
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
}
