//
//  NearSDKError.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON

/// Errors of the SDK.
@objc
public enum NearSDKError: Int, CustomStringConvertible {
    /// Thrown when `NearSDK.tokenInAppConfiguration` is `true` and app's `Info.plist` file does not include key `NearSDKToken`, which must be a valid JWT token issued for an app registered on nearit.com.
    case TokenNotFoundInAppConfiguration = 1
    
    /// Thrown when `NearSDK` is started, but the configuration of `BeaconForest` plugin cannot be downloaded.
    ///
    /// If this error occurs, `NearSDK` will never be able to evaluate any type of content when an iBeacon™ is detected, be it a content, a notification or a poll.
    case CannotDownloadRegionMonitoringConfiguration = 1000
    
    /// Thrown when `NearSDK` is started, but `CLLocationManager.authorizationStatus()` is not `CLAuthorizationStatus.AuthorizedAlways` or `CLAuthorizationStatus.AuthorizedWhenInUse`.
    ///
    /// Appropriate authorization levels should be obtained before starting `NearSDK`.
    /// 
    /// If this error occurs, `NearSDK` will never be able to evaluate any type of content when an iBeacon™ is detected, be it a content, a notification or a poll.
    case RegionMonitoringIsNotAuthorized = 1001
    
    /// Thrown when `NearSDK` is started, the user authorized the app to monitor region changes in background, but no regions can be monitored because the configuration of `BeaconForest` plugin is empty.
    /// 
    /// If this error occurs, `NearSDK` will never be able to evaluate any type of content when an iBeacon™ is detected, be it a content, a notification or a poll.
    case NoRegionsToMonitor = 1002
    
    /// Thrown when `NearSDK` is started, but recipes cannot be downloaded.
    /// 
    /// While `NearSDK` may be able to detect iBeacon™s, it will not be able to evaluate any content, notification or poll reaction.
    case CannotDownloadRecipes = 2000
    
    /// Thrown when the `NarSDK` cannot evaluate correctly an event.
    case CannotEvaluateRecipe = 3000
    
    /// Thrown when the `NearSDK` is started, but notification reactions cannot be downloaded.
    ///
    /// While `NearSDK` may be able to detect iBeacon™s, it will not be able to evaluate notification reactions.
    /// 
    /// `NearSDK` will be able to evaluate contents and polls when an iBeacon™ is detected.
    case CannotDownloadNotificationReactions = 4000
    
    /// Thrown when `NearSDK` is started, but content reactions cannot be downloaded.
    ///
    /// While `NearSDK` may be able to detect iBeacon™s, it will not be able to evaluate content reactions.
    ///
    /// `NearSDK` will be able to evaluate notifications and polls when an iBeacon™ is detected.
    case CannotDownloadContentReactions = 5000
    
    /// Thrown when `NearSDK` is started, but poll reactions cannot be downloaded.
    ///
    /// While `NearSDK` may be able to detect iBeacon™s, it will not be able to evaluate poll reactions.
    /// 
    /// `NearSDK` will be able to evaluate contents and notifications when an iBeacon™ is detected.
    case CannotDownloadPollReactions = 6000
    
    /// Thrown when `NearSDK` cannot request an installation identifier.
    case CannotReceiveInstallationID = 7000
    
    /// Thrown when `NearSDK` cannot update an existing installation identifier.
    case CannotUpdateInstallationID = 7001
    
    // MARK: Properties
    /// Human-readable description of `Self`.
    public var description: String {
        switch self {
        case TokenNotFoundInAppConfiguration:
            return "Token not found in app configuration"
        case .CannotDownloadRegionMonitoringConfiguration:
            return "Cannot download region monitoring configuration"
        case .RegionMonitoringIsNotAuthorized:
            return "Region monitoring is not authorized"
        case .NoRegionsToMonitor:
            return "No regions to monitor"
        case .CannotDownloadRecipes:
            return "Cannot download recipes"
        case .CannotEvaluateRecipe:
            return "Cannot evaluate recipe"
        case .CannotDownloadNotificationReactions:
            return "Cannot download notification reactions"
        case .CannotDownloadContentReactions:
            return "Cannot download content reactions"
        case .CannotDownloadPollReactions:
            return "Cannot download poll reactions"
        case .CannotReceiveInstallationID:
            return "Cannot receive installation identifier"
        case .CannotUpdateInstallationID:
            return "Cannot update installation identifier"
        }
    }
    
    // MARK: Initializers
    /// Converts `rawValue` in `Self` if it does correspont to a valid `Self` value.
    /// 
    /// - parameters:
    ///   - rawValue: must be either 1, 1000, 1001, 1002, 2000, 3000, 4000, 5000, 6000, 7000 or 7001
    ///   - returns: `nil` if rawValue is not 1, 1000, 1001, 1002, 2000, 3000, 4000, 5000, 6000, 7000 or 7001
    public init?(rawValue: Int) {
        switch rawValue {
        case 1:
            self = .TokenNotFoundInAppConfiguration
        case 1000:
            self = .CannotDownloadRegionMonitoringConfiguration
        case 1001:
            self = .RegionMonitoringIsNotAuthorized
        case 1002:
            self = .NoRegionsToMonitor
        case 2000:
            self = .CannotDownloadRecipes
        case 3000:
            self = .CannotEvaluateRecipe
        case 4000:
            self = .CannotDownloadNotificationReactions
        case 5000:
            self = .CannotDownloadContentReactions
        case 6000:
            self = .CannotDownloadPollReactions
        case 7000:
            self = .CannotReceiveInstallationID
        case 7001:
            self = .CannotUpdateInstallationID
        default:
            return nil
        }
    }
    
    /// Returns a `PluginEvent` instance configured for `Self`.
    func pluginEvent(pluginName: String, message: String, operation: String) -> PluginEvent {
        return PluginEvent(from: pluginName, content: JSON(dictionary: ["error": self.rawValue, "description": description, "message": message, "operation": operation]))
    }
}
