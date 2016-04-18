//
//  SDKError.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON

/// Error of the SDK
@objc
public enum SDKError: Int, CustomStringConvertible {
    // MARK: Region monitoring
    /// This error happens when the SDK is started,
    /// but the configuration of BeaconForest cannot be downloaded
    /// If this error occurs, the SDK will never be able to evaluate
    /// any type of content when an iBeacon™ is detected - contents, notifications and polls
    case CannotDownloadRegionMonitoringConfiguration = 1000
    
    /// This error happens when the SDK is started, but
    /// CLLocationManager.authorizationStatus() is not CLAuthorizationStatus.AuthorizedAlways
    /// Appropriate authorization levels should be obtained before starting the SDK.
    /// If this error occurs, the SDK will never be able to evaluate
    /// any type of content when an iBeacon™ is detected - contents, notifications and polls
    case RegionMonitoringIsNotAuthorized = 1001
    
    /// This error happens when the SDK is started,
    /// the user authorized the app to monitor region changes
    /// in backgrund, but no regions can be monitored because
    /// BeaconForest's configuration has been received, but it's empty.
    /// If this error occurs, the SDK will never be able to evaluate
    /// any type of content when an iBeacon™ is detected - contents, notifications and polls
    case NoRegionsToMonitor = 1002
    
    // MARK: Recipes
    /// This error happens when the SDK is started, but recipes cannot be downloaded.
    /// While the SDK may be able to detect iBeacon™s, it will not be able to evaluate any content
    case CannotDownloadRecipes = 2000
    
    /// This error happens when the SDK cannot evaluate correctly an event
    case CannotEvaluateRecipe = 3000
    
    /// This error happens when the SDK is started, but "notification" reactions cannot be downloaded.
    /// While the SDK may be able to detect iBeacon™s, it will not be able to evaluate notifications
    /// The SDK will be able to evaluate contents and polls when an iBeacon™ is detected
    case CannotDownloadNotificationReactions = 4000
    
    /// This error happens when the SDK is started, but "content" reactions cannot be downloaded.
    /// While the SDK may be able to detect iBeacon™s, it will not be able to evaluate contents
    /// The SDK will be able to evaluate notifications and polls when an iBeacon™ is detected
    case CannotDownloadContentReactions = 5000
    
    /// This error happens when the SDK is started, but "poll" reactions cannot be downloaded.
    /// While the SDK may be able to detect iBeacon™s, it will not be able to evaluate polls
    /// The SDK will be able to evaluate contents and notifications when an iBeacon™ is detected
    case CannotDownloadPollReactions = 6000
    
    /// SDKError description
    public var description: String {
        switch self {
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
        }
    }
    
    /// Initializes a value of SDKError
    public init?(rawValue: Int) {
        switch rawValue {
        case SDKError.CannotDownloadRegionMonitoringConfiguration.rawValue:
            self = .CannotDownloadRegionMonitoringConfiguration
        case SDKError.RegionMonitoringIsNotAuthorized.rawValue:
            self = .RegionMonitoringIsNotAuthorized
        case SDKError.NoRegionsToMonitor.rawValue:
            self = .NoRegionsToMonitor
        case SDKError.CannotDownloadRecipes.rawValue:
            self = .CannotDownloadRecipes
        case SDKError.CannotEvaluateRecipe.rawValue:
            self = .CannotEvaluateRecipe
        case SDKError.CannotDownloadNotificationReactions.rawValue:
            self = .CannotDownloadNotificationReactions
        case SDKError.CannotDownloadContentReactions.rawValue:
            self = .CannotDownloadContentReactions
        case SDKError.CannotDownloadPollReactions.rawValue:
            self = .CannotDownloadPollReactions
        default:
            return nil
        }
    }
    
    // MARK: Internal
    /// Returns a PluginEvent instance configured for the current SDKError
    func pluginEvent(pluginName: String, message: String) -> PluginEvent {
        return PluginEvent(from: pluginName, content: JSON(dictionary: ["error": self.rawValue, "description": description, "message": message]))
    }
}
