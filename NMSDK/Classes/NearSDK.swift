//
//  NearSDK.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import JWTDecode
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
    
    private override init() {
        super.init()
        
        pluginHub = PluginHub(extendedObject: self)
        pluginHub.plug(NPSDKConfiguration())
        pluginHub.plug(NPBeaconRange())
        pluginHub.plug(NPEvaluator())
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
    
    /// MARK: Management of core plugins used by the SDK
    /// This method starts the
    public class func sync() -> Bool {
        let args = JSON(dictionary: ["command": "sync", "app_token": appToken, "timeout_interval": apiTimeoutInterval])
        let runResult = plugins.run("com.nearit.plugin.np-sdk-configuration", withArguments: args)
        return runResult.status == .OK
    }
    
    /// Starts beacons' plugins (ranging)
    public class func start() -> Bool {
        return plugins.start("com.nearit.plugin.np-beacon-range")
    }
    
    /// MARK: NMPlug.Extensible
    public func didReceivePluginEvent(event: PluginEvent) {
        switch event.from {
        case "com.nearit.plugin.np-sdk-configuration":
            manageSDKConfigurationCommands(event)
        case "com.nearit.plugin.np-evaluator":
            manageEvaluatedEvents(event)
        default:
            break
        }
    }
    
    /// MARK: Core plugin management
    private func manageSDKConfigurationCommands(event: PluginEvent) {
        guard let command = event.content.string("command") else {
            delegate?.nearSDKDidReceiveEvent?(event)
            return
        }
        
        switch command {
        case "sync":
            delegate?.nearSDKDidSync?(event.content.bool("succeeded", fallback: false)!)
        default:
            delegate?.nearSDKDidReceiveEvent?(event)
        }
    }
    private func manageEvaluatedEvents(event: PluginEvent) {
        guard let command = event.content.string("command") else {
            delegate?.nearSDKDidReceiveEvent?(event)
            return
        }
        
        switch command {
        case "evaluate":
            var contents = [EvaluatedContent]()
            let evaluatedContents = event.content.dictionaryArray("contents", emptyIfNil: true)!
            for dictionary in evaluatedContents {
                if let content = EvaluatedContent(dictionary: dictionary) {
                    contents.append(content)
                }
            }
            
            delegate?.nearSDKDidEvaluateContents?(contents)
        default:
            delegate?.nearSDKDidReceiveEvent?(event)
        }
    }
}
