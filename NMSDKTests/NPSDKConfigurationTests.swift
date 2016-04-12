//
//  NPSDKConfigurationTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMPlug
@testable import NMSDK

class NPSDKConfigurationTests: XCTestCase {
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
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            self.expectation.fulfill()
        }
        
        configure("did receive an event which is not related to sync", expectationDescription: "test sync")
    }
    func testReadConfiguration() {
        SDKDelegate.didSync = { (successfully) -> Void in
            XCTAssertTrue(successfully)
            
            let beacons = NearSDK.plugins.run("com.nearit.plugin.np-sdk-configuration", withArguments: JSON(dictionary: ["command": "read configuration", "scope": "beacons"]))
            XCTAssertEqual(beacons.status, PluginResponseStatus.OK)
            XCTAssertEqual(beacons.content.dictionaryArray("objects.beacons", emptyIfNil: true)!.count, 3)
            self.expectation.fulfill()
        }
        
        configure("did receive an event which is not related to sync", expectationDescription: "test read configuration")
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
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = appToken
        THStubs.clear()
    }
}
