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
        return "0.1"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPRecipeReactionPoll.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        case "index":
            return PluginResponse.ok(JSON(dictionary: ["reactions": index()]))
        case "read":
            guard let id = arguments.string("content") else {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot run \"read\" command")
                Console.errorLine("\"read\" requires \"content\" parameter")
                return PluginResponse.error("\"read\" requires \"read\" parameter")
            }
            
            guard let reaction = poll(id) else {
                Console.warning(NPRecipeReactionPoll.self, text: "Poll \"\(id) \" not found")
                return PluginResponse.error("Poll \"\(id)\" not found")
            }
            
            return PluginResponse.ok(reaction.json)
        default:
            Console.error(NPRecipeReactionPoll.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
        }
        
        return PluginResponse.ok()
    }
    func sendNetworkRequest(arguments: JSON, sender: String?, handler: ((response: PluginResponse, HTTPCode: Int) -> Void)?) {
        guard let pollID = arguments.string("notification_id"), answerValue = arguments.int("answer"), answer = APRecipePollAnswer(rawValue: answerValue) else {
            Console.error(NPRecipeReactionPoll.self, text: "Cannot send event")
            Console.errorLine("answer field is required")
            Console.errorLine("notification_id field is required")
            Console.errorLine("event received: \(arguments.dictionary)")
            
            handler?(response: PluginResponse.error("Cannot send event: it must contain a valid answer value (\"answer\" field) and a poll identifier (\"notification_id\" field)"), HTTPCode: -1)
            return
        }
        
        APRecipeReactions.postPollNotificationAnswer(answer, withPollID: pollID) { (status) in
            handler?(response: (status == .Created ? PluginResponse.ok() : PluginResponse.error("Cannot send answer \(answerValue) for poll \(pollID))")), HTTPCode: status.rawValue)
        }
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPRecipeReactionPoll.self, text: "Downloading poll reactions...", symbol: .Download)
        APRecipeReactions.getPollNotifications { (polls, status) in
            if status != .OK {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot download poll reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadPollReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", operation: "sync"))
                return
            }
            
            Console.info(NPRecipeReactionPoll.self, text: "Saving poll reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for poll in polls {
                Console.infoLine(poll.id, symbol: .Add)
                self.hub?.cache.store(poll, inCollection: "Reactions", forPlugin: self)
            }
            
            Console.infoLine("polls saved: \(polls.count)")
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
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
    private func poll(id: String) -> APRecipePoll? {
        guard let resource: APRecipePoll = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
}
