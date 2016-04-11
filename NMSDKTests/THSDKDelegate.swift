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
    var didSync: ((successfully: Bool) -> Void)?
    var didReceiveEvent: ((event: PluginEvent) -> Void)?
    
    override init() {
        super.init()
    }
    
    func nearSDKDidSync(successfully: Bool) {
        didSync?(successfully: successfully)
    }
}
