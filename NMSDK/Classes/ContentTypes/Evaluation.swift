//
//  Evaluation.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 04/07/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/**
 Represents the description of an evaluation.
 */
@objc
public class Evaluation: NSObject {
    // MARK: Properties
    /**
     The evaluation's pulse.
     */
    public private (set) var pulse: EvaluationPulse?
    /**
     The description of the evaluation's recipe.
     */
    public private (set) var recipe: EvaluationRecipe?
    /**
     Human-readable description of `Self`.
     */
    public override var description: String {
        var components = ["Evaluation"]
        
        if let p = pulse {
            components.append(pulse == nil  ? "  pulse: ?" : "  pulse:")
            components.append("   - plugin: \(p.plugin)")
            components.append("   - action: \(p.action)")
            components.append("   - bundle: \(p.bundle)")
        }
        
        if let r = recipe {
            components.append(recipe == nil ? " recipe: ?" : " recipe:")
            components.append("  -     id: \(r.id)")
            components.append("  - online: \(r.online ? "yes" : "no")")
        }
        
        return components.joinWithSeparator("\n")
    }
    
    // MARK: Initializers
    /**
     Initializes a new `Evaluation` or returns `nil` if both `pulse` and `recipe` are `nil`.
     
     - parameter pulse: the pulse which produced the evaluation
     - parameter recipe: the recipe which produced the evaluation
     */
    public init?(pulse p: EvaluationPulse?, recipe r: EvaluationRecipe?) {
        if p == nil && r == nil {
            return nil
        }
        
        pulse = p
        recipe = r
    }
}
