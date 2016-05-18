//
//  NPSegmentation.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMCache
import NMPlug
import NMJSON
import NMNet

class NPSegmentation: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.Segmentation.name
    }
    override var version: String {
        return "0.1"
    }
    override var commands: [String: RunHandler] {
        return ["read": read, "save": save, "clear": clear]
    }
    /*
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["request-new-profile-id": requestNewProfileID, "add-data-points": addDataPoints]
    }*/
    
    // MARK: Read / Write
    func read(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pluginHub = hub else {
            return PluginResponse.cannotRun("read")
        }
        
        guard let resources: [NPSegmentationIdentifier] = pluginHub.cache.resourcesIn(collection: "SegmentationIdentifiers", forPlugin: self), resource = resources.first else {
            return PluginResponse.ok(JSON(), command: "read")
        }
        
        return PluginResponse.ok(JSON(dictionary: ["profile-id": resource.id]), command: "read")
    }
    func save(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pluginHub = hub, id = arguments.string("id") else {
            return PluginResponse.cannotRun("save", requiredParameters: ["id"])
        }
        
        let resource = NPSegmentationIdentifier(json: JSON(dictionary: ["id": id]))!
        pluginHub.cache.removeAllResourcesWithPlugin(self)
        pluginHub.cache.store(resource, inCollection: "SegmentationIdentifiers", forPlugin: self)
        
        return PluginResponse.ok(command: "save")
    }
    func clear(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pluginHub = hub else {
            return PluginResponse.cannotRun("clear")
        }
        
        pluginHub.cache.removeAllResourcesWithPlugin(self)
        return PluginResponse.ok(command: "clear")
    }
}
