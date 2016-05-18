//
//  NearSDK.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import UIKit
import NMNet
import NMJSON
import NMPlug

/// nearit.com iOS SDK.
///
/// NearSDK is designed to work with nearit.com platform.
/// 
/// Apps linked to nearit.com apps can:
///
/// - detect iBeacon™s
/// - evaluate (i.e. return) contents or polls (reactions) when an "enter region" event is detected for an iBeacon™ registered on nearit.com
/// NearSDK should be configured and started as soon as possible, for example in app's delegate method `application(_:didFinishLaunchingWithOprions:)`.
///
/// To configure NearSDK, a valid nearit.com token must be obtained from nearit.com and must be passed to NearSDK as an argument at startup time.
///
/// NearSDK can be started by one out of two class methods:
/// - start()
/// - start(appToken:)
/// 
/// If NearSDK is started by calling start(), app's `Info.plist` file must include nearit.com app token for key `NearSDKToken`.
/// 
/// If the app needs to use reactions (i.e. contents or polls) evaluated by NearSDK, one or more of its classes must implement `NearSDKDelegate` protocol's methods; `delegate` property of NearSDK must be set to the class(es) implementing `NearSDKDelegate` which should use reactions evaluated in response to the detection of a beacon.
///
/// The source code of NearSDK is open source and distributed with MIT license: for more informations, check the [NearSDK GitHub repository](https://github.com/nearit/nm.sdk)
@objc
public class NearSDK: NSObject, Extensible {
    // MARK: Static constants
    /// A `String` representing the current version of `NearSDK`.
    static let currentVersion = "0.8"
    
    private static let sharedSDK = NearSDK()
    private var timeoutInterval: NSTimeInterval = 10
    private var consoleOutput = false
    private var forwardCoreEvents = false
    private var corePluginNames = [String]()
    private var pluginHub: PluginHub!
    private var delegate: NearSDKDelegate?
    
    // Synchronization process support properties
    private static var syncDidEnd = false
    private static var syncingCorePlugins = Set<CorePlugin>()
    private static var syncincErrors = [CorePluginError]()
    
    // Initializer
    private override init() {
        super.init()
        
        pluginHub = PluginHub(extendedObject: self)
        
        let plugins: [Pluggable] = [NPBeaconForest(), NPRecipes(), NPRecipeReactionContent(), NPRecipeReactionPoll(), NPImageCache(), NPDevice(), NPSegmentation()]
        for plugin in plugins {
            pluginHub.plug(plugin)
            corePluginNames.append(plugin.name)
        }
    }
    
    // MARK: Class properties
    /// The delegate object which will receive SDK's events.
    /// 
    /// The SDK will produce easy to process events whenever a core plugin will produce an event.
    /// 
    /// Events produced by 3rd party plugins will be sent to the delegate as they are received.
    public class var delegate: NearSDKDelegate? {
        get {
            return sharedSDK.delegate
        }
        set(newDelegate) {
            sharedSDK.delegate = newDelegate
        }
    }
    
    /// Plugin hub exposed by the SDK.
    public class var plugins: PluginHub {
        return sharedSDK.pluginHub
    }
    
