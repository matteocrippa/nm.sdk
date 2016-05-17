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
        return "0.3"
    }
    override var commands: [String: RunHandler] {
        return ["read": read]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["refresh": refresh]
    }
    
    // MARK: Read
    func read(arguments: JSON, sender: String?) -> PluginResponse {
        guard let installations: [APDeviceInstallation] = hub?.cache.resourcesIn(collection: "Installations", forPlugin: self), installation = installations.first else {
            return PluginResponse.cannotRun("read", requiredParameters: [], optionalParameters: [], cause: "No installation identifier can be found")
        }
        
        return PluginResponse.ok(JSON(dictionary: ["installation-id": installation.id]), command: "read")
    }
    
    // MARK: Refresh
    func refresh(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPDevice.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "apns-token"])
            completionHandler?(response: PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "apns-token"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        guard let installations: [APDeviceInstallation] = hub?.cache.resourcesIn(collection: "Installations", forPlugin: self), installation = installations.first else {
            APDevice.requestInstallationID(NearSDKVersion: NearSDK.currentVersion, APNSToken: arguments.string("apns-token"), response: { (installation, status) in
                self.manageSyncResponse(true, installation: installation, status: status, completionHandler: completionHandler)
            })
            
            return
        }
        
        APDevice.updateInstallationID(installation.id, NearSDKVersion: NearSDK.currentVersion, APNSToken: arguments.string("apns-token")) { (installation, status) in
            self.manageSyncResponse(false, installation: installation, status: status, completionHandler: completionHandler)
        }
    }
    private func manageSyncResponse(didRequestNewID: Bool, installation: APDeviceInstallation?, status: HTTPStatusCode, completionHandler: ResponseHandler?) {
        guard let object = installation where status == (didRequestNewID ? .Created : .OK) else {
            Console.error(NPDevice.self, text: "Cannot \(didRequestNewID ? "receive" : "refresh") installation identifier")
            
            let event = (didRequestNewID ?
                NearSDKError.CannotReceiveInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)", command: "refresh") :
                NearSDKError.CannotUpdateInstallationID.pluginEvent(name, message: "HTTPStatusCode \(status.rawValue)", command: "refresh")
            )
            
            completionHandler?(response: PluginResponse(status: .Error, content: event.content, command: "refresh"))
            return
        }
        
        Console.info(NPDevice.self, text: "Installation identifier \(didRequestNewID ? "received" : "updated")")
        Console.infoLine("identifier: \(object.id)")
        
        if let token = object.APNSToken {
            Console.infoLine("APNS token: \(token)")
        }
        
        hub?.cache.removeAllResourcesWithPlugin(self)
        hub?.cache.store(object, inCollection: "Installations", forPlugin: self)
        
        completionHandler?(response: PluginResponse.ok(
            JSON(dictionary: ["status": (didRequestNewID ? DeviceInstallationStatus.Received : DeviceInstallationStatus.Updated).rawValue, "installation": DeviceInstallation(installation: object)]),
            command: "refresh"))
    }
}
