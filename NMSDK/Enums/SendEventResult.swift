//
//  SendEventResult.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 27/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/// The result of a "send event" action executed by calling `NearSDK.sendEvent(_:response:)`
@objc
public enum SendEventResult: Int, CustomStringConvertible {
    /// Returned whenever an event is successfully sent to nearit.com
    case Success = 1
    
    /// Returned whenever an event is not sent to nearit.com
    case Failure = 0
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public var description: String {
        switch self {
        case Success:
            return "Success"
        case .Failure:
            return "Failure"
        }
    }
}
