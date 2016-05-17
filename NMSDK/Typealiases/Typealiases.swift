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

/// Used used when a notification has been touched.
public typealias DidTouchNotification = ((success: Bool, notificationTouched: Bool, recipeDownloaded: Bool) -> Void)

/// Used when a recipe has been evaluated.
public typealias DidEvaluateRecipe = ((success: Bool, didDownloadRecipe: Bool) -> Void)

/// A simple "operation successful" handler.
public typealias DidCompleteOperation = ((success: Bool) -> Void)

/// Used when images have been fetched.
public typealias DidFetchImages = ((images: [String: UIImage], downloaded: [String], notFound: [String]) -> Void)

/// Used when `NearSDK` completes the refresh of the installation identifier.
public typealias DidRefreshInstallationIdentifier = ((status: DeviceInstallationStatus, installation: DeviceInstallation?) -> Void)

/// Used when `NearSDK` sends an event to nearit.com.
public typealias DidSendEvent = ((response: PluginResponse, status: HTTPStatusCode, result: SendEventResult) -> Void)