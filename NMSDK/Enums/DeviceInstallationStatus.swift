//
//  DeviceInstallationStatus.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 26/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/// Describes the status of a device installation refresh operation
@objc
public enum DeviceInstallationStatus: Int {
    /// A new installation identifier has been received
    case Received
    
    /// An existing installation identifier has been updated
    case Updated
    
    /// The installation identifier cannot be received or updated
    case NotRefreshed
}
