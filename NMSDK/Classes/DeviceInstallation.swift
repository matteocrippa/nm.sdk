//
//  DeviceInstallation.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 05/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// An object which represents a nearit.com device installation
@objc
public class DeviceInstallation: NSObject {
    /// The installation identifier
    public private (set) var id = ""
    
    /// The device operating system
    public private (set) var operatingSystem = ""
    
    /// The device operating system version
    public private (set) var operatingSystemVersion = ""
    
    /// The NearSDK version
    public var sdkVersion = ""
    
    /// The APNS token associated to the device
    public private (set) var apnsToken: String?
    
    // MARK: Initializers
    /// Initializes a new `DeviceInstallation`.
    ///
    /// - parameters:
    ///   - installation: the source `APDeviceInstallation` instance
    public init(installation: APDeviceInstallation) {
        super.init()
        
        id = installation.id
        operatingSystem = installation.operatingSystem
        operatingSystemVersion = installation.operatingSystemVersion
        sdkVersion = installation.NearSDKVersion
        apnsToken = installation.APNSToken
    }
}
