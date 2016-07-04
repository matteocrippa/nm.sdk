//
//  EvaluationPulse.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 04/07/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/**
 Represents the description of the pulse which describes the evaluation of a recipe.
 */
@objc
public class EvaluationPulse: NSObject {
    // MARK: Properties
    /**
     The identifier of the pulse's plugin.
     */
    public private (set) var plugin = ""
    /**
     The identifier of the pulse's action.
     */
    public private (set) var action = ""
    /**
     The identifier of the pulse's bundle.
     */
    public private (set) var bundle = ""
    
    // MARK: Initializers
    /**
     Initializes a new `EvaluationPulse`.
     
     - parameter plugin: the identifier of the pulse's plugin
     - parameter action: the identifier of the pulse's action
     - parameter bundle: the identifier of the pulse's bundle
     */
    public init(plugin p: String, action a: String, bundle b: String) {
        plugin = p
        action = a
        bundle = b
    }
}
