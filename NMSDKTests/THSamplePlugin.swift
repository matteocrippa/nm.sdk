//
//  THSamplePlugin.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 23/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMPlug

class THSamplePlugin: Plugin {
    override var name: String {
        return "com.near.sampleplugin"
    }
    override var commands: [String: RunHandler] {
        return [
            "nearSDKDidEvaluateRecipe": nearSDKDidEvaluateRecipe,
            "beaconForestDidEnterRegion": beaconForestDidEnterRegion,
            "beaconForestDidExitRegion": beaconForestDidExitRegion
        ]
    }
    override var observedBroadcastKeys: [String] {
        return ["nearSDKDidEvaluateRecipe", "beaconForestDidEnterRegion", "beaconForestDidExitRegion"]
    }
    
    private func nearSDKDidEvaluateRecipe(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "nearSDKDidEvaluateRecipe"))
        return PluginResponse.ok(arguments, command: "nearSDKDidEvaluateRecipe")
    }
    private func beaconForestDidEnterRegion(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "beaconForestDidEnterRegion"))
        return PluginResponse.ok(arguments, command: "beaconForestDidEnterRegion")
    }
    private func beaconForestDidExitRegion(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "beaconForestDidExitRegion"))
        return PluginResponse.ok(arguments, command: "beaconForestDidExitRegion")
    }
}