    /// The app token linked to an app registered on nearit.com.
    ///
    /// The token must be a valid JSON Web Token.
    /// 
    /// If the token is a valid nearit.com token, `API.appID` property will return the app identifier of an app registered on nearit.com for which the authorization token has been issued, otherwise, `API.appID` will be empty, but `API.authorizationToken` will be equal to the new value.
    public class var appToken: String {
        get {
            return  API.authorizationToken
        }
        set(newToken) {
            API.authorizationToken = newToken
        }
    }
    /// The app identifier defined by `NearSDK.app`.
    public class var appID: String {
        return API.appID
    }
    /// The timeout interval of web requests sent to nearit.com servers.
    ///
    /// The default value is `10` seconds.
    /// 
    /// This value must be greater than `0`: assigning a value less than or equal to `0` will reset the timeout interval to `10` seconds.
    public class var timeoutInterval: NSTimeInterval {
        get {
            return sharedSDK.timeoutInterval
        }
        set(newTimeoutInterval) {
            sharedSDK.timeoutInterval = (newTimeoutInterval <= 0 ? 10 : newTimeoutInterval)
        }
    }
    /// A flag controlling the console output of `NearSDK`.
    /// 
    /// If true, NearSDK will output some informations on Xcode's console: the default value is `false`.
    public class var consoleOutput: Bool {
        get {
            return sharedSDK.consoleOutput
        }
        set(newFlag) {
            sharedSDK.consoleOutput = newFlag
        }
    }
    /// A flag which controls if events generate by `NearSDK`'s core plugin are forwarded to the object implementing `NearSDKDelegate` protocol, which is set via `NearSDK.delegate` property.
    ///
    /// If `true`, all events generated by core plugins will be forwarded to delegate "as-is", otherwise they will be silenced - the delegate will not receive any of these events.
    public class var forwardCoreEvents: Bool {
        get {
            return sharedSDK.forwardCoreEvents
        }
        set(newFlag) {
            sharedSDK.forwardCoreEvents = newFlag
        }
    }
    /// The names of the core plugins used by `NearSDK`.
    public class var corePluginNames: [String] {
        return sharedSDK.corePluginNames
    }
    
    // MARK: Controlling `NearSDK`
    /// Starts the SDK.
    ///
    /// - parameters:
    ///   - appToken: the app token used by `NearSDK`; if nil or not defined, it must be configured in app's `Info.plist` file for key `NearSDKToken`
    /// - returns: `true` if `appToken` is valid and all core plugins have been started successfully, `false` otherwise
    public class func start(appToken token: String? = nil) -> Bool {
        // token is defined
        if let aToken = token {
            NearSDK.appToken = aToken
            return startCorePlugins()
        }
        
        // token is not defined (nil): use value NearSDKToken configured in app's Info.plist
        guard let aToken = NSBundle.mainBundle().objectForInfoDictionaryKey("NearSDKToken") as? String else {
            delegate?.nearSDKDidFail?(
                error: NearSDKError.TokenNotFoundInAppConfiguration,
                message: "A valid token must be configured in app's Info.plist for key \"NearSDKToken\": it must be linked to an app registered on nearit.com")
            
            Console.error(NearSDK.self, text: "Cannot start NearSDK")
            Console.errorLine("NearSDKToken key not found in app's Info.plist")
            Console.errorLine("Add NearSDKToken key to app's Info.plist or start NearSDK by calling NearSDK(token:)")
            return false
        }
        
        NearSDK.appToken = aToken
        return startCorePlugins()
    }
    private class func startCorePlugins() -> Bool {
        var result = true
        
        syncDidEnd = false
        syncincErrors = []
        syncingCorePlugins = [CorePlugin.Recipes, CorePlugin.BeaconForest, CorePlugin.Polls, CorePlugin.Contents]
        
        let arguments = JSON(dictionary: ["app-token": appToken, "timeout-interval": timeoutInterval])
        for plugin in syncingCorePlugins {
            result = result && (plugins.run(plugin.name, command: "sync", withArguments: arguments).status == .OK)
            
            if !result {
                Console.error(NearSDK.self, text: "An error occurred while starting NearSDK")
                Console.errorLine("NearSDK core plugin failed to run")
                Console.errorLine("plugin: \(plugin)")
            }
        }
        
        return result
    }
    private class func corePlugin(plugin: CorePlugin, didSynchronizeWithError error: CorePluginError?) {
        if let e = error {
            syncincErrors.append(e)
        }
        
        syncingCorePlugins.remove(plugin)
        delegate?.nearSDKPluginDidSync?(plugin, error: error)
        
        if !syncDidEnd && syncingCorePlugins.count <= 0 {
            syncDidEnd = true
            delegate?.nearSDKDidSync?(syncincErrors)
        }
    }
    
