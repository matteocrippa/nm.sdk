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
    
    private func resetAppInfo() {
        appToken = ""
        appIdentifier = nil
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
    
    /// MARK: NMPlug.Extensible
    public func didReceivePluginEvent(event: PluginEvent) {
    }
}
