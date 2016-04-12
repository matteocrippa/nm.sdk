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
    enum Configuration: String {
        case Rules = "Rules"
        case Evaluations = "Evaluations"
        case BeaconEvaluations = "BeaconEvaluations"
    }
    enum Common: String {
        case Beacons = "Beacons"
        case Contents = "Contents"
    }
}

class ConfigurationRule: PluginResource {
    var beacon_id: String { return json.string("beacon_id")! }
    var content_id: String { return json.string("content_id")! }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id"), bid = json.string("beacon_id"), cid = json.string("content_id") else {
            return nil
        }
        
        super.init(dictionary: ["id": id, "content_id": cid, "beacon_id": bid])
    }
}
class ConfigurationEvaluation: PluginResource {
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
class ConfigurationBeaconEvaluation: PluginResource {
    var rules_to_contents: [[String: AnyObject]] { return json.dictionaryArray("rules_to_contents", emptyIfNil: true)! }
    
    required init?(dictionary object: [String: AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id"), rtc = json.dictionaryArray("rules_to_contents", emptyIfNil: true) else {
            return nil
        }
        
        super.init(dictionary: ["id": id, "rules_to_contents": rtc])
    }
}
class CorePluginEvent {
    class func createWithCommand(command: String, args: [String: AnyObject]) -> JSON {
        var dictionary = [String: AnyObject]()
        for (k, v) in args {
            dictionary[k] = v
        }
        
        dictionary["command"] = command
        return JSON(dictionary: dictionary)
    }
    class func merge(id: String, dictionary args: [String: AnyObject]) -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        for (k, v) in args {
            dictionary[k] = v
        }
        
        dictionary["id"] = id
        return dictionary
    }
    class func configurationBody(resources: [PluginResource], command: String, scope: String) -> JSON {
        var responseBody = [String: AnyObject]()
        for resource in resources {
            guard var contents: [[String: AnyObject]] = responseBody[scope] as? [[String: AnyObject]] else {
                responseBody[scope] = [resource.json.dictionary]
                continue
            }
            
            contents.append(resource.json.dictionary)
            responseBody[scope] = contents
        }
        
        return createWithCommand(command, args: ["scope": scope, "objects": responseBody])
    }
}
