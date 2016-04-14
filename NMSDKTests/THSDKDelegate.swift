//
//  THSDKDelegate.swift
//  NMPlug
//
//  Created by Francesco Colleoni on 31/03/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMSDK
import NMJSON
import NMPlug

class THSDKDelegate: NSObject, NearSDKDelegate {
    var didReceiveEvent: ((event: PluginEvent) -> Void)?
    var didReceiveEvaluatedContents: ((contents: [JSON]) -> Void)?
    
    override init() {
        super.init()
    }
    
    func nearSDKDidReceiveEvent(event: PluginEvent) {
        didReceiveEvent?(event: event)
    }
    func nearSDKDidEvaluateContents(contents: [JSON]) {
        didReceiveEvaluatedContents?(contents: contents)
    }
}
