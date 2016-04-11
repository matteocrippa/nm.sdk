//
//  Beacon.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMPlug
import NMJSON

class Beacon: PluginResource {
    var uuid: NSUUID { return NSUUID(UUIDString: json.string("proximity_uuid")!)! }
    var major: Int { return json.int("major")! }
    var minor: Int { return json.int("minor")! }
    var range: Int { return json.int("range")! }
    var key: String { return "\(uuid.UUIDString).\(major).\(minor).\(range)" }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let
            id = json.string("id"),
            pid = json.string("proximity_uuid"), uuid = NSUUID(UUIDString: pid),
            maj = json.int("major"), min = json.int("minor"),
            rnv = json.int("range"), _ = CLProximity(rawValue: rnv) else {
                return nil
        }
        
        super.init(dictionary: ["id": id, "proximity_uuid": uuid.UUIDString, "major": maj, "minor": min, "range": rnv])
    }
}

