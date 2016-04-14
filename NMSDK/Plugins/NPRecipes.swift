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
        default:
            return PluginResponse.error("\"do\" parameter must be \"sync\" or \"evaluate\"")
        }
        
        return PluginResponse.ok()
    }
    
    // MARK: Sync
    private func sync(appToken: String, timeoutInterval: NSTimeInterval?) {
        API.authorizationToken = appToken
        API.timeoutInterval = timeoutInterval ?? 10.0
        
        APRecipes.get { (resources, status) in
            self.parseResources(resources, status: status)
        }
    }
    private func parseResources(resources: APIResourceCollection?, status: HTTPStatusCode) {
        guard let recipes = resources where status == .OK else {
            return
        }
        
        hub?.cache.removeAllResourcesWithPlugin(self)
        for recipe in recipes.resources {
            guard let
                inType = recipe.attributes.string("pulse_ingredient_id"),
                inIdentifier = recipe.attributes.string("pulse_slice_id"),
                outType = recipe.attributes.string("reaction_ingredient_id"),
                outIdentifier = recipe.attributes.string("reaction_slice_id") else {
                    continue
            }
            
            if let resource = APRecipe(dictionary: ["id": "\(inType).\(inIdentifier)", "out-type": outType, "out-identifier": outIdentifier]) {
                hub?.cache.store(resource, inCollection: "Recipes", forPlugin: self)
            }
        }
        
        hub?.dispatch(event: PluginEvent(from: name, content: JSON(dictionary: ["operation": "sync"])))
    }
}

