//
//  THExtendedObject.swift
//  NMPlug
//
//  Created by Francesco Colleoni on 31/03/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug

class THExtendedObject: NSObject, Extensible {
    var eventReceived: ((event: PluginEvent) -> Void)?
    
    func didReceivePluginEvent(event: PluginEvent) {
        eventReceived?(event: event)
    }
}
