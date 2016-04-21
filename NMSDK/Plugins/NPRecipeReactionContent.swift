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
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPRecipeReactionContent.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\" or \"read\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPRecipeReactionContent.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        case "read":
            guard let id = arguments.string("content") else {
                Console.error(NPRecipeReactionContent.self, text: "Cannot run \"read\" command")
                Console.errorLine("\"read\" requires \"content\" parameter")
                return PluginResponse.error("\"read\" requires \"content\" parameter")
            }
            
            guard let reaction = content(id) else {
                Console.warning(NPRecipeReactionContent.self, text: "Content \"\(id) \" not found")
                return PluginResponse.error("Content \"\(id)\" not found")
            }
            
            return PluginResponse.ok(reaction.json)
        default:
            Console.error(NPRecipeReactionContent.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"read\"")
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"read\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPRecipeReactionContent.self, text: "Downloading content reactions...", symbol: .Download)
        APRecipeReactions.getContentNotifications { (contents, status) in
            if status != .OK {
                Console.error(NPRecipeReactionContent.self, text: "Cannot download content reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadContentReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPRecipeReactionContent.self, text: "Saving content reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for content in contents {
                Console.infoLine(content.id, symbol: .Add)
                
                self.hub?.cache.store(content, inCollection: "Reactions", forPlugin: self)
            }
            
            Console.infoLine("content reactions saved: \(contents.count)")
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
    private func content(id: String) -> APRecipeContent? {
        guard let resource: APRecipeContent = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
}
