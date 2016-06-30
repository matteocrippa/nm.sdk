//
//  CustomJSONObject.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 30/06/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMNet

/**
 A custom JSON Object reaction.
 */
@objc
public class CustomJSONObject: NSObject {
    // MARK: Properties
    /**
     The identifier of the content.
     */
    public private (set) var id = ""
    
    /**
     The json object itself.
     */
    public private (set) var content = JSON()
    
    /**
     The creation date of the content.
     */
    public private (set) var creationDate: NSDate?
    
    /**
     The last update date of the content.
     */
    public private (set) var lastUpdate: NSDate?
    
    // MARK: Initializers
    /**
     Initializes a new `CustomJSONObject`.
     
     - parameter jsonObject: the source `APJSONObject` instance
     */
    public init(jsonObject: APJSONObject) {
        super.init()
        
        id = jsonObject.id
        content = jsonObject.content
        
        creationDate = jsonObject.creationDate
        lastUpdate = jsonObject.lastUpdate
    }
    
    // MARK: Properties
    /**
     Human-readable description of `Self`.
     */
    public override var description: String {
        return Console.describe(CustomJSONObject.self, properties: ("id", id), ("content", "\(content)"))
    }
}

