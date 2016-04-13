//
//  NPBeaconRangingTests.swift
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

class NPBeaconRangingTests: XCTestCase {
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
    func testRangeKnownBeacon() {
        let rangePlugin = THBeaconRange(authorizationStatusStub: CLAuthorizationStatus.AuthorizedAlways)
        
        SDKDelegate.didReceiveEvaluatedContents = { (contents) -> Void in
            for content in contents {
                print(content.dictionary)
            }
            
            XCTAssertEqual(contents.count, 2)
            self.expectation.fulfill()
        }
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            NearSDK.plugins.plug(rangePlugin)
            rangePlugin.locationManager(CLLocationManager(), didRangeBeacons: [THStubs.stubBeacon(major: 1, minor: 1), THStubs.stubBeacon(major: 2, minor: 2)], inRegion: THStubs.stubBeaconRegion())
        }
        
        configure("did receive an event which is not related to beacon ranging or sync", expectationDescription: "test range known beacon")
    }
    
    // MARK: Helper functions
    private func configure(failMessage: String, expectationDescription: String) {
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            XCTFail(failMessage)
            self.expectation.fulfill()
        }
        
        THStubs.stubConfigurationAPIResponse()
        
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
