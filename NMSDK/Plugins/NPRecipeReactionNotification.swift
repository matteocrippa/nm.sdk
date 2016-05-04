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
        return "0.3"
    }
    override var supportedCommands: Set<String> {
        return Set(["sync", "index", "read"])
    }
    
    override func run(command: String, arguments: JSON, sender: String?) -> PluginResponse {
        switch command {
        case "sync":
            return sync(arguments)
        case "index":
            return PluginResponse.ok(JSON(dictionary: ["reactions": index()]), command: "index")
        case "read":
            return read(arguments.string("content-id"))
        default:
            Console.commandNotSupportedError(NPRecipeReactionNotification.self, supportedCommands: supportedCommands)
            return PluginResponse.commandNotSupported(command)
        }
    }
    
    // MARK: Sync
    private func sync(arguments: JSON) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipeReactionNotification.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPRecipeReactionNotification.self, text: "Downloading notification reactions...", symbol: .Download)
        APRecipeReactions.getSimpleNotifications { (notifications, status) in
            if status != .OK {
                Console.error(NPRecipeReactionNotification.self, text: "Cannot download notification reactions")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadNotificationReactions.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
                return
            }
            
            Console.info(NPRecipeReactionNotification.self, text: "Saving notification reactions...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for notification in notifications {
                Console.infoLine(notification.id, symbol: .Add)
                
                self.hub?.cache.store(notification, inCollection: "Reactions", forPlugin: self)
            }
            Console.infoLine("notifications saved: \(notifications.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
        }
        
        return PluginResponse.ok(command: "sync")
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
    private func read(contentID: String?) -> PluginResponse {
        guard let id = contentID else {
            Console.commandError(NPRecipeReactionNotification.self, command: "read", requiredParameters: ["content-id"])
            return PluginResponse.cannotRun("read", requiredParameters: ["content-id"])
        }
        
        guard let reaction = notification(id) else {
            Console.commandWarning(NPRecipeReactionNotification.self, command: "read", cause: "Notification \"\(id) \" not found")
            return PluginResponse.warning("Notification \"\(id)\" not found", command: "read")
        }
        
        return PluginResponse.ok(reaction.json, command: "read")
    }
    private func notification(id: String) -> APRecipeNotification? {
        guard let resource: APRecipeNotification = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
}
