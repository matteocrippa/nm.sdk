//
//  Recipe.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 27/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// A recipe which can be evaluated into "notification", "content" or "poll" reactions.
@objc
public class Recipe: NSObject {
    // MARK: Properties
    /// The identifier of the recipe.
    public private (set) var id = ""
    
    /// The name of the trigger which enables the evaluation of the recipe.
    ///
    /// This value is the name of a plugin used by nearit.com
    public private (set) var inCase = ""
    
    /// The trigger which enables the evaluation of the recipe.
    ///
    /// This value is usually an identifier.
    public private (set) var inTarget = ""
    
    /// The trigger itself - it may represent an event by name.
    public private (set) var trigger = ""
    
    
    /// The name of the action triggered by the evaluation of the recipe.
    ///
    /// This value is the name of a plugin used by nearit.com.
    public private (set) var outCase = ""
    
    /// The action triggered by the evaluation of the recipe.
    ///
    /// This value is usually an identifier.
    public private (set) var outTarget = ""
    
    // MARK: Initializers
    /// Initializes a new `Recipe`.
    ///
    /// - parameters:
    ///   - recipe: the source `APRecipe` instance
    public init(recipe: APRecipe) {
        super.init()
        
        id = recipe.id
        inCase = recipe.inCase
        inTarget = recipe.inTarget
        trigger = recipe.trigger
        outCase = recipe.outCase
        outTarget = recipe.outTarget
    }
    
    // MARK: Properties
    /// Human-readable description of Self.
    public override var description: String {
        return Console.describe(Recipe.self, properties: [("id", id), ("inCase", inCase), ("inTarget", inTarget), ("trigger", trigger), ("outCase", outCase), ("outTarget", outTarget)])
    }
}

