//
//  NPImageCache.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import UIKit
import NMJSON
import NMPlug

class NPImageCache: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.ImageCache.name
    }
    override var version: String {
        return "0.3"
    }
    override var commands: [String: RunHandler] {
        return ["store": store, "clear": clear, "read": read]
    }
    
    // MARK: Images' management
    private func store(arguments: JSON, sender: String?) -> PluginResponse {
        guard let dictionaries = arguments.dictionaryArray("images") else {
            Console.commandError(NPImageCache.self, command: "store", cause: "\"images\" must be an array of dictionaries like [\"id\": <String>, \"image\": <UIImage>]", requiredParameters: ["images"])
            return PluginResponse.cannotRun("store", requiredParameters: ["images"], cause: "\"images\" must be an array of dictionaries like [\"id\": <String>, \"image\": <UIImage>]")
        }
        
        var images = [String: UIImage]()
        for dictionary in dictionaries {
            if let id = dictionary["id"] as? String, image = dictionary["image"] as? UIImage {
                images[id] = image
            }
        }
        
        for (id, image) in images {
            if let resource = ContentImage(json: JSON(dictionary: ["id": id, "image": image])) {
                hub?.cache.store(resource, inCollection: "Images", forPlugin: self)
            }
        }
        
        return PluginResponse.ok(command: "store")
    }
    private func clear(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.cache.removeAllResourcesWithPlugin(self)
        return PluginResponse.ok(command: "clear")
    }
    private func read(arguments: JSON, sender: String?) -> PluginResponse {
        guard let identifiers = arguments.stringArray("identifiers") else {
            Console.commandError(NPImageCache.self, command: "read", cause: "\"identifiers\" must be an array of String identifiers", requiredParameters: ["identifiers"])
            return PluginResponse.cannotRun("read", requiredParameters: ["identifiers"], cause: "\"identifiers\" must be an array of String identifiers")
        }
        
        var images = [String: AnyObject]()
        if let resources: [ContentImage] = hub?.cache.resourcesIn(collection: "Images", forPlugin: self) {
            for resource in resources where identifiers.contains(resource.id) {
                if let image = resource.image {
                    images[resource.id] = image
                }
            }
        }
        
        return PluginResponse.ok(JSON(dictionary: ["images": images]), command: "read")
    }
}
