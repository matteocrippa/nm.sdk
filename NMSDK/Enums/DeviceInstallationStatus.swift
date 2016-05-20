//
//  DeviceInstallationStatus.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 26/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/**
 Describes the status of a device installation refresh operation.
 */
@objc
public enum DeviceInstallationStatus: Int {
    /**
     A new installation identifier has been received.
     */
    case Received = 10
    
    /**
     An existing installation identifier has been updated.
     */
    case Updated = 20
    
    /**
     The installation identifier cannot be received or updated.
     */
    case NotRefreshed = 0
    
    /**An unsupported status value.
     */
    case Unknown = -1
    
    // MARK: Initializers
    /**
     Converts `rawValue` in `Self`.
     
     - parameter rawValue: must be either `10`, `20` or `0`
     - returns: .Unknown if `rawValue` is not `10`, `20` or `0`
     */
    public init(rawValue: Int) {
        switch rawValue {
        case 10:
            self = .Received
        case 20:
            self = .Updated
        case 0:
            self = .NotRefreshed
        default:
            self = .Unknown
        }
    }
}
