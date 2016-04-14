//
//  NPBeaconForest.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMPlug
import NMJSON
import NMNet

class NPBeaconForest: Plugin, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    // MARK: Plugin override
    override var name: String {
        return "com.nearit.sdk.plugin.np-beacon-monitor"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
        }
        
        sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        APBeaconForest.get { (resources, status) in
            self.parseResources(resources, status: status)
        }
    }
    private func parseResources(resources: APIResourceCollection?, status: HTTPStatusCode) {
        guard let forest = resources where status == .OK else {
            return
        }
        
        var nodes = [String: APBeaconForestNode]()
        parseBeaconForestNodes(forest.resources, storeInto: &nodes)
        parseBeaconForestNodes(Array(forest.included.values), storeInto: &nodes, ignoredIdentifiers: Array(nodes.keys))
        
        for node in nodes.values {
            hub?.cache.store(node, inCollection: "Regions", forPlugin: self)
        }
        
        hub?.dispatch(event: PluginEvent(from: name, content: JSON(dictionary: ["operation": "sync"])))
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
    
    // MARK: Start monitoring
    
}
