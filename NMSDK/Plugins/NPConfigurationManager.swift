//
//  NPConfigurationManager.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 13/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet
import NMPlug
import NMJSON
import NMCache

class NPConfigurationManager {
    // MARK: In-memory cache
    private var rules = [String: ConfigurationRule]()
    private var beacons = [String: Beacon]()
    private var contents = [String: EvaluatedContent]()
    private var beaconForestNodes = [String: BeaconForestNode]()
    private (set) var plugin: Pluggable!
    
    // MARK: Sync process
    func sync(plugin p: Pluggable, appToken: String, timeoutInterval: NSTimeInterval) {
        plugin = p
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval
        
        clearInMemoryCache()
        syncRules()
    }
    private func clearInMemoryCache() {
        rules = [: ]
        beacons = [: ]
        contents = [: ]
        beaconForestNodes = [: ]
    }
    private func syncDidFailWithError(error: String) {
        plugin.hub?.dispatch(event: PluginEvent(from: plugin.name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": false, "error": error])))
    }
    private func syncDidSucceed() {
        plugin.hub?.dispatch(event: PluginEvent(from: plugin.name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": true])))
    }
    private func syncRules() {
        MatchRulesAPI.get { (resources, status) in
            guard let rules = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download match rules")
                return
            }
            
            for rule in rules.resources {
                if let ruleObject = ConfigurationRule(dictionary: CorePluginEvent.merge(rule.id, dictionary: rule.attributes.dictionary)) {
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
                if let beaconObject = Beacon(dictionary: CorePluginEvent.merge(beacon.id, dictionary: beacon.attributes.dictionary)) {
                    self.beacons[beacon.id] = beaconObject
                }
            }
            
            self.syncContents()
        }
    }
    private func syncContents() {
        ContentsAPI.get { (resources, status) in
            guard let contents = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download beacons' configuration - Ranging")
                return
            }
            
            for content in contents.resources {
                if let contentObject = EvaluatedContent(dictionary: CorePluginEvent.merge(content.id, dictionary: content.attributes.dictionary)) {
                    self.contents[content.id] = contentObject
                }
            }
            
            self.completeSync()
        }
    }
    private func completeSync() {
        plugin.hub?.cache.removeAllResourcesWithPlugin(plugin)
        
        var beaconToRules: [String: [String]] = [: ]
        var beaconKeys: [String: String] = [: ]
        
        for content in contents.values {
            plugin.hub?.cache.store(content, inCollection: Collections.Common.Contents.rawValue, forPlugin: plugin)
        }
        
        for beacon in beacons.values {
            plugin.hub?.cache.store(beacon, inCollection: Collections.Common.Beacons.rawValue, forPlugin: plugin)
            beaconKeys[beacon.id] = beacon.key
        }
        
        for rule in rules.values {
            plugin.hub?.cache.store(rule, inCollection: Collections.Configuration.Rules.rawValue, forPlugin: plugin)
            guard var map = beaconToRules[rule.beacon_id] else {
                beaconToRules[rule.beacon_id] = [rule.id]
                continue
            }
            
            if !map.contains(rule.id) {
                map.append(rule.id)
                beaconToRules[rule.beacon_id] = map
            }
        }
        
        var evaluations = [String: ConfigurationBeaconEvaluation]()
        for (beaconID, ruleIDs) in beaconToRules {
            if let key = beaconKeys[beaconID], evaluation = ConfigurationEvaluation(dictionary: ["id": key, "rules": ruleIDs, "detector": "beacon"]) {
                var ruleToContentIdentifiers = [String: [String: String]]()
                for id in ruleIDs {
                    if let rule = rules[id], content = contents[rule.content_id] {
                        ruleToContentIdentifiers[id] = ["rule_id": id, "content_id": content.id]
                    }
                }
                
                if let evaluation = ConfigurationBeaconEvaluation(dictionary: ["id": key, "rules_to_contents": Array(ruleToContentIdentifiers.values)]) {
                    evaluations[key] = evaluation
                }
                
                plugin.hub?.cache.store(evaluation, inCollection: Collections.Configuration.Evaluations.rawValue, forPlugin: plugin)
            }
        }
        
        var evaluatorSyncCommand: [String: AnyObject] = ["command": "sync"]
        add(contents, toCommand: &evaluatorSyncCommand, withKey: "contents")
        add(evaluations, toCommand: &evaluatorSyncCommand, withKey: "beacon_evaluations")
        
        guard let response = plugin.hub?.send(direct: PluginDirectMessage(from: plugin.name, to: "com.nearit.plugin.np-evaluator", content: JSON(dictionary: evaluatorSyncCommand))) where response.status == .OK else {
            clearInMemoryCache()
            syncDidFailWithError("Cannot sync with plugin NPEvaluator")
            return
        }
        
        clearInMemoryCache()
        syncDidSucceed()
    }
    private func add(resources: [String: PluginResource], inout toCommand command: [String: AnyObject], withKey key: String) {
        for v in resources.values {
            guard var array = command[key] as? [[String: AnyObject]] else {
                command[key] = [v.dictionary]
                continue
            }
            
            array.append(v.dictionary)
            command[key] = array
        }
    }
}