    /// Touches a push notification.
    ///
    /// This method marks a notification as "opened" or "touched" on nearit.com.
    /// The input parameter `userInfo` must include at least the key `push_id`, otherwise no push will be touched.
    /// If `downloadRecipe` is set to `true`, `userInfo` must also include key `recipe_id`.
    /// This method will read the current installation identifier and will not touch the push notification if no installation identifier can be found.
    /// An installation identifier can be obtained by calling `NearSDK.refreshInstallationID(APNSToken:didRefresh:)`.
    ///
    /// - parameters:
    ///   - userInfo: the userInfo dictionary of the remote push notification
    ///   - action: the touch action - `Received` or `Opened`
    ///   - downloadRecipe: if `true`, this method will try to download the recipe linked to the push notification; the identifier of the recipe must be define in `userInfo` key `recipe_id`. The default value of this flag is `false`
    ///   - completionHandler: an optional handler which informs if the push notification has been touched on nearit.com
    /// - seealso: `refreshInstallationID(APNSToken:didRefresh:)`
    public class func touchPushNotification(userInfo userInfo: [NSObject: AnyObject], action: PushNotificationAction, downloadRecipe: Bool = false, completionHandler: DidTouchNotification? = nil) {
        let response = plugins.run(CorePlugin.Device.name, command: "read")
        guard let pushID = userInfo["push_id"] as? String, installationID = response.content.string("installation-id") where response.status == PluginResponseStatus.OK else {
            completionHandler?(success: false, notificationTouched: false, recipeDownloaded: false)
            return
        }
        
        switch action {
        case .Received:
            PushNotificationsAPI.touchReceived(pushID, installationID: installationID, response: { (data, status) in
                downloadPushNotificationRecipe(
                    touchStatus: status,
                    recipeID: userInfo["recipe_id"] as? String,
                    downloadRecipe: downloadRecipe,
                    completionHandler: completionHandler)
            })
        case .Opened:
            PushNotificationsAPI.touchOpened(pushID, installationID: installationID, response: { (data, status) in
                downloadPushNotificationRecipe(touchStatus: status,
                    recipeID: userInfo["recipe_id"] as? String,
                    downloadRecipe: downloadRecipe,
                    completionHandler: completionHandler)
            })
        }
    }
    private class func downloadPushNotificationRecipe(touchStatus status: HTTPStatusCode, recipeID: String?, downloadRecipe flag: Bool, completionHandler: DidTouchNotification?) {
        if status.codeClass != HTTPStatusCodeClass.Successful {
            completionHandler?(success: false, notificationTouched: true, recipeDownloaded: false)
            return
        }
        
        if !flag {
            completionHandler?(success: true, notificationTouched: true, recipeDownloaded: false)
            return
        }
        
        guard let id = recipeID else {
            completionHandler?(success: false, notificationTouched: true, recipeDownloaded: false)
            return
        }
        
        downloadRecipe(id, completionHandler: { (success) in
            completionHandler?(success: success, notificationTouched: true, recipeDownloaded: success)
        })
    }
    
    /// Downloads a recipe.
    ///
    /// This method should be used whenever the download of a recipe is preferred, for example in response to a remote notification.
    /// - parameters:
    ///   - id: the identifier of the recipe which should be downloaded
    ///   - completionHandler: an optional handler which informs if the download succeeded or not
    public class func downloadRecipe(id: String, completionHandler: DidCompleteOperation? = nil) {
        plugins.runAsync(CorePlugin.Recipes.name, command: "download", withArguments: JSON(dictionary: ["id": id])) { (response) in
            completionHandler?(success: response.status == .OK)
        }
    }
    /// Evaluates a recipe.
    ///
    /// This method evaluates a recipe immediately if it has been downloaded previously, otherwise it will download it before attempting to evaluate it again.
    /// The result of the evaluation will be forwarded to `nearSDKDidEvaluateRecipe(_:)` method of `NearSDKDelegate` protocol.
    /// - parameters:
    ///   - id: the identifier of the recipe which should be evaluated
    ///   - downloadAgain: if `true`, the recipe will be downloaded again; the default value of this flag is `false` - this option will overwrite the recipe which was cached for the given identifier, including its contents; if the download fails, the old copy of the recipe will be evaluated
    ///   - completionHandler: an optionalHandler which informs if the evaluation succeeded and if the recipe has been downloaded
    public class func evaluateRecipe(id: String, downloadAgain: Bool = false, completionHandler: DidEvaluateRecipe? = nil) {
        if downloadAgain {
            downloadAndEvaluateRecipe(id, completionHandler: completionHandler)
            return
        }
        
