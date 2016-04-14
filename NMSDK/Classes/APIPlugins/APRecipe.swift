//
//  APRecipe.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMPlug

class APRecipe: PluginResource {
    var outType: String { return json.string("out-type")! }
    var outIdentifier: String { return json.string("out-identifier")! }
    
    required init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let _ = json.string("id"), _ = json.string("out-type"), _ = json.string("out-identifier") else {
            return nil
        }
        
        super.init(dictionary: object)
    }
}
