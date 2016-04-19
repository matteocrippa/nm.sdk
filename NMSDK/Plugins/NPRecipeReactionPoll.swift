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
        return "com.nearit.sdk.plugin.np-recipe-reaction-poll"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPRecipeReactionPoll.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\" or \"read\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
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
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"read\"")
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"read\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPRecipeReactionPoll.self, text: "Downloading poll reactions...", symbol: .Download)
        APRecipeReactions.getPollNotifications { (polls, status) in
            if status != .OK {
                Console.error(NPRecipeReactionPoll.self, text: "Cannot download poll reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadPollReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
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
    private func poll(id: String) -> APRecipePoll? {
        guard let
            resource = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self),
            reaction = APRecipePoll(dictionary: resource.dictionary) else {
                return nil
        }
        
        return reaction
    }
}
