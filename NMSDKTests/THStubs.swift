//
//  THStubs.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import OHHTTPStubs
import NMJSON

class THStubs {
    class func clear() {
        OHHTTPStubs.removeAllStubs()
    }
    class func stubBeacons() {
        stub(isHost("api.nearit.com") && isPath("/detectors/beacons")) { (response) -> OHHTTPStubsResponse in
            var beacons = [APIResource]()
            for i in 1...3 {
                let attributes = JSON(dictionary: [
                    "name": "beacon \(i)",
                    "major": i,
                    "minor": i,
                    "proximity_uuid": "00000000-0000-0000-0000-000000000000",
                    "range": CLProximity.Near.rawValue])
                beacons.append(APIResource(type: "beacons", id: "beacon_\(i)", attributes: attributes, relationships: [: ]))
            }
            
            return OHHTTPStubsResponse(JSONObject: APIResourceCollection(resources: beacons).json(), statusCode: 200, headers: nil)
        }
    }
    class func stubContents() {
        stub(isHost("api.nearit.com") && isPath("/contents")) { (response) -> OHHTTPStubsResponse in
            var contents = [APIResource]()
            for i in 1...3 {
                let attributes = JSON(dictionary: [
                    "app_id": "app id",
                    "title": "content \(i)",
                    "short_description": "short \(i)",
                    "long_description": "long description \(1)"])
                contents.append(APIResource(type: "contents", id: "content_\(i)", attributes: attributes, relationships: [: ]))
            }
            
            return OHHTTPStubsResponse(JSONObject: APIResourceCollection(resources: contents).json(), statusCode: 200, headers: nil)
        }
    }
    class func stubMatchRules() {
        stub(isHost("api.nearit.com") && isPath("/matchings")) { (response) -> OHHTTPStubsResponse in
            var rules = [APIResource]()
            for i in 1...3 {
                let attributes = JSON(dictionary: ["content_id": "content_\(i)", "app_id": "app id", "beacon_id": "beacon_\(i)"])
                rules.append(APIResource(type: "matchings", id: "rule_\(i)", attributes: attributes, relationships: [: ]))
            }
            
            return OHHTTPStubsResponse(JSONObject: APIResourceCollection(resources: rules).json(), statusCode: 200, headers: nil)
        }
    }
    
    class func stubEvaluateBeacon() -> JSON {
        return JSON(dictionary: ["command": "evaluate", "proximity_uuid": "00000000-0000-0000-0000-000000000000", "major": 1, "minor": 1, "range": CLProximity.Near.rawValue])
    }
    class func stubBeacon() -> CLBeacon {
        return THBeacon(major: 1, minor: 1, proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, proximity: CLProximity.Near)
    }
    class func stubBeaconRegion() -> CLBeaconRegion {
        return CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, identifier: "identifier")
    }
}
