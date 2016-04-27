# NMSDK
nearit.com iOS SDK

**WARNING**

This is a pre-release software and is not production-ready - code snippets contained in this README are Swift 2.2.

**Installation**

`NearSDK` is available as a CocoaPod for iOS 8 and later and can be easily integrated into existing iOS apps by adding `pod 'NMSDK'` command to your `Podfile`.

The following code snippet may be used as a template of a `Podfile`

**sample Podfile**

    use_frameworks!

    target '<your app target name>' do
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

`NearSDK` can detect iBeacon™s registered for nearit.com apps: whenever a beacon is detected, a content, a notification or a poll may be evaluated by the SDK.

Contents, notifications and polls (more simply, "reactions") must be configured on nearit.com and must be linked to specific beacons.

The app which adopts `NearSDK` can receive such reactions by implementing some of the methods defined in `NearSDKDelegate` protocol:

- `nearSDKDidEvaluate(notifications:)` will return a collection of `Notification` instances
  - a notification reaction is described by one property, i.e. `text`
- `nearSDKDidEvaluate(contents:)` will return a collection of `Content` instances
  - a content reaction is described by some properties:
    - `title`
    - `text`
    - `videoURL` (optional)
    - `imageIdentifiers`
        - images can be downloaded by calling `NearSDK`'s class method `imagesWithIdentifiers(_:didFetchImages:)`
- `nearSDKDidEvaluate(polls:)` will return a collection of `Poll` instances
  - a poll reaction is described by some properties:
    - `question`
    - `text`
    - `answer1`
    - `answer2`
        - the chosen answer can be sent to nearit.com by calling `NearSDK`'s class method `sendPollAnswer(_:forPoll:response:)`

All reactions evaluated by `NearSDK` may include a reference to the evaluating `Recipe`, i.e. the transformation of an input event into an output reaction.
