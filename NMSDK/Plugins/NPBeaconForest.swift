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
        return CorePlugin.BeaconForest.name
    }
    override var version: String {
        return "0.4"
    }
    override var commands: [String: RunHandler] {
        return ["sync": sync, "read-node": readNode, "read-nodes": readNodes, "read-next-nodes": readNextNodes]
    }
    
    // MARK: Sync
    private func sync(arguments: JSON, sender: String?) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPBeaconForest.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPBeaconForest.self, text: "Downloading nodes...", symbol: .Download)
        APBeaconForest.get { (nodes, status) in
            if status != .OK {
                Console.error(NPBeaconForest.self, text: "Cannot download nodes")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadRegionMonitoringConfiguration.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
                return
            }
            
            Console.info(NPBeaconForest.self, text: "Saving nodes...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for node in nodes {
                Console.infoLine(node.id, symbol: .Add)
                Console.infoLine("beacon UUID: \(node.proximityUUID.UUIDString)", symbol: .Space)
                if let major = node.major, minor = node.minor {
                    Console.infoLine("      major: \(major)", symbol: .Space)
                    Console.infoLine("      minor: \(minor)", symbol: .Space)
                }
                
                self.hub?.cache.store(node, inCollection: "Regions", forPlugin: self)
                if node.isRoot {
                    Console.infoLine("saved as default region", symbol: .Space)
                    self.hub?.cache.store(node, inCollection: "DefaultRegions", forPlugin: self)
                }
            }
            Console.infoLine("nodes saved: \(nodes.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
            self.startMonitoring()
        }
        
        return PluginResponse.ok(command: "sync")
    }
    
    // MARK: Read
    private func readNode(arguments: JSON, sender: String?) -> PluginResponse {
        guard let id = arguments.string("id") else {
            Console.commandError(NPBeaconForest.self, command: "read-node", requiredParameters: ["id"])
            return PluginResponse.cannotRun("read-node", requiredParameters: ["id"])
        }
        
        guard let node = node(id) else {
            Console.warning(NPBeaconForest.self, text: "Cannot find node \(id)")
            return PluginResponse.cannotRun("read-node", requiredParameters: ["id"], cause: "Cannot find node \(id)")
        }
        
        return PluginResponse.ok(JSON(dictionary: ["node": node]), command: "read-node")
    }
    private func readNodes(arguments: JSON, sender: String?) -> PluginResponse {
        return PluginResponse.ok(JSON(dictionary: ["nodes": nodes()]), command: "read-nodes")
    }
    private func readNextNodes(arguments: JSON, sender: String?) -> PluginResponse {
        guard let when = arguments.string("when"), id = arguments.string("node-id") where when == "enter" || when == "exit" else {
            Console.commandError(NPBeaconForest.self, command: "read-next-nodes", cause: "A valid node identifier must be provided, when must be either \"enter\" or \"exit\"", requiredParameters: ["when", "node-id"])
            return PluginResponse.cannotRun("read-next-nodes", requiredParameters: ["when", "node-id"], cause: "A valid node identifier must be provided, when must be either \"enter\" or \"exit\"")
        }
        
        let regions = (when == "enter" ? navigator.enter(id) : navigator.exit(id))
        return PluginResponse.ok(JSON(dictionary: ["monitored-regions": regions]), command: "read-next-nodes")
    }
    private func nodes() -> [[String: AnyObject]] {
        let resources: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        var nodes = [[String: AnyObject]]()
        for resource in resources {
            nodes.append(["id": resource.id, "parent": resource.json.string("parent", fallback: "-")!, "children": resource.json.stringArray("children", emptyIfNil: true)!])
        }
        
        return nodes
    }
    private func node(id: String) -> [String: AnyObject]? {
        let resources: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        for resource in resources where resource.id == id {
            return ["id": resource.id, "parent": resource.json.string("parent", fallback: "-")!, "children": resource.json.stringArray("children", emptyIfNil: true)!]
        }
        
        return nil
    }
    private func triggerEnterEventWithRegion(region: CLRegion) {
        hub?.send(
            "evaluate",
            fromPluginNamed: name,
            toPluginNamed: CorePlugin.Recipes.name,
            withArguments: JSON(dictionary: ["in-case": "beacon-forest", "in-target": region.identifier, "trigger": "enter_region"]))
    }
    
    // MARK: CoreLocation
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        enterInto(region)
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        exitFrom(region)
    }
    
    // MARK: Region monitoring
    func startMonitoring() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if ![CLAuthorizationStatus.AuthorizedAlways, CLAuthorizationStatus.AuthorizedWhenInUse].contains(authorizationStatus)  {
            Console.error(NPBeaconForest.self, text: "Cannot start monitoring regions")
            Console.errorLine("authorization status is not equal to .AuthorizedAlways or .AuthorizedWhenInUse")
            hub?.dispatch(
                event: NearSDKError.RegionMonitoringIsNotAuthorized.pluginEvent(
                    name, message: "CLLocationManager's authorization status is not equal to .AuthorizedAlways or .AuthorizedWhenInUse",
                    command: "start-monitoring"))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Stopping monitoring regions...")
        let monitoredRegions = locationManager.monitoredRegions
        for region in  monitoredRegions {
            Console.infoLine("region \(region.identifier)")
            locationManager.stopMonitoringForRegion(region)
        }
        
        let regions = navigator.identifiersToRegions(Set(navigator.defaultRegionIdentifiers))
        if regions.count <= 0 {
            Console.warning(NPBeaconForest.self, text: "Cannot monitor regions: no regions configured")
            hub?.dispatch(event: NearSDKError.NoRegionsToMonitor.pluginEvent(name, message: "Configured regions: \(regions.count)", command: "start-monitoring"))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Starting monitoring regions...")
        locationManager.delegate = self
        for region in regions {
            Console.infoLine("region \(region.identifier)")
            locationManager.startMonitoringForRegion(region)
        }
    }
    private func updateMonitoredRegions(targetIdentifiers: [String]) {
        var acceptedIdentifiers = Set<String>()
        let monitoredRegions = Array(locationManager.monitoredRegions)
        Console.info(NPBeaconForest.self, text: "Updating regions monitored...")
        
        for region in monitoredRegions {
            // Regions not contained in target will not be monitored
            if !targetIdentifiers.contains(region.identifier) {
                Console.infoLine("stopping monitoring region \(region.identifier)")
                locationManager.stopMonitoringForRegion(region)
                continue
            }
            
            acceptedIdentifiers.remove(region.identifier)
        }
        
        let acceptedRegions = navigator.identifiersToRegions(acceptedIdentifiers)
        for region in acceptedRegions {
            Console.infoLine("starting monitoring region \(region.identifier)")
            locationManager.startMonitoringForRegion(region)
        }
    }
    private func enterInto(region: CLRegion) {
        APBeaconForest.postBeaconDetected(region.identifier, response: nil)
        triggerEnterEventWithRegion(region)
        updateMonitoredRegions(navigator.enter(region.identifier))
        Console.info(NPBeaconForest.self, text: "Entered region \(region.identifier)")
    }
    private func exitFrom(region: CLRegion) {
        // If the region left by the device is being monitored, the navigator should update monitored regions
        for monitoredRegion in locationManager.monitoredRegions where monitoredRegion.identifier == region.identifier {
            updateMonitoredRegions(navigator.exit(region.identifier))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Left region \(region.identifier)")
    }
}
