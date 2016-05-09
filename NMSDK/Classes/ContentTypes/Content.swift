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
    
    /// The recipe which evaluated the content.
    public private (set) var recipe: Recipe?
    
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
    ///   - recipe: the source `APRecipe` which evaluated the content
    public init(content: APRecipeContent, recipe evaluatedRecipe: APRecipe?) {
        super.init()
        
        id = content.id
        title = content.title
        text = content.text
        imageIdentifiers = content.imageIdentifiers
        videoURL = content.videoURL
        creationDate = content.creationDate
        lastUpdate = content.lastUpdate
        
        if let r = evaluatedRecipe {
            recipe = Recipe(recipe: r)
        }
    }
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public override var description: String {
        return Console.describe(Notification.self, properties: ("id", id), ("title", title), ("text", text), ("imageIdentifiers", imageIdentifiers.joinWithSeparator(", ")), ("video", videoURL), ("recipe", recipe?.evaluation))
    }
    
    // MARK: Methods
    /// Returns an instance of a UILocalNotification.
    ///
    /// The alert body of the local notification will be equal to `text`, while its title will be equal to `title`.
    ///
    /// - parameters:
    ///   - fireDate: defines the fire date of the local notification
    public func makeLocalNotification(fireDate fireDate: NSDate) -> UILocalNotification {
        let notification = UILocalNotification()
        
        notification.alertTitle = title
        notification.alertBody = text
        notification.fireDate = fireDate
        
        return notification
    }
}
