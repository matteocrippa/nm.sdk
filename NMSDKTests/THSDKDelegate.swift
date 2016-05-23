//
//  THSDKDelegate.swift
//  NMPlug
//
//  Created by Francesco Colleoni on 31/03/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import UIKit
import NMJSON
import NMNet
import NMSDK
import NMPlug

class THSDKDelegate: NSObject, NearSDKDelegate {
    var didReceiveEvent: ((event: PluginEvent) -> Void)?
    var didReceiveError: ((error: NearSDKError, message: String) -> Void)?
    var didEvaluateRecipe: ((recipe: Recipe) -> Void)?
    var didReceiveDidEvaluateRecipeCommand: ((arguments: JSON) -> Void)?
    var didReceiveDidDetectRegionEvent: ((arguments: JSON) -> Void)?
    var sdkDidSync: ((errors: [CorePluginError]) -> Void)?
    var sdkPluginDidSync: ((plugin: CorePlugin, error: CorePluginError?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func clearHandlers() {
        didReceiveEvent = nil
        didReceiveError = nil
        didEvaluateRecipe = nil
        didReceiveDidEvaluateRecipeCommand = nil
        didReceiveDidDetectRegionEvent = nil
        sdkDidSync = nil
        sdkPluginDidSync = nil
    }
    
    func nearSDKDidSync(errors: [CorePluginError]) {
        sdkDidSync?(errors: errors)
    }
    func nearSDKPluginDidSync(plugin: CorePlugin, error: CorePluginError?) {
        sdkPluginDidSync?(plugin: plugin, error: error)
    }
    func nearSDKDidReceiveEvent(event: PluginEvent) {
        if let command = event.command where event.from == "com.near.sampleplugin" {
            switch command {
            case "evaluate-recipe":
                didReceiveDidEvaluateRecipeCommand?(arguments: event.content)
            case "enter-region":
                didReceiveDidDetectRegionEvent?(arguments: event.content)
            case "exit-region":
                didReceiveDidDetectRegionEvent?(arguments: event.content)
            default:
                break
            }
        }
        
        didReceiveEvent?(event: event)
    }
    func nearSDKDidFail(error error: NearSDKError, message: String) {
        didReceiveError?(error: error, message: message)
    }
    func nearSDKDidEvaluateRecipe(recipe: Recipe) {
        didEvaluateRecipe?(recipe: recipe)
    }
}
