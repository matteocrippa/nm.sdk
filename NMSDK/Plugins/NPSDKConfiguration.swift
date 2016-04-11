//
//  NPSDKConfiguration.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMNet
import NMJSON
import NMPlug

class NPSDKConfiguration: Plugin {
    // MARK: In-memory cache
    private var rules = [String: CFGRule]()
    private var beacons = [String: Beacon]()
    private var contents = [String: Content]()
    
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-sdk-configuration"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("command") else {
            return PluginResponse.error("\"command\" argument is required; allowed values: sync")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app_token") where !appToken.isEmpty else {
                return PluginResponse.error("\"sync\" command requires \"app_token\" to be a non nil, non empty string")
            }
            
            sync(appToken, timeoutInterval: (arguments.double("timeout_interval") ?? 10))
            return PluginResponse.ok()
                default:
            break
        }
        
        return PluginResponse.error("allowed \"command\" values: sync")
    }
    
    // MARK: Sync process
    private func clearInMemoryCache() {
        rules = [: ]
        beacons = [: ]
        contents = [: ]
    }
    private func eventWithCommand(command: String, args: [String: AnyObject]) -> JSON {
        return JSON(dictionary: ["command": command, "args": args])
    }
    
    private func sync(appToken: String, timeoutInterval: NSTimeInterval) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval
        
        clearInMemoryCache()
        syncRules()
    }
    private func syncDidFailWithError(error: String) {
        hub?.dispatch(event: PluginEvent(from: name, content: eventWithCommand("sync", args: ["succeeded": false, "error": error])))
    }
    private func syncDidSucceed() {
        hub?.dispatch(event: PluginEvent(from: name, content: eventWithCommand("sync", args: ["succeeded": true])))
    }
    private func syncRules() {
        MatchRulesAPI.get { (resources, status) in
            guard let rules = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download match rules")
                return
            }
            
            for rule in rules.resources {
                if let ruleObject = CFGRule(dictionary: ["id": rule.id, "args": rule.attributes.dictionary]) {
                    self.rules[rule.id] = ruleObject
                }
            }
            
            self.syncBeacons()
        }
    }
    private func syncBeacons() {
        BeaconsAPI.get { (resources, status) in
            guard let beacons = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download beacons' configuration")
                return
            }
            
            for beacon in beacons.resources {
                if let beaconObject = Beacon(dictionary: ["id": beacon.id, "args": beacon.attributes.dictionary]) {
                    self.beacons[beacon.id] = beaconObject
                }
            }
            
            self.syncContents()
        }
    }
    private func syncContents() {
        ContentsAPI.get { (resources, status) in
            guard let contents = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download beacons' configuration")
                return
            }
            
            for content in contents.resources {
                if let contentObject = Content(dictionary: ["id": content.id, "args": content.attributes.dictionary]) {
                    self.contents[content.id] = contentObject
                }
            }
            
            self.completeSync()
        }
    }
    private func completeSync() {
        hub?.cache.removeAllResourcesWithPlugin(self)
        
        var beaconToRules: [String: [String]] = [: ]
        var beaconKeys: [String: String] = [: ]
        
        for content in contents.values {
            hub?.cache.store(content, inCollection: Collections.Common.Contents.rawValue, forPlugin: self)
        }
        
        for beacon in beacons.values {
            hub?.cache.store(beacon, inCollection: Collections.Common.Beacons.rawValue, forPlugin: self)
            beaconKeys[beacon.id] = beacon.key
        }
        
        for rule in rules.values {
            hub?.cache.store(rule, inCollection: Collections.CFG.Rules.rawValue, forPlugin: self)
            guard var map = beaconToRules[rule.beacon_id] else {
                beaconToRules[rule.beacon_id] = [rule.id]
                continue
            }
            
            if !map.contains(rule.id) {
                map.append(rule.id)
                beaconToRules[rule.beacon_id] = map
            }
        }
        
        for (beaconID, ruleIDs) in beaconToRules {
            if let key = beaconKeys[beaconID], evaluation = CFGEvaluation(dictionary: ["id": key, "rules": ruleIDs, "detector": "beacon"]) {
                hub?.cache.store(evaluation, inCollection: Collections.CFG.Evaluations.rawValue, forPlugin: self)
            }
        }
        
        clearInMemoryCache()
        syncDidSucceed()
    }
}
