//
//  Poll.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMCache
import NMNet

/// A content reaction.
@objc
public class Poll: NSObject {
    // MARK: Properties
    /// The identifier of the poll.
    public private (set) var id = ""
    
    /// The recipe which evaluated the poll.
    public private (set) var recipe: Recipe?
    
    /// The question of the poll.
    public var question = ""
    
    /// The text of the poll: this may be a short title.
    public var text = ""
    
    /// The text of the first answer.
    public var answer1 = ""
    
    /// The text of the second answer.
    public var answer2 = ""
    
    // MARK: Initializers
    /// Initializes a new `Poll`.
    ///
    /// - parameters:
    ///   - poll: the source `APRecipePoll` instance
    ///   - recipe: the source `APRecipe` which evaluated the poll
    public init(poll: APRecipePoll, recipe evaluatedRecipe: APRecipe?) {
        super.init()
        
        id = poll.id
        question = poll.question
        text = poll.text
        answer1 = poll.answer1
        answer2 = poll.answer2
        
        if let r = evaluatedRecipe {
            recipe = Recipe(recipe: r)
        }
    }
    
    // MARK: Properties
    /// Human-readable description of Self.
    public override var description: String {
        return Console.describe(Poll.self, properties: ("id", id), ("text", text), ("question", question), ("answer1", answer1), ("answer2", answer2), ("recipe", recipe?.evaluation))
    }
}
