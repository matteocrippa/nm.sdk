//
//  Notification.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// A notification reaction.
@objc
public class Notification: NSObject {
    // MARK: Properties
    /// The identifier of the notification.
    public private (set) var id = ""
    
    /// The recipe which evaluated the notification.
    public private (set) var recipe: Recipe?
    
    /// The text of the notification.
    public private (set) var text = ""
    
    // MARK: Initializers
    /// Initializes a new `Notification`.
    ///
    /// - parameters:
    ///   - notification: the source `APRecipeNotification` instance
    ///   - recipe: the source `APRecipe` which evaluated the notification
    public init(notification: APRecipeNotification, recipe evaluatedRecipe: APRecipe?) {
        super.init()
        
        id = notification.id
        text = notification.text
        
        if let r = evaluatedRecipe {
            recipe = Recipe(recipe: r)
        }
    }
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public override var description: String {
        return Console.describe(Notification.self, properties: ("id", id), ("text", text), ("recipe", recipe?.evaluation))
    }
}
