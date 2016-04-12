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
    private var rules = [String: ConfigurationRule]()
    private var beacons = [String: Beacon]()
    private var contents = [String: EvaluatedContent]()
    
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-sdk-configuration"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("command") else {
            return PluginResponse.error("\"command\" argument is required; allowed values: \"sync\", \"read_configuration\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app_token") where !appToken.isEmpty else {
                return PluginResponse.error("\"sync\" command requires \"app_token\" to be a non nil, non empty string")
            }
            
            sync(appToken, timeoutInterval: (arguments.double("timeout_interval") ?? 10))
            return PluginResponse.ok()
        case "read_configuration":
            guard let scope = arguments.string("scope") else {
                return PluginResponse.error("\"read_configuration\" command requires argument \"scope\" to be equal to \"beacons\"")
            }
            
            switch scope {
            case "beacons":
                return PluginResponse.ok(CorePluginEvent.configurationBody(configuredBeacons(), command: command, scope: scope))
            default:
                return PluginResponse.error("\"read_configuration\" command requires argument \"scope\" to be equal to \"beacons\"")
            }
        default:
            break
        }
        
        return PluginResponse.error("\"command\" argument is required; allowed values: \"sync\", \"read_configuration\"")
    }
    
    // MARK: Sync process
    private func clearInMemoryCache() {
        rules = [: ]
        beacons = [: ]
        contents = [: ]
    }
    private func sync(appToken: String, timeoutInterval: NSTimeInterval) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval
        
        clearInMemoryCache()
        syncRules()
    }
    private func syncDidFailWithError(error: String) {
        hub?.dispatch(event: PluginEvent(from: name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": false, "error": error])))
    }
    private func syncDidSucceed() {
        hub?.dispatch(event: PluginEvent(from: name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": true])))
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
                self.syncDidFailWithError("Cannot download beacons' configuration")
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
            hub?.cache.store(rule, inCollection: Collections.Configuration.Rules.rawValue, forPlugin: self)
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
                
                hub?.cache.store(evaluation, inCollection: Collections.Configuration.Evaluations.rawValue, forPlugin: self)
            }
        }
        
        var evaluatorSyncCommand: [String: AnyObject] = ["command": "sync"]
        add(contents, toCommand: &evaluatorSyncCommand, withKey: "contents")
        add(evaluations, toCommand: &evaluatorSyncCommand, withKey: "beacon_evaluations")
        
        guard let response = hub?.send(direct: PluginDirectMessage(from: name, to: "com.nearit.plugin.np-evaluator", content: JSON(dictionary: evaluatorSyncCommand))) where response.status == .OK else {
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
    
    // MARK: Read access to configuration
    private func configuredBeacons() -> [Beacon] {
        return configuredResources(Collections.Common.Beacons.rawValue)
    }
    private func configuredResources<T: PluginResource>(collectionName: String) -> [T] {
        guard let resources = hub?.cache.resourcesIn(collection: collectionName, forPlugin: self) where resources.count > 0 else {
            return []
        }
        
        var result = [T]()
        for resource in resources {
            if let object = T(dictionary: CorePluginEvent.merge(resource.id, dictionary: resource.json.dictionary)) {
                result.append(object)
            }
        }
        
        return result
    }
}
