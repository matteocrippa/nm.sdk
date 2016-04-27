//
//  EventSerializable.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON

/// This protocol defines "action" objects which can be sent to nearit.com APIs through `NearSDK` as a response to user actions or other events.
@objc
public protocol EventSerializable {
    // MARK: Properties
    /// The name of the recipient plugin, i.e. the plugin which should manage the event.
    var pluginName: String { get }
    
    /// The dictionary which holds event's data.
    var body: JSON { get }
    
    // MARK: Initializers
    /// The failable initializer of any EventSerializable object.
    init?(body: JSON)
}
