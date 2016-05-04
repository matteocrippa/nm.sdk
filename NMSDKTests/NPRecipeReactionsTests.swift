//
//  NPRecipeReactionsTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 29/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMNet
import NMPlug
@testable import NMSDK

class NPRecipeReactionsTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    // MARK: Index command tests
    func testIndexNotifications() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test index notifications")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let response = NearSDK.plugins.run(CorePlugin.Notifications.name, command: "index")
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            XCTAssertNotNil(response.content.stringArray("reactions"))
            XCTAssertEqual(response.content.stringArray("reactions")?.count, 2)
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testIndexContents() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test index contents")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let response = NearSDK.plugins.run(CorePlugin.Contents.name, command: "index")
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            XCTAssertNotNil(response.content.stringArray("reactions"))
            XCTAssertEqual(response.content.stringArray("reactions")?.count, 3)
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testIndexPolls() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test index polls")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let response = NearSDK.plugins.run(CorePlugin.Polls.name, command: "index")
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            XCTAssertNotNil(response.content.stringArray("reactions"))
            XCTAssertEqual(response.content.stringArray("reactions")?.count, 2)
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        SDKDelegate.clearHandlers()
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
