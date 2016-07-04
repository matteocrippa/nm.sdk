//
//  EvaluationRecipe.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 04/07/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/**
 Represents the description of the recipe which is part of an evaluation.
 */
@objc
public class EvaluationRecipe: NSObject {
    // MARK: Properties
    /**
     The identifier of the recipe.
     */
    public private (set) var id = ""
    /**
     A flag which indicates if the recipe should be evaluated online.
     */
    public private (set) var online = false
    
    // MARK: Initializers
    /**
     Initializes a new `EvaluationRecipe`.
     
     - parameter plugin: the identifier of the recipe
     - parameter action: the flag which indicates if the recipe should be evaluated online (defaults to `false`)
     */
    public init(id i: String, online flag: Bool = false) {
        id = i
        online = flag
    }
}
