//
//  CorePluginEvent.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON

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
