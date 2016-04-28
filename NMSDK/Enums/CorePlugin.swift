//
//  CorePlugin.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/// Core plugins used by `NearSDK`.
@objc
public enum CorePlugin: Int, CustomStringConvertible {
    /// `BeaconForest` manages the configuration of iBeacon™s registered on nearit.com.
    ///
    /// This plugin synchronizes itself with nearit.com when `NearSDK.start()` or `NearSDK.start(token:)` is called
    case BeaconForest
    
    /// `ImageCache` manages images linked to nearit.com content reactions.
    ///
    /// This plugin can return, cache and download images for a given array of image identifiers, which must be defined in a "source" content reaction.
    /// - seealso: `Content`
    case ImageCache
    
    /// `Recipes` manages the evaluation of iBeacon™s into reactions configured on nearit.com.
    ///
    /// The evaluation of a recipe is executed offline and, if successfull, requests a reaction to `Polls`, `Contents` or `Notification`.
    /// This plugin synchronizes itself with nearit.com when `NearSDK.start()` or `NearSDK.start(token:)` is called
    case Recipes
    
    /// `Polls` returns a poll reaction in response to a successful evaluation of a recipe.
    ///
    /// `Polls` can be used to send poll answers to nearit.com by calling `NearSDK.sendPollAnswer(_:forPoll:response:)`.
    /// This plugin synchronizes itself with nearit.com when `NearSDK.start()` or `NearSDK.start(token:)` is called
    case Polls
    
    /// `Contents` returns a content reaction in response to a successful evaluation of a recipe.
    ///
    /// This plugin synchronizes itself with nearit.com when `NearSDK.start()` or `NearSDK.start(token:)` is called
    case Contents
    
    /// `Notifications` returns a notification reaction in response to a successful evaluation of a recipe.
    ///
    /// This plugin synchronizes itself with nearit.com when `NearSDK.start()` or `NearSDK.start(token:)` is called
    case Notifications
    
    /// `Device` synchronizes app's installation identifier with nearit.com.
    ///
    /// `Device` will request a new installation identifier if it cannot be found locally.
    /// This plugin should be used by calling `NearSDK.refreshInstallationID(APNSToken:didRefresh:)`.
    case Device
    
    // MARK: Properties
    /// The name used to plug `Self` into `NearSDK`'s plugin hub.
    var name: String {
        switch self {
        case .BeaconForest:
            return "com.nearit.sdk.plugin.np-beacon-forest"
        case .ImageCache:
            return "com.nearit.sdk.plugin.np-image-cache"
        case .Recipes:
            return "com.nearit.sdk.plugin.np-recipes"
        case .Polls:
            return "com.nearit.sdk.plugin.np-polls"
        case .Contents:
            return "com.nearit.sdk.plugin.np-contents"
        case .Notifications:
            return "com.nearit.sdk.plugin.np-notifications"
        case .Device:
            return "com.nearit.sdk.plugin.np-device"
        }
    }
    /// Human-readable description of `Self`.
    public var description: String {
        switch self {
        case .BeaconForest:
            return "Beacon forest"
        case .ImageCache:
            return "Image Cache"
        case .Recipes:
            return "Recipes"
        case .Polls:
            return "Polls"
        case .Contents:
            return "Contents"
        case .Notifications:
            return "Notifications"
        case .Device:
            return "Device"
        }
    }
    
    // MARK: Initializers
    /// Converts `name` in `Self` if it does correspont to a valid `Self` value.
    ///
    /// Accepted names:
    /// - com.nearit.sdk.plugin.np-beacon-forest = *BeaconForest*
    /// - com.nearit.sdk.plugin.np-image-cache   = *ImageCache*
    /// - com.nearit.sdk.plugin.np-recipes       = *Recipes*
    /// - com.nearit.sdk.plugin.np-polls         = *Polls*
    /// - com.nearit.sdk.plugin.np-contents      = *Contents*
    /// - com.nearit.sdk.plugin.np-notifications = *Notifications*
    /// - com.nearit.sdk.plugin.np-device        = *Device*
    ///
    /// - parameters:
    ///   - name: must be a concatenation of "com.nearit.sdk.plugin.np-" and with "beacon-forest", "image-cache", "recipes", "polls", "contents", "notifications" or "device"
    ///   - returns: `nil` if name is not a valid core plugin name
    public init?(name: String) {
        switch name {
        case "com.nearit.sdk.plugin.np-beacon-forest":
            self = .BeaconForest
        case "com.nearit.sdk.plugin.np-image-cache":
            self = .ImageCache
        case "com.nearit.sdk.plugin.np-recipes":
            self = .Recipes
        case "com.nearit.sdk.plugin.np-polls":
            self = .Polls
        case "com.nearit.sdk.plugin.np-contents":
            self = .Contents
        case "com.nearit.sdk.plugin.np-notifications":
            self = .Notifications
        case "com.nearit.sdk.plugin.np-device":
            self = .Device
        default:
            return nil
        }
    }
}