        let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate-recipe-by-id", withArguments: JSON(dictionary: ["id": id]))
        if response.status == PluginResponseStatus.OK {
            completionHandler?(success: true, didDownloadRecipe: false)
            return
        }
        
        downloadAndEvaluateRecipe(id, completionHandler: completionHandler)
    }
    private class func downloadAndEvaluateRecipe(id: String, completionHandler: DidEvaluateRecipe?) {
        downloadRecipe(id) { (success) in
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate-recipe-by-id", withArguments: JSON(dictionary: ["id": id]))
            completionHandler?(success: (response.status == PluginResponseStatus.OK), didDownloadRecipe: success)
        }
    }
    
    /// Returns some `UIImage` instances asynchronously for a given array of image identifiers.
    ///
    /// This method will download and cache images not found, previously cached images will not be downloaded again.
    ///
    /// When executed, the asynchronous handler `didFetchImages(images:downloaded:notFound:)` will return a `[String: UIImage]` dictionary of all images which have been found (`images`), the array of identifiers of downloaded images (`downloaded`: those images are included in `images`) and an array indicating the identifiers of images which cannot be found locally or downloaded.
    ///
    /// - parameters:
    ///   - identifiers: the identifiers of requested images; those identifiers must be linked to content reactions
    ///   - didFetchImages: the closure which should be exectude when images have been fetched
    /// - seealso: `Content` class
    public class func imagesWithIdentifiers(identifiers: [String], didFetchImages: DidFetchImages? = nil) {
        var fetched = [String: UIImage]()
        var notFound = Set<String>()
        
        if !images(identifiers, storeInto: &fetched, notFound: &notFound) {
            Console.error(NearSDK.self, text: "Cannot find images")
            didFetchImages?(images: fetched, downloaded: [], notFound: identifiers)
            return
        }
        
        if notFound.count <= 0 {
            Console.info(NearSDK.self, text: "Images found (\(fetched.count))")
            didFetchImages?(images: fetched, downloaded: [], notFound: [])
            return
        }
        
        Console.warning(NearSDK.self, text: "Some images cannot be found (\(notFound.count)) ")
        download(notFound, found: fetched) { (images, downloaded, notFound) in
            didFetchImages?(images: images, downloaded: downloaded, notFound: notFound)
        }
    }
    private class func images(identifiers: [String], inout storeInto target: [String: UIImage], inout notFound: Set<String>) -> Bool {
        let response = plugins.run(CorePlugin.ImageCache.name, command: "read", withArguments: JSON(dictionary: ["identifiers": identifiers]))
        guard let images = response.content.dictionary("images") where response.status == .OK else {
            target.removeAll()
            notFound = Set(identifiers)
            return false
        }
        
        notFound = Set(identifiers)
        for (id, image) in images {
            guard let imageInstance = image as? UIImage else {
                
                continue
            }
            
            notFound.remove(id)
            target[id] = imageInstance
        }
        
