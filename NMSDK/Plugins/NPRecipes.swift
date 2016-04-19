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
                self.hub?.dispatch(event: NearSDKError.CannotDownloadRecipes.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            self.buildCache(recipes)
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
    }
    private func buildCache(recipes: [APRecipe]) {
        hub?.cache.removeAllResourcesWithPlugin(self)
        
        var recipesMap = [String: [String]]()
        for recipe in recipes {
            hub?.cache.store(recipe, inCollection: "Recipes", forPlugin: self)
            
            let evaluationKey = APRecipe.evaluationKey(inCase: recipe.inCase, inTarget: recipe.inTarget, trigger: recipe.trigger)
            var map = recipesMap[evaluationKey] ?? []
            if !map.contains(recipe.id) {
                map.append(recipe.id)
                recipesMap[evaluationKey] = map
            }
        }
        
        for (key, identifiers) in recipesMap {
            if let resource = PluginResource(dictionary: ["id": key, "recipes": identifiers]) {
                hub?.cache.store(resource, inCollection: "RecipesMaps", forPlugin: self)
            }
        }
    }
    
    // MARK: Evaluate
    private func evaluate(key: String) -> Bool {
        guard let
            pluginHub = hub,
            recipesMap = hub?.cache.resource(key, inCollection: "RecipesMaps", forPlugin: self),
            identifiers = JSON(dictionary: recipesMap.dictionary).stringArray("recipes") else {
                self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(key)\" not found"))
                return false
        }
        
        for id in identifiers {
            guard let
                resource = hub?.cache.resource(id, inCollection: "Recipes", forPlugin: self),
                recipe = APRecipe(dictionary: resource.dictionary),
                message = evaluatorMessage(recipe),
                response = hub?.send(direct: message) where response.status == .OK else {
                    continue
            }
            
            let content = JSON(dictionary: ["content": response.content.dictionary, "type": recipe.outCase])
            return pluginHub.dispatch(event: PluginEvent(from: name, content: content))
        }
        
        self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(key)\" cannot be evaluated"))
        return false
    }
    private func evaluatorName(recipe: APRecipe) -> String? {
        switch recipe.outCase {
        case "content-notification":
            return "com.nearit.sdk.plugin.np-recipe-reaction-content"
        case "simple-notification":
            return "com.nearit.sdk.plugin.np-recipe-reaction-simple-notification"
        case "poll-notification":
            return "com.nearit.sdk.plugin.np-recipe-reaction-poll"
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
