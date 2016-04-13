//
//  NPEvaluator.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 12/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMJSON
import NMPlug

class NPEvaluator: Plugin {
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-evaluator"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("command") else {
            return PluginResponse.error("\"command\" argument is required; allowed values: \"evaluate\", \"sync\"")
        }
        
        switch command {
        case "sync":
            guard let contents = arguments.dictionaryArray("contents"), evaluations = arguments.dictionaryArray("beacon_evaluations") else {
                return PluginResponse.error("\"sync\" requires \"contents\" and \"beacon_evaluations\" to be non nil [[String: AnyObject]] instances")
            }
            
            syncConfiguration(evaluations, contents: contents)
            return PluginResponse.ok()
        case "evaluate":
            guard let keys = arguments.stringArray("beacon_keys") else {
                return PluginResponse.error("\"evaluate\" command requires argument \"beacon_keys\", " +
                    "which must be an array of keys like <CLBeacon.ProximityUUID.uppercaseString>.<CLBeacon.major>.<CLBeacon.minor>.<CLBeacon.proximity.rawValue>")
            }
            
            var contents = [[String: AnyObject]]()
            let evaluatedContents = evaluateBeacons(keys)
            for content in evaluatedContents {
                contents.append(content.dictionary)
            }
            
            hub?.dispatch(event: PluginEvent(from: name, content: CorePluginEvent.createWithCommand(command, args: ["contents": contents])))
            return PluginResponse.ok()
        default:
            break
        }
        
        return PluginResponse.error("\"command\" argument is required; allowed values: \"evaluate\", \"sync\"")
    }
    
    // MARK: Content's evaluation
    private func syncConfiguration(evaluations: [[String: AnyObject]], contents: [[String: AnyObject]]) {
        hub?.cache.removeAllResourcesWithPlugin(self)
    }
    private func evaluateBeacons(keys: [String]) -> [EvaluatedContent] {
        return []
    }
}
