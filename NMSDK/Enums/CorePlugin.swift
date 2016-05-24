//
//  CorePlugin.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

/**
 Core plugins used by `NearSDK`.
 */
@objc
public enum CorePlugin: Int, CustomStringConvertible {
    /**
     `BeaconForest` manages the configuration of iBeacon™s registered on nearit.com.
     
     This plugin synchronizes itself with nearit.com when `NearSDK.start(appToken:)` is called.
     */
    case BeaconForest
    
    /**
     `ImageCache` manages images linked to nearit.com content reactions.
     
     This plugin can return, cache and download images for a given array of image identifiers, which must be defined in a "source" content reaction.
     
     - seealso:
       - `NearSDK.imagesWithIdentifiers(_:didFetchImages:)`
       - `NearSDK.clearImageCache()`
       - `NearSDK.downloadProcessedRecipes(_:)`
     */
    case ImageCache
    
    /**
     `Recipes` manages the evaluation of iBeacon™s into reactions configured on nearit.com.
     
     The evaluation of a recipe occurs offline and, if successfull, requests a reaction to `Polls` or `Contents`.
     This plugin synchronizes itself with nearit.com when `NearSDK.start(appToken:)` is called.
     
     - seealso:
       - `Content`
       - `Poll`
     */
    case Recipes
    
    /**
     `Polls` returns a poll reaction in response to a successful evaluation of a recipe.
     
     `Polls` can be used to send poll answers to nearit.com by calling `NearSDK.sendPollAnswer(_:forPoll:response:)`.
     
     This plugin synchronizes itself with nearit.com when `NearSDK.start(appToken:)` is called.
     
     - seealso: `Poll`
     */
    case Polls
    
    /**
     `Contents` returns a content reaction in response to a successful evaluation of a recipe.
     
     This plugin synchronizes itself with nearit.com when `NearSDK.start(appToken:)` is called.
     
     - seealso: `Content`
     */
    case Contents
    
    /**
     `Device` synchronizes app's installation identifier with nearit.com.
     
     `Device` will request a new installation identifier if it cannot be found locally.
     
     This plugin should be used by calling `NearSDK.refreshInstallationID(APNSToken:didRefresh:)`.
     
     - seealso:
       - `DeviceInstallation`
       - `NearSDK.refreshInstallationID(APNSToken:didRefresh:)`
     */
    case Device
    
    /**
     `Segmentation` manages all segmentation (user-profile) related operations which can be done with nearit.com.
     
     This plugin can assign or read the cached profile identifier or request a new one and can set data points for an existing profile identifier.
     
     - seealso:
       - `NearSDK.requestNewProfileID(_:)`
       - `NearSDK.linkProfileToInstallation(_:)`
       - `NearSDK.addProfileDataPoints(_:completionHandler:)`
     */
    case Segmentation
    
    // MARK: Properties
    /**
     The name used to plug `Self` into `NearSDK`'s plugin hub.
     */
    public var name: String {
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
        case .Device:
            return "com.nearit.sdk.plugin.np-device"
        case .Segmentation:
            return "com.nearit.sdk.plugin.np-segmentation"
        }
    }
    /**
     Human-readable description of `Self`.
     */
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
        case .Device:
            return "Device"
        case .Segmentation:
            return "Segmentation"
        }
    }
    
    // MARK: Initializers
    /**
     Converts `name` in `Self` if it does correspont to a valid `Self` value.
     
     Accepted names:
     
     - `com.nearit.sdk.plugin.np-beacon-forest` (*BeaconForest*)
     - `com.nearit.sdk.plugin.np-image-cache`   (*ImageCache*)
     - `com.nearit.sdk.plugin.np-recipes`       (*Recipes*)
     - `com.nearit.sdk.plugin.np-polls`         (*Polls*)
     - `com.nearit.sdk.plugin.np-contents`      (*Contents*)
     - `com.nearit.sdk.plugin.np-device`        (*Device*)
     - `com.nearit.sdk.plugin.np-segmentation`  (*Segmentation*)
     
     - parameter name: must be a concatenation of "com.nearit.sdk.plugin.np-" and with "beacon-forest", "image-cache", "recipes", "polls", "contents", "device" or "segmentation"
     - returns: `nil` if `name` is not a valid core plugin name
     */
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
        case "com.nearit.sdk.plugin.np-device":
            self = .Device
        case "com.nearit.sdk.plugin.np-segmentation":
            self = .Segmentation
        default:
            return nil
        }
    }
}
