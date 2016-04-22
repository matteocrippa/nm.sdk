//
//  NPDevice.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 22/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPDevice: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.Device.name
    }
    override var version: String {
        return "0.1"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPBeaconForest.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\"")
            
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPBeaconForest.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                Console.errorLine("\"apns-token\" parameter is optional and, if provided, must be a valid UUID string, otherwise it will be ignored")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" and \"apns-token\" are optional: if \"app-token\" is defined, it must be a valid UUID string, otherwise it will be ignored")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"), APNSToken: arguments.string("apns-token"))
            return PluginResponse.ok()
        default:
            Console.error(NPBeaconForest.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\"")
        }
    }
    
    // MARK: Update
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?, APNSToken: String?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        guard let installations: [APDeviceInstallation] = hub?.cache.resourcesIn(collection: "Installations", forPlugin: self), installation = installations.first else {
            requestInstallation(APNSToken)
            return
        }
        
        updateInstallation(installation, APNSToken: APNSToken)
    }
    private func requestInstallation(APNSToken: String?) {
        APDevice.requestInstallationID(NearSDKVersion: NearSDK.currentVersion, APNSToken: APNSToken) { (installation, status) in
            guard let object = installation where status == .Created else {
                Console.error(NPDevice.self, text: "Cannot obtain installation identifier")
                self.hub?.dispatch(event: NearSDKError.CannotObtainInstallationID.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPDevice.self, text: "Installation identifier received")
            Console.infoLine("identifier: \(object.id)")
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            self.hub?.cache.store(object, inCollection: "Installations", forPlugin: self)
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync", "installation-id": object.id, "status": "obtained"])))
        }
    }
    private func updateInstallation(installation: APDeviceInstallation, APNSToken: String?) {
        APDevice.updateInstallationID(installation.id, NearSDKVersion: NearSDK.currentVersion, APNSToken: APNSToken) { (installation, status) in
            guard let object = installation where status == .OK else {
                Console.error(NPDevice.self, text: "Cannot update installation identifier")
                self.hub?.dispatch(event: NearSDKError.CannotUpdateInstallationID.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPDevice.self, text: "Installation identifier updated")
            Console.infoLine("identifier: \(object.id)")
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            self.hub?.cache.store(object, inCollection: "Installations", forPlugin: self)
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync", "installation-id": object.id, "status": "updated"])))
        }
    }
}
