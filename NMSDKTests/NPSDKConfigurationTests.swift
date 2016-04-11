//
//  NPSDKConfigurationTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMNet
import NMJSON
import NMPlug
import OHHTTPStubs
import CoreLocation
@testable import NMSDK

class NPSDKConfigurationTests: XCTestCase {
    var expectation: XCTestExpectation!
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        SDKDelegate.didReceiveEvent = nil
        SDKDelegate.didSync = nil
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        OHHTTPStubs.removeAllStubs()
    }
    override func tearDown() {
        SDKDelegate.didReceiveEvent = nil
        SDKDelegate.didSync = nil
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = ""
        OHHTTPStubs.removeAllStubs()
        
        super.tearDown()
    }
    
    func testSync() {
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            XCTFail("did receive an event which is not related to sync")
            self.expectation.fulfill()
        }
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            self.expectation.fulfill()
        }
        
        THStubs.stubBeacons()
        THStubs.stubContents()
        THStubs.stubMatchRules()
        
        expectation = expectationWithDescription("test sync")
        XCTAssertTrue(NearSDK.sync())
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
