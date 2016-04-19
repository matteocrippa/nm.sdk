//
//  THSDKDelegate.swift
//  NMPlug
//
//  Created by Francesco Colleoni on 31/03/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMSDK
import NMPlug

class THSDKDelegate: NSObject, NearSDKDelegate {
    var didReceiveEvent: ((event: PluginEvent) -> Void)?
    var didReceiveNotifications: ((notifications: [Notification]) -> Void)?
    var didReceiveContents: ((contents: [Content]) -> Void)?
    var didReceivePolls: ((polls: [Poll]) -> Void)?
    var didReceiveError: ((error: NearSDKError, message: String) -> Void)?
    
    override init() {
        super.init()
    }
    
    func nearSDKDidReceiveEvent(event: PluginEvent) {
        didReceiveEvent?(event: event)
    }
    func nearSDKDidEvaluate(polls collection: [Poll]) {
        didReceivePolls?(polls: collection)
    }
    func nearSDKDidEvaluate(contents collection: [Content]) {
        didReceiveContents?(contents: collection)
    }
    func nearSDKDidEvaluate(notifications collection: [Notification]) {
        didReceiveNotifications?(notifications: collection)
    }
    func nearSDKDidFail(error error: NearSDKError, message: String) {
        didReceiveError?(error: error, message: message)
    }
}
