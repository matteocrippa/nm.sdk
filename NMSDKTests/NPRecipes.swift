//
//  NPRecipes.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMPlug
@testable import NMSDK

class NPRecipes: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4")
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    func testEvaluateBeaconForestContentReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate content reaction with NPRecipes")
        
        var pluginNames = THStubs.corePluginNames()
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginNames.remove(event.from)
            if pluginNames.count <= 0 {
                let response = NearSDK.plugins.run(
                    "com.nearit.sdk.plugin.np-recipes",
                    withArguments: JSON(dictionary: [
                        "do": "evaluate",
                        "in-case": "beacon-forest",
                        "in-target": "CHILD-1.PARENT-1",
                        "trigger": "FLAVOR-1"]))
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
            }
        }
        SDKDelegate.didReceiveEvaluatedContents = { (contents) -> Void in
            XCTAssertEqual(contents.count, 1)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start())
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset(appToken: String = "") {
        SDKDelegate.didReceiveEvaluatedContents = nil
        SDKDelegate.didReceiveEvent = nil
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = appToken
        THStubs.clear()
    }
}
