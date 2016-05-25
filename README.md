# NMSDK
nearit.com iOS SDK

**WARNING**

This is a pre-release software and is not production-ready.

Code snippets contained in this README are Swift 2.2.

Methods marked as "experimental" may not work.

**Installation**

`NearSDK` is available as a CocoaPod for iOS 8 and later and can be easily integrated into existing iOS apps by adding `pod 'NMSDK'` command to your `Podfile`.

The following code snippet may be used as a template of a `Podfile`.

**Code snippet** - *sample `Podfile`*

    use_frameworks!

    target '<the name of the target of your app>' do
      pod 'NMSDK'
    end

For more informations about CocoaPods, check visit the [official website](https://guides.cocoapods.org).

**Using `NearSDK`**

*Configuring an iOS app*

`NearSDK` interacts with nearit.com APIs, thus an app token is required: it can be obtained by creating an app on nearit.com.

Once a token has been obtained, it must be set either in app's `Info.plist` file (key `NearSDKToken`) or whenever `NearSDK` is started; those approaches are mutually exclusive.

`NearSDK` uses location services to better assist indoor navigation and to provide contents
to your app's users: this implies that iOS apps using the SDK must:

- define `NSLocationAlwaysUsageDescription` key in `Info.plist`
- enable `Background Modes` capabilities:
  - `Location updates`
  - `Uses Bluetooth LE accessories`

*Interacting with NearSDK*

`NearSDK` can be used in any class of your app by importing its module

    import NMSDK

    class YourClass {
      // Your class implementation
    }

`NearSDK` must be started before being ready to use, thus apps using the SDK must call one of these class methods:

- `start()`
- `start(token:)`

Calling one of such methods should be typically done at app's startup, for example in `application(_:didFinishLaunchingWithOptions:)` method of its `UIApplicationDelegate`.

If `start()` method is called, nearit.com app token must be set in app's `Info.plist` file (see above), otherwise the token will be the only (`token`) parameter required by the method.

The following code snippets illustrate how `NearSDK` can be started:

**Code snippet** - *nearit.com app token in app's `Info.plist` file, key `NearSDKToken`*

    import UIKit
    import NMSDK

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
      var window: UIWindow?

      func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NearSDK.start()
      }
    }

**Code snippet** - *nearit.com app token set at startup*

    import UIKit
    import NMSDK

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
      var window: UIWindow?

      func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NearSDK.start(token: "<nearit.com app token>")
      }
    }

Because `NearSDK` uses iBeacon™ technology, apps should start the SDK after appropriate permissions have been obtained; more specifically, apps should request `use always authorization` permission to `CoreLocation` before starting `NearSDK`.

`NearSDK`-to-Xcode console output can be enabled by setting class property`consoleOutput` to `true`.

*Using nearit.com contents*

`NearSDK` can detect iBeacon™s registered for nearit.com apps: whenever a beacon is detected, a content or a poll may be evaluated by the SDK.

Contents and polls (more simply, "reactions") must be configured on nearit.com and must be linked to specific beacons.

The app which adopts `NearSDK` can receive such reactions by implementing some of the methods defined in `NearSDKDelegate` protocol:

- `nearSDKDidRecipe(recipe:)` will return the evaluated `Recipe`, which may include a notification text and a reaction
  - a `Content` reaction is described by some properties:
    - `title`
    - `text`
    - `videoURL` (optional)
    - `imageIdentifiers`
        - images can be downloaded by calling `NearSDK`'s class method `imagesWithIdentifiers(_:didFetchImages:)`
  - a `Poll` reaction is described by some properties:
    - `question`
    - `text`
    - `answer1`
    - `answer2`
        - the chosen answer can be sent to nearit.com by calling `NearSDK`'s class method `sendPollAnswer(_:forPoll:response:)`

*Push notifications and NearSDK*

`NearSDK` can manage push notifications sent from nearit.com backend.

If this scenario must be supported by apps with `NearSDK`, two informations must be obtained:

- a valid Apple Push Notification Token
- a valid installation identifier from nearit.com

As the name implies, the *installation identifier* is what uniquely identifies a specific installation of a `NearSDK`-powered app and such identifier could be tied to an APNS token.

Installation identifiers can be only refreshed by calling `refreshInstallationID(APNSToken:didRefresh:)` class method of `NearSDK`.

Because this method accepts an optional `APNSToken`, it should be called either when an APNS token has been obtained or not.

**Code snippet** - *refresh installation id with APNS token*

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
      NearSDK.refreshInstallationID(APNSToken: deviceToken, didRefresh: nil)
    }

**Code snippet** - *refresh installation id without APNS token*

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
      NearSDK.refreshInstallationID(APNSToken: nil, didRefresh: nil)
    }

* Notes about NearSDK Core Plugins*
`NearSDK` uses some "core" plugins which fulfills requirements of the SDK itself: such plugins are built with [NMPlug](https://github.com/nearit/nm.plug) module.

Two of those plugins are used to detect events related to iBeacons™s and to produce contents, more specifically:

- `NearSDK` will broadcast:
  - `enter-region` command on broadcast key `beacon-forest`
    - event's content will be `["region-id": <String>, "event": "enter", "region-name": <String>]`
  - `exit-region` commands on broadcast key `beacon-forest`
    - event's content will be `["region-id": <String>, "event": "exit", "region-name": <String>]`
  - `evaluate-recipe` command on broadcast key `recipes`
    - event's content will be `["pulse": <JSON>, "evaluation": ["reaction": <JSON>, "recipe": <JSON>, "type": <String>]]`
