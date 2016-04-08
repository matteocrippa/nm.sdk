//
//  NPSDKConfiguration.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet
import NMJSON
import NMPlug

class NPSDKConfiguration: Plugin {
    override var name: String {
        return "com.nearit.plugin.np-sdk-configuration"
    }
    
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        return PluginResponse.ok()
    }
}
