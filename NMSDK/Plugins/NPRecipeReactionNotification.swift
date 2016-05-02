//
//  NPRecipeReactionNotification.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPRecipeReactionNotification: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.Notifications.name
    }
    override var version: String {
        return "0.2"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPRecipeReactionNotification.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPRecipeReactionNotification.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        case "index":
            return PluginResponse.ok(JSON(dictionary: ["reactions": index()]))
        case "read":
            guard let id = arguments.string("content") else {
                Console.error(NPRecipeReactionNotification.self, text: "Cannot run \"read\" command")
                Console.errorLine("\"read\" requires \"content\" parameter")
                return PluginResponse.error("\"read\" requires \"content\" parameter")
            }
            
            guard let reaction = notification(id) else {
                Console.warning(NPRecipeReactionContent.self, text: "Notification \"\(id) \" not found")
                return PluginResponse.error("Notification \"\(id)\" not found")
            }
            
            return PluginResponse.ok(reaction.json)
        default:
            Console.error(NPRecipeReactionNotification.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"index\" or \"read\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPRecipeReactionNotification.self, text: "Downloading notification reactions...", symbol: .Download)
        APRecipeReactions.getSimpleNotifications { (notifications, status) in
            if status != .OK {
                Console.error(NPRecipeReactionNotification.self, text: "Cannot download notification reactions")
                
                self.hub?.dispatch(event: NearSDKError.CannotDownloadNotificationReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", operation: "sync"))
                return
            }
            
            Console.info(NPRecipeReactionNotification.self, text: "Saving notification reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for notification in notifications {
                Console.infoLine(notification.id, symbol: .Add)
                
                self.hub?.cache.store(notification, inCollection: "Reactions", forPlugin: self)
            }
            
            Console.infoLine("notifications saved: \(notifications.count)")
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
    
    // MARK: Read
    private func index() -> [String] {
        guard let resources: [APRecipeNotification] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
            return []
        }
        
        var keys = [String]()
        for resource in resources {
            keys.append(resource.id)
        }
        
        return keys
    }
    private func notification(id: String) -> APRecipeNotification? {
        guard let resource: APRecipeNotification = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
}
