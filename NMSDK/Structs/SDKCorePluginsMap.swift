//
//  SDKCorePluginsMap.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

struct SDKCorePluginsMap {
    enum Index: String {
        case SDKConfiguration = "SDKConfiguration"
    }
    
    var map = [Index: String]()
    mutating func update(index: Index, pluginName: String?) {
        guard let name = pluginName else {
            map.removeValueForKey(index)
            return
        }
        
        map[index] = name
    }
    subscript(name: String) -> Index? {
        for (i, n) in map where n == name {
            return i
        }
        
        return nil
    }
}
