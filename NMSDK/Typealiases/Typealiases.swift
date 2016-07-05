//
//  Typealiases.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet
import NMPlug

/**
 Used used when a notification has been touched.
 */
public typealias DidTouchNotification = ((success: Bool, notificationTouched: Bool, recipeDownloaded: Bool) -> Void)

/**
 Used when a recipe has been evaluated.
 */
public typealias DidEvaluateRecipe = ((success: Bool, didDownloadRecipe: Bool) -> Void)

/**
 A simple "operation successful" handler.
 */
public typealias DidCompleteOperation = ((success: Bool) -> Void)

/**
 Used when a recipe is downloaded from nearit.com servers, but has not been cached.
 */
public typealias DidDownloadRecipe = ((recipe: Recipe?, status: HTTPStatusCode) -> Void)

/**
 Used when the identifier of a resource has been refreshed.
 If `id` is nil, it is assumed that the refresh operation did fail.
 */
public typealias DidRefreshIdentifier = ((id: String?) -> Void)

/**
 Used when images have been fetched.
 */
public typealias DidFetchImages = ((images: [String: UIImage], downloaded: [String], notFound: [String]) -> Void)

/**
 Used when `NearSDK` downloads processed recipes.
 `NearSDK` will return identifiers of downloaded recipes, plus identifiers of contents and polls, including a flag that indicates if they have been downloaded from nearit.com.
 */
public typealias DidDownloadProcessedRecipes = ((success: Bool, recipes: [String], contents: [(id: String, status: HTTPSimpleStatusCode)], polls: [(id: String, status: HTTPSimpleStatusCode)]) -> Void)

/**
 Used when `NearSDK` completes the refresh of the installation identifier.
 */
public typealias DidRefreshInstallationIdentifier = ((status: DeviceInstallationStatus, installation: DeviceInstallation?) -> Void)

/**
 Used when `NearSDK` sends an event to nearit.com.
 */
public typealias DidSendEvent = ((response: PluginResponse, status: HTTPStatusCode, result: SendEventResult) -> Void)

/**
 Used when `NearSDK` downloads a `Content` reaction.
 
 - seealso: `Content`
 */
public typealias DidDownloadContent = ((content: Content?, result: HTTPSimpleStatusCode) -> Void)

/**
 Used when `NearSDK` downloads a `Poll` reaction.
 
 - seealso: `Poll`
 */
public typealias DidDownloadPoll = ((poll: Poll?, result: HTTPSimpleStatusCode) -> Void)