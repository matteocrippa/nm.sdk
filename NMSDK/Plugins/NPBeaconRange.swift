//
//  NPBeaconRange.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMJSON
import NMPlug

class NPBeaconRange: StatefulPlugin, CLLocationManagerDelegate {
    // MARK: In-memory cache
    private var locationManager = CLLocationManager()
    
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-beacon-range"
    }
    override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    // MARK: StatefulPluggable - override
    override func start(arguments: JSON) -> Bool {
        // The plugin must not be in a running state and it should not be ranging any region
        if isRunning || locationManager.rangedRegions.count > 0 {
            return false
        }
        
        // CLAuthorizationStatus must be .AuthorizedAlways or .AuthorizedWhenInUse
        if ![CLAuthorizationStatus.AuthorizedAlways, CLAuthorizationStatus.AuthorizedWhenInUse].contains(CLLocationManager.authorizationStatus()) {
            return false
        }
        
        // The configuration cannot be empty, otherwise no regions will be ranged
        guard let rangedRegions = loadConfiguration() where rangedRegions.count > 0 else {
            return false
        }
        
        // Start ranging beacons in configured regions
        for (identifier, uuid) in rangedRegions {
            locationManager.startRangingBeaconsInRegion(CLBeaconRegion(proximityUUID: uuid, identifier: identifier))
        }
        
        return super.start()
    }
    override func stop() -> Bool {
        // The plugin must be in a running and it should not be ranging any region
        if !isRunning || locationManager.rangedRegions.count <= 0 {
            super.stop()
            return false
        }
        
        // Stop ranging ranged regions
        let rangedRegions = locationManager.rangedRegions
        for region in rangedRegions {
            locationManager.stopMonitoringForRegion(region)
        }
        
        return super.stop()
    }
    
    // MARK: Setup
    func loadConfiguration() -> [String: NSUUID]? {
        // The SDK should have downloaded beacons' configuration with core plugin NPSDKConfiguration
        guard let
            configuration = hub?.send(direct: PluginDirectMessage(from: name, to: "com.nearit.plugin.np-sdk-configuration", content: JSON(dictionary: ["command": "read_configuration", "scope": "beacons"]))),
            beacons = configuration.content.dictionaryArray("objects.beacons") where beacons.count > 0 else {
                return nil
        }
        
        // Get only "unique" regions, i.e. all configured unique identifiers
        var rangedRegions = [String: NSUUID]()
        for beacon in beacons {
            if let object = Beacon(dictionary: beacon) {
                rangedRegions["region-\(object.uuid.UUIDString)"] = object.uuid
            }
        }
        
        return rangedRegions
    }
    
    // MARK: CLLocationManagerDelegate protocol methods
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        if beacons.count <= 0 {
            return
        }
        
        var keys = [String]()
        for beacon in beacons {
            keys.append("\(beacon.proximityUUID.UUIDString).\(beacon.major.integerValue).\(beacon.minor.integerValue).\(beacon.proximity.rawValue)")
        }
        
        hub?.send(direct: PluginDirectMessage(from: name, to: "com.nearit.plugin.np-evaluator", content: JSON(dictionary: ["command": "evaluate", "beacon_keys": keys])))
    }
}
