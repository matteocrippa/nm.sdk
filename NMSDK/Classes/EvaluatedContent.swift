//
//  EvaluatedContent.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON

/// A content evaluated by nearit.com SDK
@objc
public class EvaluatedContent: PluginResource {
    /// The title of the content
    public var title: String {
        return json.string("title")!
    }
    /// The short description of the content
    public var shortDescription: String {
        return json.string("short_description")!
    }
    /// The long description of the contents
    var longDescription: String {
        return json.string("long_description")!
    }
    /// The identifiers of photos associated to the content
    var photoIdentifiers: [String] { return json.stringArray("photo_ids")! }
    
    required public init?(dictionary object: [String : AnyObject]) {
        let json = JSON(dictionary: object)
        guard let id = json.string("id") else {
            return nil
        }
        
        super.init(dictionary: ["id": id,
            "title": json.string("title", fallback: "")!,
            "short_description": json.string("short_description", fallback: "")!,
            "long_description": json.string("long_description", fallback: "")!,
            "photo_ids": json.stringArray("photo_ids", emptyIfNil: true)!]
        )
    }
}
