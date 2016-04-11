//
//  Helpers.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMPlug
import NMJSON

// MARK: Support
enum Collections {
    enum CFG: String {
        case Rules = "Rules"
        case Evaluations = "Evaluations"
    }
    enum Common: String {
        case Beacons = "Beacons"
        case Contents = "Contents"
    }
}

class CFGRule: PluginResource {
    var beacon_id: String { return json.string("beacon_id")! }
    var content_id: String { return json.string("content_id")! }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id"), bid = json.string("args.beacon_id"), cid = json.string("args.content_id") else {
            return nil
        }
        
        super.init(dictionary: ["id": id, "content_id": cid, "beacon_id": bid])
    }
}
class CFGEvaluation: PluginResource {
    var detector: String { return json.string("detector")! }
    var rules: [String] { return json.stringArray("rules")! }
    
    required init?(dictionary object: [String: AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id"), rules = json.stringArray("rules"), detector = json.string("detector") else {
            return nil
        }
        
        super.init(dictionary: ["id": id, "rules": rules, "detector": detector])
    }
}

class Beacon: PluginResource {
    var uuid: NSUUID { return NSUUID(UUIDString: json.string("uuid")!)! }
    var major: Int { return json.int("major")! }
    var minor: Int { return json.int("minor")! }
    var range: Int { return json.int("range")! }
    var key: String { return "\(uuid.UUIDString).\(major).\(minor).\(range)" }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let
            id = json.string("id"),
            pid = json.string("args.proximity_uuid"), uuid = NSUUID(UUIDString: pid),
            maj = json.int("args.major"), min = json.int("args.minor"),
            rnv = json.int("args.range"), _ = CLProximity(rawValue: rnv) else {
                return nil
        }
        
        super.init(dictionary: ["id": id, "uuid": uuid.UUIDString, "major": maj, "minor": min, "range": rnv])
    }
}
class Content: PluginResource {
    var title: String { return json.string("title")! }
    var short_description: String { return json.string("short_description")! }
    var long_description: String { return json.string("long_description")! }
    var photo_ids: [String] { return json.stringArray("photo_ids")! }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id") else {
            return nil
        }
        
        super.init(dictionary: ["id": id,
            "title": json.string("args.title", fallback: "")!,
            "short_description": json.string("args.short_description", fallback: "")!,
            "long_description": json.string("args.long_description", fallback: "")!,
            "photo_ids": json.stringArray("args.photo_ids", emptyIfNil: true)!]
        )
    }
}
