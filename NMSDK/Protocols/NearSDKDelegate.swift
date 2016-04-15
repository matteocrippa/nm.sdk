//
//  NearSDKDelegate.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet
import NMPlug
import NMJSON

/// The protocol which should be implemented by objects which
/// should receive and consume events generated by NearSDK
@objc
public protocol NearSDKDelegate {
    /// If implemented, this method will be invoked whenever NearSDK receives an event
    optional func nearSDKDidReceiveEvent(event: PluginEvent)
    
    /// If implemented, this method will be invoked whenever NearSDK evaluates one or more notifications
    optional func nearSDKDidEvaluate(notifications collection: [APRecipeNotification])
    
    /// If implemented, this method will be invoked whenever NearSDK evaluates one or more contents
    optional func nearSDKDidEvaluate(contents collection: [APRecipeContent])
}
