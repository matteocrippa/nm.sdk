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
    override var version: String {
        return "0.3"
    }
    override var commands: [String: RunHandler] {
        return ["sync": sync, "index": index, "evaluate": evaluate]
    }
    
    // MARK: Sync
    private func sync(arguments: JSON, sender: String?) -> PluginResponse {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipes.self, command: "sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            return PluginResponse.cannotRun("sync", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPRecipes.self, text: "Downloading recipes...", symbol: .Download)
        APRecipes.get { (recipes, recipeMaps, status) in
            if status != .OK {
                Console.error(NPRecipes.self, text: "Cannot download recipes")
                self.hub?.dispatch(event: NearSDKError.CannotDownloadRecipes.pluginEvent(self.name, message: "HTTPStatusCode \(status.rawValue)", command: "sync"))
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
            
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: "sync"))
        }
        
        return PluginResponse.ok(command: "sync")
    }
    
    // MARK: Index
    private func index(arguments: JSON, sender: String?) -> PluginResponse {
        var maps = [String: [Recipe]]()
        guard let recipeMaps: [APRecipeMap] = hub?.cache.resourcesIn(collection: "RecipesMaps", forPlugin: self) else {
            return PluginResponse.ok(JSON(dictionary: ["triggers": maps]), command: "index")
        }
        
        for map in recipeMaps {
            var recipes = [Recipe]()
            for id in map.recipes {
                if let recipe: APRecipe = hub?.cache.resource(id, inCollection: "Recipes", forPlugin: self) {
                    recipes.append(Recipe(recipe: recipe))
                }
            }
            
            maps[map.recipeKey] = recipes
        }
        
        return PluginResponse.ok(JSON(dictionary: ["triggers": maps]), command: "index")
    }
    
    // MARK: Evaluate
    private func evaluate(arguments: JSON, sender: String?) -> PluginResponse {
        guard let inCase = arguments.string("in-case"), inTarget = arguments.string("in-target"), trigger = arguments.string("trigger") else {
            Console.commandError(NPRecipes.self, command: "evaluate", requiredParameters: ["in-case", "in-target", "trigger"])
            return PluginResponse.cannotRun("evaluate", requiredParameters: ["in-case", "in-target", "trigger"])
        }
        
        let evaluationKey = APRecipe.evaluationKey(inCase: inCase, inTarget: inTarget, trigger: trigger)
        Console.info(NPRecipes.self, text: "Will evaluate recipe \(evaluationKey)")
        
        guard let pluginHub = hub, recipeMap: APRecipeMap = hub?.cache.resource(evaluationKey, inCollection: "RecipesMaps", forPlugin: self) else {
            Console.commandWarning(NPRecipes.self, command: "evaluate", cause: "Cannot evaluate recipe \(evaluationKey)")
            self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" not found", command: "evaluate"))
            return PluginResponse.warning("Cannot evaluate recipe \(evaluationKey)", command: "evaluate")
        }
        
        for id in recipeMap.recipes {
            guard let
                recipe: APRecipe = hub?.cache.resource(id, inCollection: "Recipes", forPlugin: self),
                command = evaluatorCommand(recipe),
                response = hub?.send(command.command, fromPluginNamed: name, toPluginNamed: command.evaluator, withArguments: command.args) else {
                    continue
            }
            
            if response.status != .OK {
                Console.error(NPRecipes.self, text: "Cannot evaluate reaction")
                return PluginResponse.cannotForward(command.command, toPluginNamed: command.evaluator, targetPluginResponse: response)
            }
            
            Console.info(NPRecipes.self, text: "Recipe \(evaluationKey) has been evaluated")
            Console.infoLine("content id: \(recipe.outTarget)")
            Console.infoLine("      type: \(recipe.outCase)")
            
            let reaction = JSON(dictionary: ["reaction": response.content.dictionary, "recipe": recipe.json.dictionary, "type": recipe.outCase])
            return pluginHub.dispatch(event: PluginEvent(from: name, content: reaction, pluginCommand: "evaluate")) ?
                PluginResponse.ok(command: "evaluate") :
                PluginResponse.cannotRun("evaluate", requiredParameters: ["in-case", "in-target", "trigger"], cause: "Cannot send evaluation request to \(command.evaluator) for evaluation key \(evaluationKey)")
        }
        
        Console.warning(NPRecipes.self, text: "Cannot evaluate recipe \(evaluationKey)")
        Console.warningLine("content type may be invalid or no content can be found for the given recipe", symbol: .Space)
        self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" cannot be evaluated", command: "evaluate"))
        return PluginResponse.warning("Cannot evaluate recipe \(evaluationKey)", command: "evaluate")
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
    private func evaluatorCommand(recipe: APRecipe) -> (command: String, args: JSON, evaluator: String)? {
        guard let evaluator = evaluatorName(recipe) else {
            return nil
        }
        
        return ("read", JSON(dictionary: ["content-id": recipe.outTarget]), evaluator)
    }
}
