//
//  NearSDKDelegate.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import NMJSON
import NMPlug

/**
 The protocol which should be implemented by classes which should receive and consume events generated by `NearSDK`.
 */
@objc
public protocol NearSDKDelegate {
    // MARK: Common methods
    /**
     This method is called after when all core plugins used by `NearSDK` have synced with nearit.com, but errors occured.
     
     - parameter errors: an array of errors produced by plugins which failed to synchronize with nearit.com
     - seealso: `CorePluginError`
     */
    optional func nearSDKSyncDidFailWithErrors(errors: [CorePluginError])
    
    /**
     This method is called after when all core plugins used by `NearSDK` have synced with nearit.com successfully.
     */
    optional func nearSDKDidSync()
    
    /**
     This method is called when one of core plugins used by `NearSDK` synchronizes itself with nearit.com.
     
     - parameter plugin: the core plugin which originated the event
     - parameter error: the optional error which describes why a core plugin did fail its synchronization task; if nil, the synchronization task is supposed to be successful
     - seealso:
       - `CorePlugin`
       - `CorePluginError`
     */
    optional func nearSDKPlugin(plugin: CorePlugin, didSyncWithError error: CorePluginError?)
    
    /**
     This method is called when region monitoring fails.
     
     Region monitoring may fail because:
     
     - authorization status is not `CLAuthorizationStatus.AuthorizedAlways` or `CLAuthorizationStatus.AuthorizedWhenInUse`
     - no regions can be found in `NearSDK`'s local cache
     - both of the above conditions are true
     
     - parameter configuredRegionsCount: indicates how many regions have been found in `NearSDK`'s local cache
     - parameter authorizationStatus: `CoreLocation`'s authorization status
     */
    optional func nearSDKRegionMonitoringDidFail(configuredRegionsCount configuredRegionsCount: Int, authorizationStatus: CLAuthorizationStatus)
    
    /**
     This method is called whenever `NearSDK` receives an event.
     
     - parameter event: the event received by `NearSDK`
     */
    optional func nearSDKDidReceiveEvent(event: PluginEvent)
    
    /**
     This method is called whenever `NearSDK` detects an error.
     
     - parameter error: the `NearSDKError` received by `NearSDK`
     - parameter message: a `String` which better describes the error
     - seealso: `NearSDKError`
     */
    optional func nearSDKDidFail(error error: NearSDKError, message: String)
    
    // MARK: Evaluations
    /**
     This method is called whenever `NearSDK` evaluates a recipe.
     
     - parameter recipe: the recipe evaluated by `NearSDK`
     - seealso: `Recipe`
     */
    optional func nearSDKDidEvaluateRecipe(recipe: Recipe)
}
