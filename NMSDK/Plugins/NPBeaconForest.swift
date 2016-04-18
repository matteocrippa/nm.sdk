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
    private lazy var navigator: NPBeaconForestNavigator = {
        return NPBeaconForestNavigator(plugin: self)
    }()
    
    // MARK: Plugin override
    override var name: String {
        return "com.nearit.sdk.plugin.np-beacon-monitor"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
            return PluginResponse.ok()
        case "read-nodes":
            return PluginResponse.ok(JSON(dictionary: ["nodes": nodes()]))
        case "read-node":
            guard let id = arguments.string("id") else {
                return PluginResponse.error("\"id\" parameter is required")
            }
            
            guard let node = node(id) else {
                return PluginResponse.error("Node \"\(id)\" not found")
            }
            
            return PluginResponse.ok(JSON(dictionary: ["node": node]))
        case "read-next-nodes":
            guard let when = arguments.string("when"), id = arguments.string("id") where when == "enter" || when == "exit" else {
                return PluginResponse.error("\"action\" and \"id\" parameters are required, \"when\" must be either \"enter\" or \"exit\"")
            }
            
            return PluginResponse.ok(JSON(dictionary: ["monitored-regions": (when == "enter" ? navigator.enter(id) : navigator.exit(id))]))
        default:
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
        }
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        APBeaconForest.get { (nodes, status) in
            if status != .OK {
                self.hub?.dispatch(event: SDKError.CannotDownloadRegionMonitoringConfiguration.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for node in nodes {
                self.hub?.cache.store(node, inCollection: "Regions", forPlugin: self)
                
                if node.isRoot {
                    self.hub?.cache.store(node, inCollection: "DefaultRegions", forPlugin: self)
                }
            }
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
            self.startMonitoring()
        }
    }
    
    // MARK: Read configuration
    private func nodes() -> [[String: AnyObject]] {
        let resources = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        var nodes = [[String: AnyObject]]()
        for resource in resources {
            nodes.append(["id": resource.id, "parent": resource.json.string("parent", fallback: "-")!, "children": resource.json.stringArray("children", emptyIfNil: true)!])
        }
        
        return nodes
    }
    private func node(id: String) -> [String: AnyObject]? {
        let resources = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        for resource in resources where resource.id == id {
            return ["id": resource.id, "parent": resource.json.string("parent", fallback: "-")!, "children": resource.json.stringArray("children", emptyIfNil: true)!]
        }
        
        return nil
    }
    private func triggerEnterEventWithRegion(region: CLRegion) {
        hub?.send(direct: PluginDirectMessage(
            from: name,
            to: "com.nearit.sdk.plugin.np-recipes",
            content: JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": region.identifier, "trigger": "enter_region"])))
    }
    
    // MARK: CoreLocation
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        triggerEnterEventWithRegion(region)
        updateMonitoredRegions(navigator.enter(region.identifier))
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        for monitoredRegion in locationManager.monitoredRegions where monitoredRegion.identifier == region.identifier {
            // If the region left by the device is being monitored, the navigator should update monitored regions
            updateMonitoredRegions(navigator.exit(region.identifier))
            return
        }
    }
    
    // MARK: Region monitoring
    func startMonitoring() {
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
            hub?.dispatch(event: SDKError.RegionMonitoringIsNotAuthorized.pluginEvent(name, message: "CLLocationManager's authorization status is not equal to .AuthorizedAlways"))
            return
        }
        
        let monitoredRegions = locationManager.monitoredRegions
        for region in  monitoredRegions {
            locationManager.stopMonitoringForRegion(region)
        }
        
        let regions = navigator.identifiersToRegions(navigator.defaultRegionIdentifiers)
        if regions.count <= 0 {
            hub?.dispatch(event: SDKError.NoRegionsToMonitor.pluginEvent(name, message: "Configured regions: \(regions.count)"))
            return
        }
        
        locationManager.delegate = self
        for region in regions {
            locationManager.startMonitoringForRegion(region)
        }
    }
    private func updateMonitoredRegions(targetIdentifiers: [String]) {
        var acceptedIdentifiers = [String]()
        
        let monitoredRegions = Array(locationManager.monitoredRegions)
        for region in monitoredRegions {
            // Regions not contained in target will not be monitored
            if !targetIdentifiers.contains(region.identifier) {
                locationManager.stopMonitoringForRegion(region)
                continue
            }
            
            acceptedIdentifiers.append(region.identifier)
        }
        
        /// Add all other target identifiers
        for id in targetIdentifiers where !acceptedIdentifiers.contains(id) {
            acceptedIdentifiers.append(id)
        }
        
        let acceptedRegions = navigator.identifiersToRegions(acceptedIdentifiers)
        for region in acceptedRegions {
            locationManager.startMonitoringForRegion(region)
        }
    }
}
