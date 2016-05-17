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
        return ["sync": sync, "index": index, "evaluate": evaluate, "evaluate-recipe-by-id": evaluateByID]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["download": download]
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
                Console.infoLine("             name: \(recipe.name)", symbol: .Space)
                Console.infoLine("notification text: \(recipe.notificationText)", symbol: .Space)
                Console.infoLine("     pulse plugin: \(recipe.pulse(.Plugin))", symbol: .Space)
                Console.infoLine("     pulse bundle: \(recipe.pulse(.Bundle))", symbol: .Space)
                Console.infoLine("     pulse action: \(recipe.pulse(.Action))", symbol: .Space)
                Console.infoLine(" operation plugin: \(recipe.operation(.Plugin))", symbol: .Space)
                Console.infoLine(" operation bundle: \(recipe.operation(.Bundle))", symbol: .Space)
                Console.infoLine(" operation action: \(recipe.operation(.Action))", symbol: .Space)
                Console.infoLine("  reaction plugin: \(recipe.reaction(.Plugin))", symbol: .Space)
                Console.infoLine("  reaction bundle: \(recipe.reaction(.Bundle))", symbol: .Space)
                Console.infoLine("  reaction action: \(recipe.reaction(.Action))", symbol: .Space)
                
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
        guard let pulsePlugin = arguments.string("pulse-plugin"), pulseBundle = arguments.string("pulse-bundle"), pulseAction = arguments.string("pulse-action") else {
            Console.commandError(NPRecipes.self, command: "evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"])
            return PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"])
        }
        
        let evaluationKey = APRecipe.evaluationKey(pulsePlugin: pulsePlugin, pulseBundle: pulseBundle, pulseAction: pulseAction)
        Console.info(NPRecipes.self, text: "Will evaluate recipe \(evaluationKey)")
        
        guard let pluginHub = hub, recipeMap: APRecipeMap = hub?.cache.resource(evaluationKey, inCollection: "RecipesMaps", forPlugin: self) else {
            Console.commandWarning(NPRecipes.self, command: "evaluate", cause: "Cannot evaluate recipe \(evaluationKey)")
            self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" not found", command: "evaluate"))
            return PluginResponse.warning("Cannot evaluate recipe \(evaluationKey)", command: "evaluate")
        }
        
        Console.info(NPRecipes.self, text: "Evaluating recipes in map \(recipeMap.id)")
        for id in recipeMap.recipes {
            Console.infoLine("key: \(recipeMap.recipeKey)")
            Console.infoLine("map: \(id)")
            
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
            Console.infoLine("content id: \(recipe.reaction(.Bundle))")
            Console.infoLine("      type: \(recipe.reaction(.Plugin))")
            
            let reaction = JSON(dictionary: ["reaction": response.content.dictionary, "recipe": recipe.json.dictionary, "type": recipe.reaction(.Plugin)])
            return pluginHub.dispatch(event: PluginEvent(from: name, content: reaction, pluginCommand: "evaluate")) ?
                PluginResponse.ok(command: "evaluate") :
                PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"], cause: "Cannot send evaluation request to \(command.evaluator) for evaluation key \(evaluationKey)")
        }
        
        Console.warning(NPRecipes.self, text: "Cannot evaluate recipe \(evaluationKey)")
        Console.warningLine("content type may be invalid or no content can be found for the given recipe", symbol: .Space)
        self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" cannot be evaluated", command: "evaluate"))
        return PluginResponse.warning("Cannot evaluate recipe \(evaluationKey)", command: "evaluate")
    }
    private func evaluateByID(arguments: JSON, sender: String?) -> PluginResponse {
        guard let id = arguments.string("id") else {
            Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"])
            return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"])
        }
        
        guard let
            pluginHub = hub,
            recipe: APRecipe = pluginHub.cache.resource(id, inCollection: "Recipes", forPlugin: self),
            command = evaluatorCommand(recipe),
            response = hub?.send(command.command, fromPluginNamed: name, toPluginNamed: command.evaluator, withArguments: command.args) where response.status == .OK else {
                Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
                return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
        }
        
        let reaction = JSON(dictionary: ["reaction": response.content.dictionary, "recipe": recipe.json.dictionary, "type": recipe.reaction(.Plugin)])
        return pluginHub.dispatch(event: PluginEvent(from: name, content: reaction, pluginCommand: "evaluate")) ?
            PluginResponse.ok(command: "evaluate") :
            PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"], cause: "Cannot send evaluation request to \(command.evaluator) for recipe \(recipe.id)")
    }
    private func download(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let id = arguments.string("id") else {
            Console.commandError(NPRecipes.self, command: "Cannot download recipe", requiredParameters: ["recipe-id"])
            completionHandler?(response: PluginResponse.cannotRun("download", requiredParameters: ["recipe-id"]))
            return
        }
        
        APRecipes.get(id) { (recipe, reaction, status) in
            guard let evaluatedRecipe = recipe, evaluatedReaction = reaction, pluginHub = self.hub, evaluator = self.evaluatorName(evaluatedRecipe) where status == .OK else {
                Console.commandError(NPRecipes.self, command: "Cannot download recipe \(id)", cause: "Cannot download the recipe, the reaction or both, plugin hub may be nil")
                return
            }
            
            let key = APRecipe.evaluationKey(pulsePlugin: evaluatedRecipe.pulse(.Plugin), pulseBundle: evaluatedRecipe.pulse(.Bundle), pulseAction: evaluatedRecipe.pulse(.Action))
            if let map: APRecipeMap = pluginHub.cache.resource(key, inCollection: "RecipesMaps", forPlugin: self) ?? APRecipeMap(json: JSON(dictionary: ["id": key, "recipes": [evaluatedRecipe.id]])) {
                map.addRecipeID(evaluatedRecipe.id)
                pluginHub.cache.store(map, inCollection: "RecipesMaps", forPlugin: self)
            }
            else {
                completionHandler?(response: PluginResponse.cannotRun("download", requiredParameters: ["id"], cause: "Recipe \(id) has been downloaded, but recipe's reaction could not be stored offline"))
                return
            }
            
            // Store contents
            pluginHub.cache.store(evaluatedRecipe, inCollection: "Recipes", forPlugin: self)
            completionHandler?(response: pluginHub.send("store-online-resource", fromPluginNamed: self.name, toPluginNamed: evaluator, withArguments: JSON(dictionary: ["resource": evaluatedReaction])).status == .OK ?
                PluginResponse.ok(JSON(dictionary: ["id": id]), command: "download") :
                PluginResponse.cannotRun("download", requiredParameters: ["id"], cause: "Recipe \(id) has been downloaded, but recipe's reaction could not be stored offline")
            )
        }
    }
    
    private func evaluatorName(recipe: APRecipe) -> String? {
        switch recipe.reaction(.Plugin) {
        case "poll-notification":
            return CorePlugin.Polls.name
        case "content-notification":
            return CorePlugin.Contents.name
        default:
            return nil
        }
    }
    private func evaluatorCommand(recipe: APRecipe) -> (command: String, args: JSON, evaluator: String)? {
        guard let evaluator = evaluatorName(recipe) else {
            return nil
        }
        
        return ("read", JSON(dictionary: ["content-id": recipe.reaction(.Bundle)]), evaluator)
    }
}
