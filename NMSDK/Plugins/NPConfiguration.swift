//
//  NPConfiguration.swift
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

class NPConfiguration: Plugin {
    private var configurationManager = NPConfigurationManager()
    
    // MARK: Plugin - override
    override var name: String {
        return "com.nearit.plugin.np-configuration"
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
            
            configurationManager.sync(plugin: self, appToken: appToken, timeoutInterval: (arguments.double("timeout_interval") ?? 10))
            return PluginResponse.ok()
        case "read_configuration":
            guard let scope = arguments.string("scope") else {
                return PluginResponse.error("\"read_configuration\" command requires argument \"scope\" to be equal to \"beacons\"")
            }
            
            switch scope {
            case "beacons":
                return PluginResponse.ok(CorePluginEvent.configurationBody(NPConfigurationReader.configuredBeacons(self), command: command, scope: scope))
            default:
                return PluginResponse.error("\"read_configuration\" command requires argument \"scope\" to be equal to \"beacons\"")
            }
        default:
            break
        }
        
        return PluginResponse.error("\"command\" argument is required; allowed values: \"sync\", \"read_configuration\"")
    }
}
