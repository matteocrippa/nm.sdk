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
    private var beaconForestNodes = [String: APBeaconForestNode]()
    private (set) var plugin: Pluggable!
    
    // MARK: Sync process
    func sync(plugin p: Pluggable, appToken: String, timeoutInterval: NSTimeInterval) {
        plugin = p
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval
        
        clearInMemoryCache()
        downloadBeaconForest()
    }
    private func clearInMemoryCache() {
        beaconForestNodes = [: ]
    }
    private func syncDidFailWithError(error: String) {
        plugin.hub?.dispatch(event: PluginEvent(from: plugin.name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": false, "error": error])))
    }
    private func syncDidSucceed() {
        plugin.hub?.dispatch(event: PluginEvent(from: plugin.name, content: CorePluginEvent.createWithCommand("sync", args: ["succeeded": true])))
    }
    
    // MARK: nearit.com "BeaconForest" plugin integration
    private func downloadBeaconForest() {
        APBeaconForest.get { (resources, status) in
            guard let forest = resources where status == .OK else {
                self.syncDidFailWithError("Cannot download beacons' configuration")
                return
            }
            
            var nodes = [String: APBeaconForestNode]()
            self.parseBeaconForestNodes(forest.resources, storeInto: &nodes)
            self.parseBeaconForestNodes(Array(forest.included.values), storeInto: &nodes, ignoredIdentifiers: Array(nodes.keys))
            
            self.completeSync()
        }
    }
    private func parseBeaconForestNodes(collection: [APIResource], inout storeInto target: [String: APBeaconForestNode], ignoredIdentifiers: [String] = []) {
        for resource in collection where !ignoredIdentifiers.contains(resource.id) {
            guard let UUIDString = resource.attributes.string("uuid") where NSUUID(UUIDString: UUIDString) != nil else {
                continue
            }
            
            var dictionary: [String: AnyObject] = ["id": resource.id, "uuid": UUIDString]
            if let major = resource.attributes.int("major"), minor = resource.attributes.int("minor") {
                dictionary["major"] = major
                dictionary["minor"] = minor
            }
            
            var children = [String]()
            if let childrenRelationship = resource.relationships["children"]?.resources {
                for child in childrenRelationship where !children.contains(child.id) {
                    children.append(child.id)
                }
            }
            dictionary["children"] = children
            
            if let parentRelationship = resource.relationships["parent"]?.resources.first {
                dictionary["parent"] = parentRelationship.id
            }
            
            if let node = APBeaconForestNode(dictionary: dictionary) {
                target[node.id] = node
            }
        }
    }
    
    // MARK: Common
    private func completeSync() {
        plugin.hub?.cache.removeAllResourcesWithPlugin(plugin)
        
        for (id, node) in beaconForestNodes {
            if let resource = PluginResource(dictionary: ["id": id, "uuid": node.proximityUUID.UUIDString]) {
                plugin.hub?.cache.store(resource, inCollection: "RangedRegions", forPlugin: plugin)
            }
        }
        
        for (id, node) in beaconForestNodes {
            if let resource = PluginResource(dictionary: ["id": id, "uuid": node.proximityUUID.UUIDString, "region_identifier": node.identifier]) {
                plugin.hub?.cache.store(resource, inCollection: "MonitoredRegions", forPlugin: plugin)
            }
        }
        
        syncDidSucceed()
    }
}
