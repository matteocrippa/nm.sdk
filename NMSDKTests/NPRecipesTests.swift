//
//  NPRecipesTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMNet
import NMPlug
@testable import NMSDK

class NPRecipesTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    // MARK: Successful evaluations
    func testEvaluateBeaconForestNotificationReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate notification reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "C10_2", "trigger": "EVENT-2"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        
        SDKDelegate.didReceiveNotifications = { (notifications) in
            XCTAssertEqual(notifications.count, 1)
            XCTAssertNotNil(notifications[0].recipe)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateBeaconForestContentReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate content reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "C10_1", "trigger": "enter_region"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didReceiveContents = { (contents) in
            XCTAssertEqual(contents.count, 1)
            XCTAssertNotNil(contents[0].recipe)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateBeaconForestPollReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate poll reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "C20_1", "trigger": "EVENT-3"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didReceivePolls = { (polls) in
            XCTAssertEqual(polls.count, 1)
            XCTAssertNotNil(polls[0].recipe)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Unsuccessful evaluations
    func testRecipeNotFound() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test recipe not found")
        
        SDKDelegate.didReceiveError = { (error, message) in
            if error == NearSDKError.CannotEvaluateRecipe {
                expectation.fulfill()
            }
        }
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "C0_0", "trigger": "EVENT-X"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.Error)
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testUnprocessableRecipe() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test unprocessable recipe - unknown content type")
        
        SDKDelegate.didReceiveError = { (error, message) in
            if error == NearSDKError.CannotEvaluateRecipe {
                expectation.fulfill()
            }
        }
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["do": "evaluate", "in-case": "beacon-forest", "in-target": "C1000_1", "trigger": "EVENT-1"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.Error)
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Send events
    func testSendPollAnswer() {
        THStubs.stubConfigurationAPIResponse()
        THStubs.stubAPRecipePostPollAnswer(.Answer1, pollID: "poll_id")
        let expectation = expectationWithDescription("test send poll answer")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            NearSDK.sendEvent(PollAnswer(poll: "poll_id", answer: .Answer1), response: { (response, status) in
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
                XCTAssertEqual(status.codeClass, HTTPStatusCodeClass.Successful)
                expectation.fulfill()
            })
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testSendPollAnswerViaSDK() {
        THStubs.stubConfigurationAPIResponse()
        THStubs.stubAPRecipePostPollAnswer(.Answer1, pollID: "poll_id")
        let expectation = expectationWithDescription("test send poll answer via SDK")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            NearSDK.sendPollAnswer(.Answer1, forPoll: "poll_id") { (response, result) in
                XCTAssertEqual(result, SendEventResult.Success)
                XCTAssertEqual(response.dictionary.count, 0)
                expectation.fulfill()
            }
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
