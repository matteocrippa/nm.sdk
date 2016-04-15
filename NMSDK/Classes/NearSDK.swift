//
//  NearSDK.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import JWTDecode
import NMNet
import NMJSON
import NMPlug

/// nearit.com iOS SDK
@objc
public class NearSDK: NSObject, Extensible {
    private static let sharedSDK = NearSDK()
    
    private var appToken = ""
    private var appIdentifier: String?
    private var apiTimeoutInterval: NSTimeInterval = 10
    private var pluginHub: PluginHub!
    private var delegate: NearSDKDelegate?
    private var forwardCoreEvents = false
    private var corePluginNames = [String]()
    
    private override init() {
        super.init()
        
        pluginHub = PluginHub(extendedObject: self)
        
        let plugins: [Pluggable] = [
            NPBeaconForest(),
            NPRecipes(),
            NPRecipeReactionSimpleNotification(),
            NPRecipeReactionContent(),
            NPRecipeReactionPoll()]
        
        for plugin in plugins {
            pluginHub.plug(plugin)
            corePluginNames.append(plugin.name)
        }
    }
    private func resetAppInfo() {
        appToken = ""
        appIdentifier = nil
    }
    
    /// The delegate object which will receive SDK's events
    /// The SDK will produce easy to process events
    /// whenever a core plugin will produce an event
    /// Events produced by 3rd party plugins will be
    /// sent to the delegate as they are received
    public class var delegate: NearSDKDelegate? {
        get {
            return sharedSDK.delegate
        }
        set(newDelegate) {
            sharedSDK.delegate = newDelegate
        }
    }
    
    /// Plugin management interface exposed by the SDK
    public class var plugins: PluginHub {
        return sharedSDK.pluginHub
    }
    
    /// The app token linked to an app registered on nearit.com
    /// The token must be a valid JSON Web Token
    public class var appToken: String {
        get {
            return sharedSDK.appToken
        }
        set(newAppToken) {
            if newAppToken != sharedSDK.appToken {
                do {
                    let jwt = try decode(newAppToken)
                    guard let data: [String: AnyObject] = jwt.claim("data") else {
                        sharedSDK.resetAppInfo()
                        return
                    }
                    
                    guard let
                        account = JSON(dictionary: data).json("account"),
                        identifier = account.string("id"),
                        role = account.string("role_key") where role.lowercaseString == "app" else {
                            sharedSDK.resetAppInfo()
                            return
                    }
                    
                    sharedSDK.appToken = newAppToken
                    sharedSDK.appIdentifier = identifier
                }
                catch _ {
                    sharedSDK.resetAppInfo()
                }
            }
        }
    }
    /// The app identifier defined by the app token
    public class var appIdentifier: String? {
        return sharedSDK.appIdentifier
    }
    /// The timeout interval of web requests sent to nearit.com servers
    /// The default value is 10 seconds
    /// This value must be greater than 0
    /// Assigning a value less than or equal to 0
    /// will reset the timeout interval to 10 seconds
    public class var apiTimeoutInterval: NSTimeInterval {
        get {
            return sharedSDK.apiTimeoutInterval
        }
        set(newTimeoutInterval) {
            sharedSDK.apiTimeoutInterval = (newTimeoutInterval <= 0 ? 10 : newTimeoutInterval)
        }
    }
    /// If true, all events generated by core plugins
    /// will be forwarded to delegate "as-is", otherwise
    /// they will be silenced - the delegate will not receive any of these events
    public class var forwardCoreEvents: Bool {
        get {
            return sharedSDK.forwardCoreEvents
        }
        set(newFlag) {
            sharedSDK.forwardCoreEvents = newFlag
        }
    }
    /// The names of the core plugins used by NearSDK
    public class var corePluginNames: [String] {
        return sharedSDK.corePluginNames
    }
    
    /// MARK: Management of core plugins used by the SDK
    /// Starts the SDK
    public class func start() -> Bool {
        var result = true
        
        result = result &&
            plugins.run(
                "com.nearit.sdk.plugin.np-beacon-monitor",
                withArguments: JSON(dictionary: ["app-token": appToken, "timeout-interval": apiTimeoutInterval])).status == .OK
        
        result = result &&
            plugins.run(
                "com.nearit.sdk.plugin.np-recipes",
                withArguments: JSON(dictionary: ["do": "sync", "app-token": appToken, "timeout-interval": apiTimeoutInterval])).status == .OK
        
        result = result &&
            plugins.run(
                "com.nearit.sdk.plugin.np-recipe-reaction-content",
                withArguments: JSON(dictionary: ["do": "sync", "app-token": appToken, "timeout-interval": apiTimeoutInterval])).status == .OK
        
        result = result &&
            plugins.run(
                "com.nearit.sdk.plugin.np-recipe-reaction-simple-notification",
                withArguments: JSON(dictionary: ["do": "sync", "app-token": appToken, "timeout-interval": apiTimeoutInterval])).status == .OK
        
        result = result &&
            plugins.run(
                "com.nearit.sdk.plugin.np-recipe-reaction-poll",
                withArguments: JSON(dictionary: ["do": "sync", "app-token": appToken, "timeout-interval": apiTimeoutInterval])).status == .OK
        
        
        return result
    }
    
    /// MARK: NMPlug.Extensible
    public func didReceivePluginEvent(event: PluginEvent) {
        manageRecipeReaction(event)
        manageCoreEventForwarding(event)
    }
    private func manageRecipeReaction(event: PluginEvent) {
        switch event.from {
        case "com.nearit.sdk.plugin.np-recipes":
            guard let content = event.content.json("content"), type = event.content.string("type") else {
                return
            }
            
            manageReaction(content, type: type)
        default:
            break
        }
    }
    private func manageReaction(content: JSON, type: String) {
        switch type {
        case "content-notification":
            if let object = APRecipeContent(dictionary: content.dictionary) {
                delegate?.nearSDKDidEvaluate?(contents: [object])
            }
        default:
            break
        }
    }
    private func manageCoreEventForwarding(event: PluginEvent) {
        if corePluginNames.contains(event.from) && !forwardCoreEvents {
            return
        }
        
        delegate?.nearSDKDidReceiveEvent?(event)
    }
}