        return true
    }
    private class func download(notFound: Set<String>, found: [String: UIImage], completionHandler: DidFetchImages?) {
        Console.info(NearSDK.self, text: "Downloading images (\(notFound.count))...")
        MediaAPI.getImages(Array(notFound)) { (images, identifiersNotFound, status) in
            var result = images
            for (id, image) in found {
                result[id] = image
            }
            
            Console.infoLine("downloaded: (\(images.keys.count))")
            Console.infoLine(" not found: (\(identifiersNotFound.count))")
            completionHandler?(images: result, downloaded: Array(images.keys), notFound: identifiersNotFound)
        }
    }
    
    /// Clears all cached images.
    /// 
    /// All subsequent calls to `NearSDK.imagesWithIdentifiers(_:didFetchImages:)` may download images again.
    ///
    /// - returns: `true` if the cache has been cleared, `false` otherwise
    public class func clearImageCache() -> Bool {
        let didClearImageCache = (plugins.run(CorePlugin.ImageCache.name, command: "clear").status == .OK)
        if !didClearImageCache {
            Console.error(NearSDK.self, text: "Cannot clear images' cache")
        }
        
        return didClearImageCache
    }
    
    /// Refreshes an existing installation identifier or requests a new one.
    ///
    /// If a device installation can be found locally, it will be used to update the remote counterpart on nearit.com servers, otherwise a new installation will be requested and stored offline.
    ///
    /// - parameters:
    ///   - APNSToken: the optional Apple Push Notification token which should be associated to the device installation
    ///   - didRefresh: the closure which should be executed when the refresh of the installation identifier ends
    public class func refreshInstallationID(APNSToken APNSToken: String?, didRefresh: DidRefreshInstallationIdentifier?) {
        var dictionary = [String: AnyObject]()
        dictionary["app-token"] = NearSDK.appToken
        dictionary["timeout-interval"]  = NearSDK.timeoutInterval
        
        if let token = APNSToken {
            dictionary["apns-token"] = token
        }
        
        plugins.runAsync(CorePlugin.Device.name, command: "refresh", withArguments: JSON(dictionary: dictionary)) { (response) in
            if response.status != .OK {
                didRefresh?(status: .NotRefreshed, installation: nil)
                return
            }
            
            guard let statusValue = response.content.int("status"), installation = response.content.object("installation") as? DeviceInstallation else {
                didRefresh?(status: .Unknown, installation: nil)
                return
            }
            
            didRefresh?(status: DeviceInstallationStatus(rawValue: statusValue), installation: installation)
        }
    }
    
    // MARK: Communicating with NearSDK
    /// Sends an event to a registered plugin.
    /// 
    /// The plugin must support "post" asynchronous command and its response must include the raw (Int) value of a HTTPStatusCode case in response content for key `HTTPStatusCode`.
    /// The result of the action will be `SendEventResult.Success` if the class of the HTTP status code is `HTTPStatusCodeClass.Successful`.
    ///
    /// - parameters:
    ///   - event: the event being sent
    ///   - response: the handler which will be executed when `event`'s recipient will end processing `event`
    public class func sendEvent(event: EventSerializable, response handler: DidSendEvent?) {
        plugins.runAsync(CorePlugin.Polls.name, command: "post", withArguments: event.body) { (response) in
            let status = HTTPStatusCode(rawValue: response.content.int("HTTPStatusCode", fallback: -1)!)
            let result = (status.codeClass == HTTPStatusCodeClass.Successful ? SendEventResult.Success : SendEventResult.Failure)
            
            handler?(response: response, status: status, result: result)
        }
    }
    /// Sends an answer for a given poll to nearit.com.
    ///
    /// This is a facility method which sends a `PollAnswer` instance by calling `NearSDK.sendEvent(_:response:)`.
    ///
    /// - parameters:
    ///   - answer: the answer
    ///   - poll: the identifier of the target poll
    ///   - response: the handler which will be executed when the answer is sent to nearit.com or when an error occurs
    public class func sendPollAnswer(answer: APRecipePollAnswer, forPoll poll: String, response handler: DidSendEvent?) {
        sendEvent(PollAnswer(poll: poll, answer: answer), response: handler)
    }
    
