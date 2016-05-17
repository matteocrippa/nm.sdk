//
//  PushNotificationAction.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 10/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/// Actions related to push notifications.
///
/// Push notifications' actions should be used when it is required to touch them on nearit.com.
/// Touching a push notification means marking the notification as "received" or "opened"
@objc
public enum PushNotificationAction: Int, CustomStringConvertible {
    /// A push notification has been received.
    case Received
    
    /// A push notification has been opened.
    case Opened
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public var description: String {
        switch self {
        case .Received:
            return "Received"
        case .Opened:
            return "Opened"
        }
    }
}
