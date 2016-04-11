//
//  NPSDKBeaconMonitorTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMPlug
@testable import NMSDK

class NPSDKBeaconMonitorTests: XCTestCase {
    var expectation: XCTestExpectation!
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        SDKDelegate.didReceiveEvaluatedContents = nil
        SDKDelegate.didReceiveEvent = nil
        SDKDelegate.didSync = nil
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        THStubs.clear()
    }
    override func tearDown() {
        SDKDelegate.didReceiveEvaluatedContents = nil
        SDKDelegate.didReceiveEvent = nil
        SDKDelegate.didSync = nil
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = ""
        THStubs.clear()
        
        super.tearDown()
    }
    
    func testEvaluateKnownBeacon() {
        SDKDelegate.didReceiveEvaluatedContents = { (contents) -> Void in
            XCTAssertEqual(contents.count, 1)
            self.expectation.fulfill()
        }
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            XCTFail("did receive an event which is not related to sync")
            self.expectation.fulfill()
        }
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            let evaluation = NearSDK.plugins.run(NPSDKConfiguration().name, withArguments: THStubs.stubBeacon())
            XCTAssertEqual(evaluation.status, PluginResponseStatus.OK)
        }
        
        THStubs.stubBeacons()
        THStubs.stubContents()
        THStubs.stubMatchRules()
        
        expectation = expectationWithDescription("test sync")
        XCTAssertTrue(NearSDK.sync())
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
