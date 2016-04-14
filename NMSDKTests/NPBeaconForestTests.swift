//
//  NPBeaconForestTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import CoreLocation
import NMJSON
import NMPlug
@testable import NMSDK

class NPBeaconForestTests: XCTestCase {
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
    
    func testSync() {
        var pluginsLeft = [String: Bool]()
        for name in NearSDK.corePluginNames {
            pluginsLeft[name] = true
        }
        
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginsLeft.removeValueForKey(event.from)
            
            if pluginsLeft.count <= 0 {
                self.expectation.fulfill()
            }
        }
        
        configure("did receive an event which is not related to sync", expectationDescription: "test sync")
        XCTAssertTrue(NearSDK.start())
    }
    
    // MARK: Helper functions
    private func configure(failMessage: String, expectationDescription: String) {
        THStubs.stubConfigurationAPIResponse()
        
        expectation = expectationWithDescription(expectationDescription)
        XCTAssertTrue(NearSDK.start())
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    private func reset(appToken: String = "") {
        SDKDelegate.didReceiveEvaluatedContents = nil
        SDKDelegate.didReceiveEvent = nil
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = appToken
        THStubs.clear()
    }
}
