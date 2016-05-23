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
        return ["evaluate-recipe": evaluateRecipe, "enter-region": enterRegion, "exit-region": exitRegion]
    }
    override var observedBroadcastKeys: [String] {
        return ["recipes", "beacon-forest"]
    }
    
    private func evaluateRecipe(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "evaluate-recipe"))
        return PluginResponse.ok(arguments, command: "evaluate-recipe")
    }
    private func enterRegion(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "enter-region"))
        return PluginResponse.ok(arguments, command: "enter-region")
    }
    private func exitRegion(arguments: JSON, sender: String?) -> PluginResponse {
        hub?.dispatch(event: PluginEvent(from: name, content: arguments, pluginCommand: "exit-region"))
        return PluginResponse.ok(arguments, command: "exit-region")
    }
}
