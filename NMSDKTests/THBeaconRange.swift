//
//  THBeaconRange.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMPlug
import NMJSON
@testable import NMSDK

class THBeaconRange: NPBeaconRange {
    private (set) var authorizationStatusStub = CLAuthorizationStatus.AuthorizedWhenInUse
    
    init(authorizationStatusStub stub: CLAuthorizationStatus) {
        authorizationStatusStub = stub
    }
    override func start(arguments: JSON) -> Bool {
        if ![CLAuthorizationStatus.AuthorizedAlways, CLAuthorizationStatus.AuthorizedWhenInUse].contains(authorizationStatusStub) {
            return false
        }
        
        guard let rangedRegions = loadConfiguration() where rangedRegions.count > 0 else {
            return false
        }
        
        return true
    }
    override func stop() -> Bool {
        return true
    }
}
