//
//  Notification.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// A notification reaction
@objc
public class Notification: NSObject {
    /// The identifier of the notification
    public private (set) var id = ""
    
    /// The text of the notification
    public private (set) var text = ""
    
    init(notification: APRecipeNotification) {
        super.init()
        
        id = notification.id
        text = notification.text
    }
}
