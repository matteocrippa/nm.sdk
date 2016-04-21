//
//  ContentImage.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 21/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import UIKit
import NMJSON
import NMCache

class ContentImage: NSObject, CacheResourceSerializable {
    private (set) var id = ""
    private (set) var json = JSON(dictionary: [: ])
    var image: UIImage? {
        guard let image = json.dictionary["image"] as? UIImage else {
            return nil
        }
        
        return image
    }
    
    required init?(json: JSON) {
        super.init()
        
        guard let id = json.string("id") where json.dictionary["image"] is UIImage else {
            return nil
        }
        
        self.id = id
        self.json = json
    }
}
