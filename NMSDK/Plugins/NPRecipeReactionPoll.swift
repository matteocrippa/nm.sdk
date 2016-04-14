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
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\" or \"evaluate\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        default:
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"evaluate\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        APRecipeReactions.getPollNotifications { (polls, status) in
            if status != .OK {
                return
            }
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for poll in polls {
                self.hub?.cache.store(poll, inCollection: "Reaction", forPlugin: self)
            }
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
}
