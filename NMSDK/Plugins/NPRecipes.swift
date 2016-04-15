//
//  NPRecipes.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 14/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPRecipes: Plugin {
    // MARK: Plugin override
    override var name: String {
        return "com.nearit.sdk.plugin.np-recipes"
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\" or \"evaluate\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        case "evaluate":
            guard let inCase = arguments.string("in-case"), inTarget = arguments.string("in-target"), trigger = arguments.string("trigger") else {
                return PluginResponse.error("\"evaluate\" requires \"in-case\", \"in-target\" and \"trigger\" parameters")
            }
            
            let recipeIdentifier = APRecipe.evaluationKey(inCase: inCase, inTarget: inTarget, trigger: trigger)
            return evaluate(recipeIdentifier) ?
                PluginResponse.ok() :
                PluginResponse.error("Cannot evaluate event \(recipeIdentifier)")
        default:
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"evaluate\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        APRecipes.get { (recipes, status) in
            if status != .OK {
                return
            }
            
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for recipe in recipes {
                self.hub?.cache.store(recipe, inCollection: "Recipes", forPlugin: self)
            }
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
    
    // MARK: Evaluate
    private func evaluate(recipeIdentifier: String) -> Bool {
        guard let
            resource = hub?.cache.resource(recipeIdentifier, inCollection: "Recipes", forPlugin: self),
            recipe = APRecipe(dictionary: resource.dictionary),
            message = evaluatorMessage(recipe),
            response = hub?.send(direct: message) else {
                return false
        }
        
        guard let pluginHub = hub else {
            return false
        }
        
        let content = JSON(dictionary: ["content": response.content.dictionary, "type": recipe.outCase])
        return pluginHub.dispatch(event: PluginEvent(from: name, content: content))
    }
    private func evaluatorName(recipe: APRecipe) -> String? {
        switch recipe.outCase {
        case "content-notification":
            return "com.nearit.sdk.plugin.np-recipe-reaction-content"
        case "simple-notification":
            return "com.nearit.sdk.plugin.np-recipe-reaction-simple-notification"
        default:
            return nil
        }
    }
    private func evaluatorMessage(recipe: APRecipe) -> PluginDirectMessage? {
        guard let evaluator = evaluatorName(recipe) else {
            return nil
        }
        
        return PluginDirectMessage(from: name, to: evaluator, content: JSON(dictionary: ["do": "read", "content": recipe.outTarget]))
    }
}