    /// Manages plugins sent from registered plugins to `NearSDK`.
    public func didReceivePluginEvent(event: PluginEvent) {
        manageRecipeReaction(event)
        manageCoreEventForwarding(event)
    }
    private func manageRecipeReaction(event: PluginEvent) {
        switch event.from {
        case CorePlugin.Recipes.name:
            guard let contentJSON = event.content.json("reaction"), recipeJSON = event.content.json("recipe"), recipe = APRecipe(json: recipeJSON), type = event.content.string("type") else {
                return
            }
            
            manageReaction(contentJSON, recipe: recipe, type: type)
        default:
            break
        }
    }
    private func manageReaction(reactionJSON: JSON, recipe: APRecipe, type: String) {
        if type == "content-notification" || type == "poll-notification" {
            var content: APRecipeContent?
            if let json = reactionJSON.json("content") {
                content = APRecipeContent(json: json)
            }
            
            var poll: APRecipePoll?
            if let json = reactionJSON.json("poll") {
                poll = APRecipePoll(json: json)
            }
            
            delegate?.nearSDKDidEvaluateRecipe?(Recipe(recipe: recipe, contentReaction: content, pollReaction: poll))
        }
    }
    private func manageCoreEventForwarding(event: PluginEvent) {
        // Sync tasks and errors should be examined first
        manageSync(event)
        if manageError(event) {
            return
        }
        
        // Non-error events may be discarded
        if corePluginNames.contains(event.from) && !forwardCoreEvents {
            return
        }
        
        // Non-blocked events will be forwarded to delegate
        delegate?.nearSDKDidReceiveEvent?(event)
    }
    private func manageSync(event: PluginEvent) {
        guard let plugin = CorePlugin(name: event.from) where event.command == "sync" else {
            return
        }
        
        NearSDK.corePlugin(plugin, didSynchronizeWithError: CorePluginError(event: event))
    }
    private func manageError(event: PluginEvent) -> Bool {
        if let errorValue = event.content.int("error"), error = NearSDKError(rawValue: errorValue), message = event.content.string("message") {
            delegate?.nearSDKDidFail?(error: error, message: message)
            return true
        }
        
        return false
    }
    
    // MARK: Segmentation
    /// Gets or sets the current profile identifier.
    ///
    /// If the value of this property is set explicitly, it must be a valid profile identifier obtained by calling nearit.com APIs or `NearSDK.requestNewProfileID(_:)`.
    public static var profileID: String? {
        get {
            let response = plugins.run(CorePlugin.Segmentation.name, command: "read")
            guard let id = response.content.string("profile-id") where response.status == .OK else {
                return nil
            }
            
            return id
        }
        set(newValue) {
            guard let id = newValue else {
                plugins.run(CorePlugin.Segmentation.name, command: "clear")
                return
            }
            
            plugins.run(CorePlugin.Segmentation.name, command: "save", withArguments: JSON(dictionary: ["id": id]))
        }
    }
    /// Gets the current installation identifier.
    ///
    /// This value can be refreshed by calling `NearSDK.refreshInstallationID(APNSToken:didRefresh:)`.
    public static var installationID: String? {
        let response = plugins.run(CorePlugin.Device.name, command: "read")
        guard let id = response.content.string("installation-id") where response.status == .OK else {
            return nil
        }
        
        return id
    }
    /// Requests a new profile identifier.
    ///
    /// This method requires `NearSDK.installationID` to be not nil and will return the cached profile identifier, if found.
    /// - parameters:
    ///   - response: the response handler which will be called asynchronously when the profile identifier has been obtained or has been red from the local cache.
    public class func requestNewProfileID(response: ((id: String?) -> Void)?) {
        if let id = profileID {
            response?(id: id)
            return
        }
        
        guard let id = installationID else {
            response?(id: nil)
            return
        }
        
        APSegmentation.requestProfileID(appID: API.appID, installationID: id) { (id, status) in
            NearSDK.profileID = id
            response?(id: id)
        }
    }
}
