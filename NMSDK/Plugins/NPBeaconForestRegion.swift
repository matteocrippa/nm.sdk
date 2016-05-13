//
//  NPBeaconForestRegion.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 13/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMCache

class NPBeaconForestRegion: NSObject, CacheResourceSerializable {
    var id = ""
    var json = JSON()
    
    required init?(json: JSON) {
        guard let id = json.string("id") else {
            return nil
        }
        
        self.id = id
        self.json = json
    }
}