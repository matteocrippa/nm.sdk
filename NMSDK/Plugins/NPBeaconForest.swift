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
        
        APBeaconForest.get { (nodes, status) in
            if status != .OK {
                return
            }
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for node in nodes {
                self.hub?.cache.store(node, inCollection: "Regions", forPlugin: self)
            }
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
    
    // MARK: Region monitoring
    private func startMonitoringRegions() {
        // TODO: must be implemented
    }
    private func stopMonitoringRegions() {
        // TODO: must be implemented
    }
}
