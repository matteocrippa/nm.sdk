//
//  NPSDKBeaconRangingTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import CoreLocation
import NMJSON
import NMPlug
@testable import NMSDK

class NPSDKBeaconRangingTests: XCTestCase {
    var expectation: XCTestExpectation!
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4")
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    func testStartRanging() {
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            NearSDK.plugins.plug(THBeaconRange(authorizationStatusStub: CLAuthorizationStatus.NotDetermined))
            XCTAssertFalse(NearSDK.start())
            NearSDK.plugins.unplug("com.nearit.plugin.np-beacon-range")
            
            NearSDK.plugins.plug(THBeaconRange(authorizationStatusStub: CLAuthorizationStatus.AuthorizedWhenInUse))
            XCTAssertTrue(NearSDK.start())
            NearSDK.plugins.unplug("com.nearit.plugin.np-beacon-range")
            
            NearSDK.plugins.plug(THBeaconRange(authorizationStatusStub: CLAuthorizationStatus.AuthorizedAlways))
            XCTAssertTrue(NearSDK.start())
            NearSDK.plugins.unplug("com.nearit.plugin.np-beacon-range")
            
            self.expectation.fulfill()
        }
        
        configure("did receive an event which is not related to beacon ranging or sync", expectationDescription: "test start SDK")
    }
    func testEvaluateKnownBeacon() {
        SDKDelegate.didReceiveEvaluatedContents = { (contents) -> Void in
            XCTAssertEqual(contents.count, 1)
            self.expectation.fulfill()
        }
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            let evaluation = NearSDK.plugins.run("com.nearit.plugin.np-sdk-configuration", withArguments: THStubs.stubEvaluateBeacon())
            XCTAssertEqual(evaluation.status, PluginResponseStatus.OK)
        }
        
        configure("did receive an event which is not related to beacon ranging or sync", expectationDescription: "test evaluate known beacon")
    }
    func testRangeKnownBeacon() {
        let rangePlugin = THBeaconRange(authorizationStatusStub: CLAuthorizationStatus.AuthorizedAlways)
        
        SDKDelegate.didReceiveEvaluatedContents = { (contents) -> Void in
            XCTAssertEqual(contents.count, 1)
            self.expectation.fulfill()
        }
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            NearSDK.plugins.plug(rangePlugin)
            rangePlugin.locationManager(CLLocationManager(), didRangeBeacons: [THStubs.stubBeacon()], inRegion: THStubs.stubBeaconRegion())
        }
        
        configure("did receive an event which is not related to beacon ranging or sync", expectationDescription: "test range known beacon")
    }
    
    // MARK: Helper functions
    private func configure(failMessage: String, expectationDescription: String) {
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            XCTFail(failMessage)
            self.expectation.fulfill()
        }
        
        THStubs.stubBeacons()
        THStubs.stubContents()
        THStubs.stubMatchRules()
        
        expectation = expectationWithDescription(expectationDescription)
        XCTAssertTrue(NearSDK.sync())
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    private func reset(appToken: String = "") {
        SDKDelegate.didReceiveEvaluatedContents = nil
        SDKDelegate.didReceiveEvent = nil
        SDKDelegate.didSync = nil
        NearSDK.plugins.unplug("com.nearit.plugin.np-beacon-range")
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = appToken
        THStubs.clear()
    }
}
