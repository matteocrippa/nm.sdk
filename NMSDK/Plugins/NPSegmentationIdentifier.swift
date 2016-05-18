//
//  NPSegmentationIdentifier.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMCache

class NPSegmentationIdentifier: NSObject, CacheResourceSerializable {
    private (set) var id = ""
    private (set) var json = JSON()
    
    required init?(json: JSON) {
        guard let id = json.string("id") else {
            return nil
        }
        
        self.id = id
        self.json = json
    }
}
