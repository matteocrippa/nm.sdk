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
    }
}
