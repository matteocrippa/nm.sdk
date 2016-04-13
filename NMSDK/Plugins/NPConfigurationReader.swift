//
//  NPConfigurationReader.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 13/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMCache

class NPConfigurationReader {
    class func configuredBeacons(plugin: Pluggable) -> [Beacon] {
        return configuredResources(plugin, collectionName: Collections.Common.Beacons.rawValue)
    }
    
    private class func configuredResources<T: PluginResource>(plugin: Pluggable, collectionName: String) -> [T] {
        guard let resources = plugin.hub?.cache.resourcesIn(collection: collectionName, forPlugin: plugin) where resources.count > 0 else {
            return []
        }
        
        var result = [T]()
        for resource in resources {
            if let object = T(dictionary: CorePluginEvent.merge(resource.id, dictionary: resource.json.dictionary)) {
                result.append(object)
            }
        }
        
        return result
    }
}
