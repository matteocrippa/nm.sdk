//
//  NPBeaconRange.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMJSON
import NMPlug

class NPBeaconRange: StatefulPlugin {
    // MARK: In-memory cache
    private var rules = [String: ConfigurationRule]()
    private var beacons = [String: Beacon]()
    private var contents = [String: EvaluatedContent]()
    
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-beacon-range"
    }
    
    // MARK: StatefulPluggable - override
    override func start(arguments: JSON) -> Bool {
        return true
    }
    override func stop() -> Bool {
        return true
    }
}
