//
//  THBeacon.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 12/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation

class THBeacon: CLBeacon {
    private var _major = 0
    private var _minor = 0
    private var _proximityUUID: NSUUID!
    private var _proximity = CLProximity.Near
    
    override var major: NSNumber {
        return _major
    }
    override var minor: NSNumber {
        return _minor
    }
    override var proximityUUID: NSUUID {
        return _proximityUUID
    }
    override var proximity: CLProximity {
        return _proximity
    }
    
    init(major: Int, minor: Int, proximityUUID: NSUUID, proximity: CLProximity) {
        super.init()
        
        _major = major
        _minor = minor
        _proximityUUID = proximityUUID
        _proximity = proximity
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
