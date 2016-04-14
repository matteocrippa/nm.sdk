//
//  APBeaconForestNode.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 12/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMPlug

class APBeaconForestNode: PluginResource {
    var proximityUUID: NSUUID { return NSUUID(UUIDString: json.string("uuid")!)! }
    var major: Int? { return json.int("major") }
    var minor: Int? { return json.int("minor") }
    var parent: String? { return json.string("parent") }
    var isRoot: Bool { return parent != nil }
    var children: [String] { return json.stringArray("children", emptyIfNil: true)! }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id"), UUIDString = json.string("uuid") where NSUUID(UUIDString: UUIDString) != nil else {
            return nil
        }
        
        var dictionary: [String: AnyObject] = ["id": id, "uuid": UUIDString]
        if let major = json.int("major"), minor = json.int("minor") {
            dictionary["major"] = major
            dictionary["minor"] = minor
        }
        
        dictionary["children"] = json.stringArray("children") ?? [String]()
        if let parent = json.string("parent") {
            dictionary["parent"] = parent
        }
        
        super.init(dictionary: dictionary)
    }
}
