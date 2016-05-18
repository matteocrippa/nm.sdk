//
//  NPBeaconForest.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import UIKit
import CoreLocation
import NMCache
import NMPlug
import NMJSON
import NMNet

class NPBeaconForest: Plugin, CLLocationManagerDelegate {
    private static let rangedBeaconsCandidatesUpperLimit = 3
    private static let rangedBeaconsBackgroundUpperLimit = 3
    private static let rangedBeaconsActiveUpperLimit = 10
    private var rangedBeacons = [String: (beacon: CLBeacon, count: Int)]()
    private var forceForestNavigation = false
    private var locationManager = CLLocationManager()
    private lazy var navigator: NPBeaconForestNavigator = {
        return NPBeaconForestNavigator(plugin: self)
    }()
    
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.BeaconForest.name
    }
    override var version: String {
        return "0.5"
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
                Console.infoLine("beacon UUID: \(node.proximityUUID.UUIDString)")
                
                if let name = node.name {
                    Console.infoLine("       name: \(name)")
                }
                
                if let major = node.major, minor = node.minor {
                    Console.infoLine("      major: \(major)")
                    Console.infoLine("      minor: \(minor)")
                }
                
                self.hub?.cache.store(node, inCollection: "Regions", forPlugin: self)
                if node.isRoot {
                    Console.infoLine("saved as default region")
                    self.hub?.cache.store(node, inCollection: "DefaultRegions", forPlugin: self)
                }
            }
            Console.infoLine("nodes saved: \(nodes.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
            self.startLocationUpdates()
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
        return PluginResponse.ok(JSON(dictionary: ["monitored-regions": Array(regions)]), command: "read-next-nodes")
    }
    private func nodes() -> [[String: AnyObject]] {
        let resources: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        var nodes = [[String: AnyObject]]()
        for resource in resources {
            nodes.append(["id": resource.id, "name": resource.name ?? "-", "parent": resource.parent ?? "-", "children": resource.children])
        }
        
        return nodes
    }
    private func node(id: String) -> [String: AnyObject]? {
        let resources: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
        
        for resource in resources where resource.id == id {
            return ["id": resource.id, "name": resource.name ?? "-", "parent": resource.parent ?? "-", "children": resource.children]
        }
        
        return nil
    }
    private func triggerEnterEventWithRegion(region: CLRegion) {
        hub?.send(
            "evaluate",
            fromPluginNamed: name,
            toPluginNamed: CorePlugin.Recipes.name,
            withArguments: JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": region.identifier, "pulse-action": "enter_region"]))
    }
    
    // MARK: CoreLocation
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        startMonitoring()
        startRanging()
    }
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        enter(region)
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        exit(region)
    }
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        let sortedBeacons = beacons.sort { (a, b) -> Bool in return a.accuracy < b.accuracy }
        guard let beacon = sortedBeacons.first else {
            forceEnterRegionAfterRanging()
            return
        }
        
        tackRangedBeacon(beacon)
        forceEnterRegionAfterRanging()
    }
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if !forceForestNavigation {
            return
        }
        
        switch state {
        case .Inside:
            enter(region)
            forceForestNavigation = false
        case .Outside:
            exit(region)
            forceForestNavigation = false
        default:
            break
        }
    }
    func forceEnterRegionAfterRanging() {
        let app = UIApplication.sharedApplication()
        if app.applicationState == .Background && rangedBeacons.count < NPBeaconForest.rangedBeaconsBackgroundUpperLimit {
            return
        }
        
        if app.applicationState == .Active && rangedBeacons.count < NPBeaconForest.rangedBeaconsActiveUpperLimit {
            return
        }
        
        guard let
            nodes: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? [])
            where nodes.count > 0 && rangedBeacons.count > 0 else {
            stopRanging()
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Will force \"enter region\" event after ranging")
        Console.infoLine("beacons found: \(rangedBeacons.count)")
        var targets = [(beacon: CLBeacon, count: Int)]()
        for (key, info) in rangedBeacons {
            Console.infoLine("    beacon: \(key)")
            Console.infoLine("detections: \(info.count)")
            targets.append(info)
        }
        
        var candidatesLeft = NPBeaconForest.rangedBeaconsCandidatesUpperLimit
        for target in targets where candidatesLeft > 0 {
            for node in nodes where cachedNode(node, representsBeacon: target.beacon) {
                if let region = navigator.identifierToRegion(node.id) {
                    enter(region)
                    candidatesLeft -= 1
                }
            }
        }
        
        stopRanging()
    }
    
    // MARK: Location updates
    func startLocationUpdates() {
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
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // MARK: Region ranging
    private func startRanging() {
        rangedBeacons = [: ]
        
        let regions = regionsToRange()
        for region in regions {
            locationManager.startRangingBeaconsInRegion(region)
        }
    }
    private func stopRanging() {
        rangedBeacons = [: ]
        
        let regions = regionsToRange()
        for region in regions {
            locationManager.stopRangingBeaconsInRegion(region)
        }
    }
    private func regionsToRange() -> Set<CLBeaconRegion> {
        guard let nodes: [APBeaconForestNode] = (hub?.cache.resourcesIn(collection: "Regions", forPlugin: self) ?? []) else {
            return Set()
        }
        
        var proximityUUIDs = Set<NSUUID>()
        for node in nodes {
            proximityUUIDs.insert(node.proximityUUID)
        }
        
        var regions = Set<CLBeaconRegion>()
        for uuid in proximityUUIDs {
            regions.insert(CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString))
        }
        
        return regions
    }
    
    // MARK: Region monitoring
    func startMonitoring() {
        var identifiers = currentRegionIdentifiers()
        identifiers = identifiers.count > 0 ? identifiers : navigator.defaultRegionIdentifiers
        
        let regions = navigator.identifiersToRegions(identifiers)
        if regions.count <= 0 {
            Console.warning(NPBeaconForest.self, text: "Cannot monitor regions: no regions configured")
            hub?.dispatch(event: NearSDKError.NoRegionsToMonitor.pluginEvent(name, message: "Configured regions: \(regions.count)", command: "start-monitoring"))
            return
        }
        
        Console.info(NPBeaconForest.self, text: "Stopping monitoring regions...")
        for region in regions {
            Console.infoLine("region \(region.identifier) - node name \(nodeName(region))")
            locationManager.stopMonitoringForRegion(region)
        }
        
        Console.info(NPBeaconForest.self, text: "Starting monitoring regions...")
        forceForestNavigation = true
        persistCurrentRegionIdentifiers(identifiers)
        for region in regions {
            Console.infoLine("region \(region.identifier) - node name \(nodeName(region))")
            locationManager.startMonitoringForRegion(region)
        }
    }
    private func updateMonitoredRegions(targetIdentifiers: Set<String>) {
        let regions = processTargetRegionIdentifiers(targetIdentifiers)
        persistCurrentRegionIdentifiers(targetIdentifiers)
        
        Console.info(NPBeaconForest.self, text: "Updating regions monitored...")
        for region in regions.discarded {
            Console.infoLine("stopping monitoring region \(region.identifier) - node name \(nodeName(region))")
            locationManager.stopMonitoringForRegion(region)
        }
        
        for region in regions.accepted {
            Console.infoLine("starting monitoring region \(region.identifier) - node name \(nodeName(region))")
            locationManager.startMonitoringForRegion(region)
        }
    }
    private func enter(region: CLRegion) {
        APBeaconForest.postBeaconDetected(region.identifier, response: nil)
        triggerEnterEventWithRegion(region)
        updateMonitoredRegions(navigator.enter(region.identifier, forceForestNavigation: &forceForestNavigation))
        
        Console.info(NPBeaconForest.self, text: "Entered region \(region.identifier) - node name \(nodeName(region))")
    }
    private func exit(region: CLRegion) {
        updateMonitoredRegions(navigator.exit(region.identifier, forceForestNavigation: &forceForestNavigation))
        
        Console.info(NPBeaconForest.self, text: "Left region \(region.identifier) - node name \(nodeName(region))")
    }
    private func isMonitoredRegion(id: String) -> Bool {
        guard let _: NPBeaconForestRegion = hub?.cache.resource(id, inCollection: "RegionIdentifiers", forPlugin: self) else {
            return false
        }
        
        return true
    }
    
    // MARK: Support
    private func nodeName(region: CLRegion) -> String {
        guard let node: APBeaconForestNode = hub?.cache.resource(region.identifier, inCollection: "Regions", forPlugin: self), name = node.name else {
            return "?"
        }
        
        return name
    }
    private func cachedNode(node: APBeaconForestNode, representsBeacon beacon: CLBeacon) -> Bool {
        return (
            node.proximityUUID.UUIDString == beacon.proximityUUID.UUIDString &&
                node.major == beacon.major.integerValue &&
                node.minor == beacon.minor.integerValue)
    }
    private func tackRangedBeacon(beacon: CLBeacon) {
        let key = "\(beacon.proximityUUID.UUIDString).\(beacon.major.integerValue).\(beacon.minor.integerValue)"
        var trackedInfo = rangedBeacons[key] ?? (beacon, 0)
        
        trackedInfo.count += 1
        rangedBeacons[key] = trackedInfo
    }
    private func persistCurrentRegionIdentifiers(newIdentifiers: Set<String>) {
        hub?.cache.removeResourcesFrom(collection: "RegionIdentifiers", forPlugin: self)
        for id in newIdentifiers {
            hub?.cache.store(NPBeaconForestRegion(json: JSON(dictionary: ["id": id]))!, inCollection: "RegionIdentifiers", forPlugin: self)
        }
    }
    private func currentRegionIdentifiers() -> Set<String> {
        guard let resources: [NPBeaconForestRegion] = hub?.cache.resourcesIn(collection: "RegionIdentifiers", forPlugin: self) else {
            return Set()
        }
        
        var identifiers = Set<String>()
        for resource in resources {
            identifiers.insert(resource.id)
        }
        
        return identifiers
    }
    private func processTargetRegionIdentifiers(newIdentifiers: Set<String>) -> (accepted: Set<CLBeaconRegion>, discarded: Set<CLBeaconRegion>) {
        guard let resources: [NPBeaconForestRegion] = hub?.cache.resourcesIn(collection: "RegionIdentifiers", forPlugin: self) else {
            return (accepted: navigator.identifiersToRegions(newIdentifiers), discarded: Set())
        }
        
        var currentIdentifiers = Set<String>()
        for resource in resources {
            currentIdentifiers.insert(resource.id)
        }
        
        let acceptedSet = newIdentifiers.subtract(currentIdentifiers)
        let discardedSet = currentIdentifiers.subtract(newIdentifiers)
        
        let event = PluginEvent(
            from: name,
            content: JSON(dictionary: ["source-regions": Array(newIdentifiers), "accepted-regions": Array(acceptedSet), "discarded-regions": Array(discardedSet)]),
            pluginCommand: "-")
        hub?.dispatch(event: event)
        
        return (accepted: navigator.identifiersToRegions(acceptedSet), discarded: navigator.identifiersToRegions(discardedSet))
    }
}
