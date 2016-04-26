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
        return "0.1"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPImageCache.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"store\", \"read\" or \"clear\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"store\", \"read\" or \"clear\"")
        }
        
        switch command {
        case "store":
            guard let dictionaries = arguments.dictionaryArray("images") else {
                Console.error(NPImageCache.self, text: "Cannot run \"store\" command")
                Console.errorLine("\"images\" parameter is required, it must be an array of dictionaries like [\"id\": <String>, \"image\": <UIImage>]")
                return PluginResponse.error("\"images\" parameter is required, it must be an array of dictionaries like [\"id\": <String>, \"image\": <UIImage>]")
            }
            
            var images = [String: UIImage]()
            for dictionary in dictionaries {
                if let id = dictionary["id"] as? String, image = dictionary["image"] as? UIImage {
                    images[id] = image
                }
            }
            
            store(images)
            return PluginResponse.ok()
        case "read":
            guard let identifiers = arguments.stringArray("identifiers") else {
                Console.error(NPImageCache.self, text: "Cannot run \"read\" command")
                Console.errorLine("\"identifiers\" parameter is required, it must be an array of String identifiers")
                return PluginResponse.error("\"identifiers\" parameter is required, it must be an array of String identifiers")
            }
            
            return PluginResponse.ok(JSON(dictionary: ["images": read(identifiers)]))
        case "clear":
            clear()
            return PluginResponse.ok()
        default:
            Console.error(NPImageCache.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"store\", \"read\" or \"clear\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"store\", \"read\" or \"clear\"")
        }
    }
    
    // MARK: Images' management
    private func store(images: [String: UIImage]) {
        for (id, image) in images {
            if let resource = ContentImage(json: JSON(dictionary: ["id": id, "image": image])) {
                hub?.cache.store(resource, inCollection: "Images", forPlugin: self)
            }
        }
    }
    private func clear() {
        hub?.cache.removeAllResourcesWithPlugin(self)
    }
    private func read(identifiers: [String]) -> [String: AnyObject] {
        var images = [String: AnyObject]()
        if let resources: [ContentImage] = hub?.cache.resourcesIn(collection: "Images", forPlugin: self) {
            for resource in resources where identifiers.contains(resource.id) {
                if let image = resource.image {
                    images[resource.id] = image
                }
            }
        }
        
        return images
    }
}
