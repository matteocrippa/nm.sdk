//
//  THSDKDelegate.swift
//  NMPlug
//
//  Created by Francesco Colleoni on 31/03/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMSDK
import NMNet
import NMJSON
import NMPlug

class THSDKDelegate: NSObject, NearSDKDelegate {
    var didReceiveEvent: ((event: PluginEvent) -> Void)?
    var didReceiveNotifications: ((notifications: [APRecipeNotification]) -> Void)?
    var didReceiveContents: ((contents: [APRecipeContent]) -> Void)?
    
    override init() {
        super.init()
    }
    
    func nearSDKDidReceiveEvent(event: PluginEvent) {
        didReceiveEvent?(event: event)
    }
    func nearSDKDidEvaluate(contents collection: [APRecipeContent]) {
        didReceiveContents?(contents: collection)
    }
    func nearSDKDidEvaluate(notifications collection: [APRecipeNotification]) {
        didReceiveNotifications?(notifications: collection)
    }
}
