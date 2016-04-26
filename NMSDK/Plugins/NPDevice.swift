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
    
    // MARK: Refresh
    func sync(appToken: String, timeoutInterval: NSTimeInterval?, APNSToken: String?, didRefresh: ((status: DeviceInstallationStatus, installation: APDeviceInstallation?) -> Void)? = nil) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        guard let installations: [APDeviceInstallation] = hub?.cache.resourcesIn(collection: "Installations", forPlugin: self), installation = installations.first else {
            APDevice.requestInstallationID(NearSDKVersion: NearSDK.currentVersion, APNSToken: APNSToken, response: { (installation, status) in
                self.manageSyncResponse(true, installation: installation, status: status, response: didRefresh)
            })
            
            return
        }
        
        APDevice.updateInstallationID(installation.id, NearSDKVersion: NearSDK.currentVersion, APNSToken: APNSToken) { (installation, status) in
            self.manageSyncResponse(false, installation: installation, status: status, response: didRefresh)
        }
    }
    private func manageSyncResponse(didRequestNewID: Bool, installation: APDeviceInstallation?, status: HTTPStatusCode, response: ((status: DeviceInstallationStatus, installation: APDeviceInstallation?) -> Void)?) {
        guard let object = installation where status == (didRequestNewID ? .Created : .OK) else {
            Console.error(NPDevice.self, text: "Cannot \(didRequestNewID ? "receive" : "refresh") installation identifier")
            
            let event = (didRequestNewID ?
                NearSDKError.CannotObtainInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)") :
                NearSDKError.CannotUpdateInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)")
            )
            
            hub?.dispatch(event: event)
            response?(status: .NotRefreshed, installation: nil)
            return
        }
        
        Console.info(NPDevice.self, text: "Installation identifier \(didRequestNewID ? "received" : "updated")")
        Console.infoLine("identifier: \(object.id)")
        
        hub?.cache.removeAllResourcesWithPlugin(self)
        hub?.cache.store(object, inCollection: "Installations", forPlugin: self)
        
        let event = PluginEvent(from: name, content: JSON(dictionary: ["operation": "sync", "installation-id": object.id, "status": (didRequestNewID ? "received" : "updated")]))
        Console.infoLine("event \(event)")
        
        hub?.dispatch(event: event)
        response?(status: (didRequestNewID ? .Received : .Updated), installation: object)
    }
}
