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
        return "0.8"
    }
    override var commands: [String: RunHandler] {
        return ["index": index, "evaluate": evaluate, "evaluate-recipe-by-id": evaluateByID, "clear": clear]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return [
            "download": download,
            "download-processed-recipes": downloadProcessedRecipes,
            "evaluate-online-pulse": evaluateOnlinePulse,
            "evaluate-online-id": evaluateOnlineID]
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
    private func clear(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pluginHub = hub else {
            return PluginResponse.cannotRun("clear")
        }
        
        pluginHub.cache.removeAllResourcesWithPlugin(self)
        return PluginResponse.ok(command: "clear")
    }
    
    // MARK: Evaluate
    private func evaluate(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pulsePlugin = arguments.string("pulse-plugin"), pulseBundle = arguments.string("pulse-bundle"), pulseAction = arguments.string("pulse-action") else {
            Console.commandError(NPRecipes.self, command: "evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"])
            return PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"])
        }
        
        let evaluationKey = APRecipe.evaluationKey(pulsePlugin: pulsePlugin, pulseBundle: pulseBundle, pulseAction: pulseAction)
        Console.info(NPRecipes.self, text: "Will evaluate recipe \(evaluationKey)")
        
        var failedEvaluation: [String: AnyObject] = [
            "pulse": [
                "plugin": pulsePlugin,
                "action": pulseAction,
                "bundle": pulseBundle
            ]
        ]
        
        guard let pluginHub = hub, recipeMap: APRecipeMap = hub?.cache.resource(evaluationKey, inCollection: "RecipesMaps", forPlugin: self) else {
            Console.commandWarning(NPRecipes.self, command: "evaluate", cause: "Cannot evaluate recipe \(evaluationKey)")
            self.hub?.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" not found", command: "evaluate", details: failedEvaluation))
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
                failedEvaluation["recipe"] = [
                    "id": id,
                    "online": recipe.online
                ]
                
                pluginHub.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(name, message: "Cannot evaluate recipe \(id) for evaluation key \(evaluationKey)", command: "evaluate", details: failedEvaluation))
                return PluginResponse.cannotForward(command.command, toPluginNamed: command.evaluator, targetPluginResponse: response)
            }
            
            Console.info(NPRecipes.self, text: "Recipe \(evaluationKey) has been evaluated")
            Console.infoLine("content id: \(recipe.reaction(.Bundle))")
            Console.infoLine("      type: \(recipe.reaction(.Plugin))")
            
            let reaction = JSON(dictionary: ["reaction": [command.contentType: response.content.dictionary], "recipe": recipe.json.dictionary, "type": recipe.reaction(.Plugin)])
            
            let broadcast = JSON(dictionary: ["pulse": ["plugin": pulsePlugin, "bundle": pulseBundle, "action": pulseAction], "evaluation": reaction.dictionary])
            hub?.broadcast("evaluate-recipe", fromPluginNamed: name, toKey: "recipes", withArguments: broadcast)
            
            return pluginHub.dispatch(event: PluginEvent(from: name, content: reaction, pluginCommand: "evaluate")) ?
                PluginResponse.ok(command: "evaluate") :
                PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"], cause: "Cannot dispatch evaluation result of evaluation key \(evaluationKey)")
        }
        
        Console.warning(NPRecipes.self, text: "Cannot evaluate recipe \(evaluationKey)")
        Console.warningLine("content type may be invalid or no content can be found for the given recipe")
        pluginHub.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(evaluationKey)\" cannot be evaluated", command: "evaluate", details: failedEvaluation))
        return PluginResponse.warning("Cannot evaluate recipe \(evaluationKey)", command: "evaluate")
    }
    private func evaluateOnlinePulse(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipes.self, command: "evaluate-online-pulse", requiredParameters: ["app-token", "bundle", "action", "plugin"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("evaluate-online-pulse", requiredParameters: ["app-token", "bundle", "action", "plugin"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        guard let bundle = arguments.string("bundle"), action = arguments.string("action"), plugin = arguments.string("plugin") else {
            Console.commandError(NPRecipes.self, command: "evaluate-online-pulse", requiredParameters: ["app-token", "bundle", "action", "plugin"])
            completionHandler?(response: PluginResponse.cannotRun("evaluate-online-pulse", requiredParameters: ["app-token", "bundle", "action", "plugin"]))
            return
        }
        
        let identifiers = cachedIdentifiers()
        let pulse = APPulse(pluginID: plugin, action: action, bundleID: bundle)
        APRecipes.evaluate(pulse: pulse, profileID: identifiers.profile, installationID: identifiers.installation) { (recipe, reactions, status) in
            guard let _ = recipe, _ = reactions where status == .OK else {
                Console.error(NPRecipes.self, text: "Cannot evaluate pulse")
                Console.errorLine("   recipe: \(recipe?.name ?? "-")")
                Console.errorLine("reactions:", symbol: .AlternateSpace)
                Console.errorLine("  content: \(reactions?.content?.id ?? "-")")
                Console.errorLine("     poll: \(reactions?.poll?.id ?? "-")")
                Console.errorLine("   coupon: \(reactions?.coupon?.id ?? "-")")
                
                completionHandler?(response: PluginResponse.error("No recipe or reaction", command: "evaluate-online-pulse"))
                return
            }
            
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["recipe": recipe!, "reactions": reactions!]), command: "evaluate-online-pulse"))
        }
    }
    private func evaluateOnlineID(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipes.self, command: "evaluate-online-id", requiredParameters: ["app-token", "recipe-id"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("evaluate-online-id", requiredParameters: ["app-token", "recipe-id"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        guard let id = arguments.string("recipe-id") else {
            Console.commandError(NPRecipes.self, command: "Cannot download recipe", requiredParameters: ["app-token", "recipe-id"])
            completionHandler?(response: PluginResponse.cannotRun("evaluate-online-id", requiredParameters: ["app-token", "recipe-id"]))
            return
        }
        
        let identifiers = cachedIdentifiers()
        APRecipes.evaluate(recipe: id, profileID: identifiers.profile, installationID: identifiers.installation) { (recipe, reactions, status) in
            guard let _ = recipe, _ = reactions where status == .OK else {
                Console.error(NPRecipes.self, text: "Cannot evaluate pulse")
                Console.errorLine("   recipe: \(recipe?.name ?? "-")")
                Console.errorLine("reactions:", symbol: .AlternateSpace)
                Console.errorLine("  content: \(reactions?.content?.id ?? "-")")
                Console.errorLine("     poll: \(reactions?.poll?.id ?? "-")")
                Console.errorLine("   coupon: \(reactions?.coupon?.id ?? "-")")
                
                completionHandler?(response: PluginResponse.error("No recipe or reaction", command: "evaluate-online-id"))
                return
            }
            
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["recipe": recipe!, "reactions": reactions!]), command: "evaluate-online-id"))
        }
    }
    private func evaluateByID(arguments: JSON, sender: String?) -> PluginResponse {
        guard let id = arguments.string("id"), pluginHub = hub else {
            Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"])
            return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"])
        }
        
        guard let recipe: APRecipe = pluginHub.cache.resource(id, inCollection: "Recipes", forPlugin: self) else {
            Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot find recipe \(id)")
            pluginHub.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(name, message: "Recipe \"\(id)\" cannot be evaluated", command: "evaluate-recipe-by-id", details: ["recipe": ["id": id, "online": true]]))
            
            return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
        }
        
        let failedEvaluation = [
            "pulse": [
                "plugin": recipe.pulse(.Plugin),
                "action": recipe.pulse(.Action),
                "bundle": recipe.pulse(.Bundle)
            ],
            "recipe": [
                "id": recipe.id,
                "online": recipe.online
            ]
        ]
        
        guard let command = evaluatorCommand(recipe) else {
            Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
            
            pluginHub.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(name, message: "Recipe \"\(id)\" cannot be evaluated", command: "evaluate-recipe-by-id", details: failedEvaluation))
            
            return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
        }
        
        guard let
            response = hub?.send(command.command, fromPluginNamed: name, toPluginNamed: command.evaluator, withArguments: command.args) where response.status == .OK else {
                Console.commandError(NPRecipes.self, command: "evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
                
                pluginHub.dispatch(event: NearSDKError.CannotEvaluateRecipe.pluginEvent(self.name, message: "Recipe \"\(recipe.id)\" cannot be evaluated", command: "evaluate-recipe-by-id", details: failedEvaluation))
                
                return PluginResponse.cannotRun("evaluate-recipe-by-id", requiredParameters: ["id"], cause: "Cannot evaluate recipe \(id) or its reaction")
        }
        
        let reaction = JSON(dictionary: ["reaction": [command.contentType: response.content.dictionary], "recipe": recipe.json.dictionary, "type": recipe.reaction(.Plugin)])
        return pluginHub.dispatch(event: PluginEvent(from: name, content: reaction, pluginCommand: "evaluate")) ?
            PluginResponse.ok(command: "evaluate") :
            PluginResponse.cannotRun("evaluate", requiredParameters: ["pulse-plugin", "pulse-bundle", "pulse-action"], cause: "Cannot send evaluation request to \(command.evaluator) for recipe \(recipe.id)")
    }
    
    // MARK: Download
    private func download(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipes.self, command: "download", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("download", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        guard let id = arguments.string("id"), profileID = cachedIdentifiers().profile else {
            Console.commandError(NPRecipes.self, command: "Cannot download recipe", requiredParameters: ["recipe-id"])
            
            if cachedIdentifiers().profile == nil {
                Console.errorLine("A profile identifier must be obtained and stored before downloading recipes")
            }
            
            completionHandler?(response: PluginResponse.cannotRun("download", requiredParameters: ["recipe-id"]))
            return
        }
        
        APRecipes.get(recipe: id, forProfile: profileID) { (recipe, reaction, status) in
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
            // Coupons are not stored
            if evaluatedReaction.coupon != nil {
                completionHandler?(response: PluginResponse.cannotRun("download",
                    requiredParameters: ["id"],
                    cause: "Recipe \(id) has been downloaded, but recipe's reaction could not be stored offline"))
                return
            }
            
            pluginHub.cache.store(evaluatedRecipe, inCollection: "Recipes", forPlugin: self)
            var reaction: JSON?
            if let content = evaluatedReaction.content, resource = content.resource {
                reaction = JSON(dictionary: ["resource": resource])
            }
            
            if let poll = evaluatedReaction.poll, resource = poll.resource {
                reaction = JSON(dictionary: ["resource": resource])
            }
            
            if let r = reaction {
                let response = pluginHub.send("store-online-resource", fromPluginNamed: self.name, toPluginNamed: evaluator.name, withArguments: r)
                
                completionHandler?(response:
                    response.status == .OK ?
                        PluginResponse.ok(JSON(dictionary: ["id": id]), command: "download") :
                        PluginResponse.cannotRun("download",
                            requiredParameters: ["id"],
                            cause: "Recipe \(id) has been downloaded, but recipe's reaction could not be stored offline")
                )
                
                return
            }
            
            completionHandler?(
                response: PluginResponse.cannotRun("download",
                    requiredParameters: ["id"],
                    cause: "Recipe \(id) has been downloaded, but recipe's reaction could not be stored offline")
                )
        }
    }
    private func downloadProcessedRecipes(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let appToken = arguments.string("app-token") else {
            Console.commandError(NPRecipes.self, command: "download-processed-recipes", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "options"])
            completionHandler?(response: PluginResponse.cannotRun("download-processed-recipes", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "options"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        APRecipes.processed(options: arguments.dictionary("options", emptyIfNil: true)!) { (recipes, recipeMaps, status) in
            if status != .OK {
                Console.error(NPRecipes.self, text: "Cannot download recipes")
                completionHandler?(response: PluginResponse.cannotRun("download-processed-recipes", requiredParameters: ["app-token"], optionalParameters: ["timeout-interval", "options"], cause: "HTTPStatusCode \(status.rawValue)"))
                return
            }
            
            Console.info(NPRecipes.self, text: "Removing previously cached recipes...")
            self.clear(JSON(), sender: self.name)
            self.storeRecipes(recipes, recipeMaps: recipeMaps, command: "download-processed-recipes", dispatchEvent: false)
            
            func append(id: String, inout toDictionary dictionary: [String: [String]], forKey key: String) {
                if var array = dictionary[key] where !array.contains(id) {
                    array.append(id)
                    dictionary[key] = array
                }
                else {
                    dictionary[key] = [id]
                }
            }
            
            var reactions = ["contents": [String](), "polls": [String](), "jsons": [String]()]
            var recipeIDs = Set<String>()
            for recipe in recipes {
                recipeIDs.insert(recipe.id)
                
                guard let evaluator = self.evaluatorName(recipe) else {
                    continue
                }
                
                append(recipe.reaction(.Bundle), toDictionary: &reactions, forKey: "\(evaluator.contentType)s")
            }
            
            completionHandler?(response: PluginResponse.ok(JSON(dictionary: ["recipes": Array(recipeIDs), "reactions": reactions]), command: "download-processed-recipes"))
        }
    }
    
    // MARK: Support
    private func evaluatorName(recipe: APRecipe) -> (name: String, contentType: String)? {
        switch recipe.reaction(.Plugin) {
        case "poll-notification":
            return (CorePlugin.Polls.name, "poll")
        case "content-notification":
            return (CorePlugin.Contents.name, "content")
        case "coupon-blaster":
            return (CorePlugin.CouponBlaster.name, "coupon")
        case "json-sender":
            return (CorePlugin.CustomJSONObjects.name, "json")
        default:
            return nil
        }
    }
    private func evaluatorCommand(recipe: APRecipe) -> (command: String, args: JSON, evaluator: String, contentType: String)? {
        guard let evaluator = evaluatorName(recipe) else {
            return nil
        }
        
        return ("read", JSON(dictionary: ["content-id": recipe.reaction(.Bundle)]), evaluator.name, evaluator.contentType)
    }
    private func storeRecipes(recipes: [APRecipe], recipeMaps: [APRecipeMap], command: String, dispatchEvent: Bool) {
        Console.info(NPRecipes.self, text: "Saving recipes...")
        for recipe in recipes {
            self.hub?.cache.store(recipe, inCollection: "Recipes", forPlugin: self)
            
            Console.infoLine(recipe.id, symbol: .Add)
            Console.infoLine("             name: \(recipe.name)")
            Console.infoLine("     pulse plugin: \(recipe.pulse(.Plugin))")
            Console.infoLine("     pulse bundle: \(recipe.pulse(.Bundle))")
            Console.infoLine("     pulse action: \(recipe.pulse(.Action))")
            
            if let string = recipe.operation(.Plugin) {
                Console.infoLine(" operation plugin: \(string)")
            }
            if let string = recipe.operation(.Bundle) {
                Console.infoLine(" operation bundle: \(string)")
            }
            if let string = recipe.operation(.Action) {
                Console.infoLine(" operation action: \(string)")
            }
            
            Console.infoLine("  reaction plugin: \(recipe.reaction(.Plugin))")
            Console.infoLine("  reaction bundle: \(recipe.reaction(.Bundle))")
            Console.infoLine("  reaction action: \(recipe.reaction(.Action))")
            
            if recipe.notificationTitle != nil || recipe.notificationText != nil {
                Console.infoLine("     notification:")
                
                if let string = recipe.notificationTitle {
                    Console.infoLine("            title: \(string)")
                }
                if let string = recipe.notificationText {
                    Console.infoLine("             text: \(string)")
                }
            }
        }
        Console.infoLine("recipes saved: \(recipes.count)")
        
        Console.info(NPRecipes.self, text: "Saving events-to-recipes mappings...")
        for map in recipeMaps {
            Console.infoLine("  event: \(map.id)", symbol: .To)
            Console.infoLine("maps to: \(map.recipes.joinWithSeparator(", "))")
            
            self.hub?.cache.store(map, inCollection: "RecipesMaps", forPlugin: self)
        }
        Console.infoLine("mappings saved: \(recipes.count)")
        
        if dispatchEvent {
            self.hub?.dispatch(event: PluginEvent(from: self.name, content: JSON(dictionary: [: ]), pluginCommand: command))
        }
    }
    private func cachedIdentifiers() -> (profile: String?, installation: String?) {
        guard let pluginHub = hub else {
            return (profile: nil, installation: nil)
        }
        
        var profile: String?
        var installation: String?
        
        let pidResponse = pluginHub.send("read", fromPluginNamed: name, toPluginNamed: CorePlugin.Segmentation.name, withArguments: JSON())
        if let id = pidResponse.content.string("profile-id") where pidResponse.status == .OK {
            profile = id
        }
        
        let nidResponse = pluginHub.send("read", fromPluginNamed: name, toPluginNamed: CorePlugin.Device.name, withArguments: JSON())
        if let id = pidResponse.content.string("installation-id") where nidResponse.status == .OK {
            installation = id
        }
        
        return (profile: profile, installation: installation)
    }
}
