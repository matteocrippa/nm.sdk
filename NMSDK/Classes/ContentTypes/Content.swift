//
//  Content.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// A content reaction.
@objc
public class Content: NSObject {
    // MARK: Properties
    /// The identifier of the content.
    public private (set) var id = ""
    
    /// The title of the content.
    public private (set) var title = ""
    
    /// The text of the content.
    public private (set) var text = ""
    
    /// The identifiers of image contents associated to the content.
    public var imageIdentifiers = [String]()
    
    /// The URL of the video associated to the content.
    public var videoURL: NSURL?
    
    /// The creation date of the content
    public private (set) var creationDate: NSDate?
    
    /// The last update date of the content
    public private (set) var lastUpdate: NSDate?
    
    // MARK: Initializers
    /// Initializes a new `Content`.
    ///
    /// - parameters:
    ///   - content: the source `APRecipeContent` instance
    public init(content: APRecipeContent) {
        super.init()
        
        id = content.id
        title = content.title
        text = content.text
        imageIdentifiers = content.imageIdentifiers
        videoURL = content.videoURL
        
        creationDate = content.creationDate
        lastUpdate = content.lastUpdate
    }
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public override var description: String {
        return Console.describe(Content.self, properties: ("id", id), ("title", title), ("text", text), ("imageIdentifiers", imageIdentifiers.joinWithSeparator(", ")), ("video", videoURL))
    }
}
