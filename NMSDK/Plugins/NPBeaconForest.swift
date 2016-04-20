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
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPBeaconForest.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
            
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPBeaconForest.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
            return PluginResponse.ok()
        case "read-nodes":
            return PluginResponse.ok(JSON(dictionary: ["nodes": nodes()]))
        case "read-node":
            guard let id = arguments.string("id") else {
                Console.error(NPBeaconForest.self, text: "Cannot run \"read-node\" command")
                Console.errorLine("\"id\" parameter is required")
                return PluginResponse.error("\"id\" parameter is required")
            }
            
            guard let node = node(id) else {
                Console.warning(NPBeaconForest.self, text: "\"read-node\" command could not find node \"\(id)\"")
                return PluginResponse.error("Node \"\(id)\" not found")
            }
            
            return PluginResponse.ok(JSON(dictionary: ["node": node]))
        case "read-next-nodes":
            guard let when = arguments.string("when"), id = arguments.string("id") where when == "enter" || when == "exit" else {
                Console.error(NPBeaconForest.self, text: "Cannot run \"read-next-nodes\" command")
                Console.errorLine("\"action\" and \"id\" parameters are required, \"when\" must be either \"enter\" or \"exit\"")
                return PluginResponse.error("\"action\" and \"id\" parameters are required, \"when\" must be either \"enter\" or \"exit\"")
            }
            
            return PluginResponse.ok(JSON(dictionary: ["monitored-regions": (when == "enter" ? navigator.enter(id) : navigator.exit(id))]))
        default:
            Console.error(NPBeaconForest.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\", \"read-nodes\", \"read-node\" or \"read-next-nodes\"")
        }
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPBeaconForest.self, text: "Downloading nodes...", symbol: .Download)
        APBeaconForest.get { (nodes, status) in
            if status != .OK {
                Console.error(NPBeaconForest.self, text: "Cannot download nodes")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadRegionMonitoringConfiguration.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
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
        hub?.send(direct: PluginDirectMessage(from: name, to: CorePlugin.Recipes.name, content: JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": region.identifier, "trigger": "enter_region"])))
    }
    
    // MARK: CoreLocation
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        triggerEnterEventWithRegion(region)
        updateMonitoredRegions(navigator.enter(region.identifier))
        Console.info(NPBeaconForest.self, text: "Entered region \(region.identifier)")
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        for monitoredRegion in locationManager.monitoredRegions where monitoredRegion.identifier == region.identifier {
            // If the region left by the device is being monitored, the navigator should update monitored regions
            updateMonitoredRegions(navigator.exit(region.identifier))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Left region \(region.identifier)")
    }
    
    // MARK: Region monitoring
    func startMonitoring() {
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
            Console.error(NPBeaconForest.self, text: "Cannot start monitoring regions")
            Console.errorLine("authorization status is not equal to AuthorizedAlways")
            hub?.dispatch(event: NearSDKError.RegionMonitoringIsNotAuthorized.pluginEvent(name, message: "CLLocationManager's authorization status is not equal to .AuthorizedAlways"))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Stopping monitoring regions...")
        let monitoredRegions = locationManager.monitoredRegions
        for region in  monitoredRegions {
            Console.infoLine("region \(region.identifier)")
            locationManager.stopMonitoringForRegion(region)
        }
        
        let regions = navigator.identifiersToRegions(navigator.defaultRegionIdentifiers)
        if regions.count <= 0 {
            Console.warning(NPBeaconForest.self, text: "Cannot monitor regions: no regions configured")
            hub?.dispatch(event: NearSDKError.NoRegionsToMonitor.pluginEvent(name, message: "Configured regions: \(regions.count)"))
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
        var acceptedIdentifiers = [String]()
        let monitoredRegions = Array(locationManager.monitoredRegions)
        Console.info(NPBeaconForest.self, text: "Updating regions monitored...")
        
        for region in monitoredRegions {
            // Regions not contained in target will not be monitored
            if !targetIdentifiers.contains(region.identifier) {
                Console.infoLine("stopping monitoring region \(region.identifier)")
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
            Console.infoLine("starting monitoring region \(region.identifier)")
            locationManager.startMonitoringForRegion(region)
        }
    }
}
