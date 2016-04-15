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
    
    func testEvaluateBeaconForestNotificationReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate notification reaction with NPRecipes")
        
        var pluginNames = THStubs.corePluginNames()
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginNames.remove(event.from)
            if pluginNames.count <= 0 {
                let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "CHILD-2.PARENT-1", "trigger": "FLAVOR-2"])
                let response = NearSDK.plugins.run("com.nearit.sdk.plugin.np-recipes", withArguments: args)
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
            }
        }
        SDKDelegate.didReceiveNotifications = { (notifications) -> Void in
            XCTAssertEqual(notifications.count, 1)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start())
        waitForExpectationsWithTimeout(1000, handler: nil)
    }
    func testEvaluateBeaconForestContentReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate content reaction with NPRecipes")
        
        var pluginNames = THStubs.corePluginNames()
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginNames.remove(event.from)
            if pluginNames.count <= 0 {
                let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "CHILD-1.PARENT-1", "trigger": "FLAVOR-1"])
                let response = NearSDK.plugins.run("com.nearit.sdk.plugin.np-recipes", withArguments: args)
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
            }
        }
        SDKDelegate.didReceiveContents = { (contents) -> Void in
            XCTAssertEqual(contents.count, 1)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start())
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateBeaconForestPollReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate poll reaction with NPRecipes")
        
        var pluginNames = THStubs.corePluginNames()
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginNames.remove(event.from)
            if pluginNames.count <= 0 {
                let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "CHILD-1.PARENT-2", "trigger": "FLAVOR-3"])
                let response = NearSDK.plugins.run("com.nearit.sdk.plugin.np-recipes", withArguments: args)
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
            }
        }
        SDKDelegate.didReceivePolls = { (polls) -> Void in
            XCTAssertEqual(polls.count, 1)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start())
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset(appToken: String = "") {
        SDKDelegate.didReceiveNotifications = nil
        SDKDelegate.didReceiveContents = nil
        SDKDelegate.didReceivePolls = nil
        SDKDelegate.didReceiveEvent = nil
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        NearSDK.appToken = appToken
        THStubs.clear()
    }
}
