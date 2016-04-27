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
    
    /// The text of the notification.
    public private (set) var text = ""
    
    // MARK: Initializers
    /// Initializes a new `Notification`.
    ///
    /// - parameters:
    ///   - notification: the source `APRecipeNotification` instance
    public init(notification: APRecipeNotification) {
        super.init()
        
        id = notification.id
        text = notification.text
    }
    
    // MARK: Properties
    /// Human-readable description of Self.
    public override var description: String {
        return Console.describe(Notification.self, properties: [("id", id), ("text", text)])
    }
}
