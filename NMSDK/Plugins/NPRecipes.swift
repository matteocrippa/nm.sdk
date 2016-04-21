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
        return CorePlugin.Recipes.name
    }
    override func run(arguments: JSON, sender: String?) -> PluginResponse {
        guard let command = arguments.string("do") else {
            Console.error(NPRecipes.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"evaluate\"")
            return PluginResponse.error("\"do\" parameter is required, must be \"sync\" or \"evaluate\"")
        }
        
        switch command {
        case "sync":
            guard let appToken = arguments.string("app-token") else {
                Console.error(NPRecipes.self, text: "Cannot run \"sync\" command")
                Console.errorLine("\"app-token\" parameter is required, \"timeout-interval\" is optional")
                return PluginResponse.error("\"app-token\" parameter is required, \"timeout-interval\" is optional")
            }
            
            sync(appToken, timeoutInterval: arguments.double("timeout-interval"))
        case "evaluate":
            guard let inCase = arguments.string("in-case"), inTarget = arguments.string("in-target"), trigger = arguments.string("trigger") else {
                Console.error(NPRecipes.self, text: "Cannot run \"evaluate\" command")
                Console.errorLine("\"evaluate\" requires \"in-case\", \"in-target\" and \"trigger\" parameters")
                return PluginResponse.error("\"evaluate\" requires \"in-case\", \"in-target\" and \"trigger\" parameters")
            }
            
            let recipeIdentifier = APRecipe.evaluationKey(inCase: inCase, inTarget: inTarget, trigger: trigger)
            return evaluate(recipeIdentifier) ?
                PluginResponse.ok() :
                PluginResponse.error("Cannot evaluate event \(recipeIdentifier)")
        default:
            Console.error(NPRecipes.self, text: "Cannot run")
            Console.errorLine("\"do\" parameter is required, must be \"sync\" or \"evaluate\"")
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"evaluate\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        Console.info(NPRecipes.self, text: "Downloading recipes...", symbol: .Download)
        APRecipes.get { (recipes, recipeMaps, status) in
            if status != .OK {
                Console.error(NPRecipes.self, text: "Cannot download recipes")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadRecipes.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPRecipes.self, text: "Saving recipes...")
            self.hub?.cache.removeAllResourcesWithPlugin(self)
            for recipe in recipes {
                self.hub?.cache.store(recipe, inCollection: "Recipes", forPlugin: self)
                
                Console.infoLine(recipe.id, symbol: .Add)
                Console.infoLine("trigger: \(recipe.trigger)", symbol: .Space)
                Console.infoLine("     in: case \(recipe.inCase), target \(recipe.inTarget)", symbol: .Space)
                Console.infoLine("    out: case \(recipe.outCase), target \(recipe.outTarget)", symbol: .Space)
            }
            Console.infoLine("recipes saved: \(recipes.count)")
            
            Console.info(NPRecipes.self, text: "Saving events-to-recipes mappings...")
            for map in recipeMaps {
                Console.infoLine("  event: \(map.id)", symbol: .To)
                Console.infoLine("maps to: \(map.recipes.joinWithSeparator(", "))")
                
                self.hub?.cache.store(map, inCollection: "RecipesMaps", forPlugin: self)
            }
            Console.infoLine("mappings saved: \(recipes.count)")
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: ["operation": "sync"])))
        }
        
    }
    
    // MARK: Evaluate
    private func evaluate(key: String) -> Bool {
        Console.info(NPRecipes.self, text: "Will evaluate recipe \(key)")
        
        guard let pluginHub = hub, recipeMap: APRecipeMap = hub?.cache.resource(key, inCollection: "RecipesMaps", forPlugin: self) else {
            Console.warning(NPRecipes.self, text: "Cannot evaluate recipe \(key)")
            Console.warningLine("recipe not found", symbol: .Space)
            self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(key)\" not found"))
            return false
        }
        
        for id in recipeMap.recipes {
            guard let
                recipe: APRecipe = hub?.cache.resource(id, inCollection: "Recipes", forPlugin: self),
                message = evaluatorMessage(recipe),
                response = hub?.send(direct: message) where response.status == .OK else {
                    continue
            }
            
            Console.info(NPRecipes.self, text: "Recipe \(key) has been evaluated")
            Console.infoLine("content id: \(recipe.outTarget)")
            Console.infoLine("      type: \(recipe.outCase)")
            let content = JSON(dictionary: ["content": response.content.dictionary, "type": recipe.outCase])
            return pluginHub.dispatch(event: PluginEvent(from: name, content: content))
        }
        
        Console.warning(NPRecipes.self, text: "Cannot evaluate recipe \(key)")
        Console.warningLine("content type may be invalid or no content can be found for the given recipe", symbol: .Space)
        self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(key)\" cannot be evaluated"))
        return false
    }
    private func evaluatorName(recipe: APRecipe) -> String? {
        switch recipe.outCase {
        case "poll-notification":
            return CorePlugin.Polls.name
        case "content-notification":
            return CorePlugin.Contents.name
        case "simple-notification":
            return CorePlugin.Notifications.name
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
