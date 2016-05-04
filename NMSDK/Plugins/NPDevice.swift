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
        return "0.2"
    }
    override var supportedCommands: Set<String> {
        return Set(["refresh"])
    }
    
    override func run(command: String, arguments: JSON, sender: String?) -> PluginResponse {
        switch command {
        case "refresh":
            return refresh(arguments)
        default:
            Console.commandNotSupportedError(NPDevice.self, supportedCommands: supportedCommands)
            return PluginResponse.commandNotSupported(command)
        }
    }
    
    // MARK: Refresh
    func refresh(arguments: JSON, didRefresh: ((status: DeviceInstallationStatus, installation: APDeviceInstallation?) -> Void)? = nil) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPDevice.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "apns-token"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "apns-token"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        guard let installations: [APDeviceInstallation] = hub?.cache.resourcesIn(collection: "Installations", forPlugin: self), installation = installations.first else {
            APDevice.requestInstallationID(NearSDKVersion: NearSDK.currentVersion, APNSToken: arguments.string("apns-token"), response: { (installation, status) in
                self.manageSyncResponse(true, installation: installation, status: status, response: didRefresh)
            })
            
            return PluginResponse.ok(command: "refresh")
        }
        
        APDevice.updateInstallationID(installation.id, NearSDKVersion: NearSDK.currentVersion, APNSToken: arguments.string("apns-token")) { (installation, status) in
            self.manageSyncResponse(false, installation: installation, status: status, response: didRefresh)
        }
        
        return PluginResponse.ok(command: "refresh")
    }
    private func manageSyncResponse(didRequestNewID: Bool, installation: APDeviceInstallation?, status: HTTPStatusCode, response: ((status: DeviceInstallationStatus, installation: APDeviceInstallation?) -> Void)?) {
        guard let object = installation where status == (didRequestNewID ? .Created : .OK) else {
            Console.error(NPDevice.self, text: "Cannot \(didRequestNewID ? "receive" : "refresh") installation identifier")
            
            let event = (didRequestNewID ?
                NearSDKError.CannotReceiveInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)", command: "sync") :
                NearSDKError.CannotUpdateInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)", command: "sync")
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
