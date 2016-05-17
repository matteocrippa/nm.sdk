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
    func testEvaluateBeaconForestContentReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate content reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C10_1", "pulse-action": "enter_region"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            XCTAssertNil(recipe.poll)
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
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C20_1", "pulse-action": "EVENT-3"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.poll)
            XCTAssertNil(recipe.content)
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
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C0_0", "pulse-action": "EVENT-X"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.Warning)
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
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C1000_1", "pulse-action": "EVENT-1"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.Warning)
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Read recipes
    func testIndexRecipes() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test index recipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "index")
            guard let triggers = response.content.dictionary("triggers") else {
                XCTFail("triggers not found")
                return
            }
            
            XCTAssertEqual(triggers.count, 4)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            expectation.fulfill()
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
            
            NearSDK.sendEvent(PollAnswer(poll: "poll_id", answer: .Answer1), response: { (response, status, result) in
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
                XCTAssertEqual(status.codeClass, HTTPStatusCodeClass.Successful)
                XCTAssertEqual(result, SendEventResult.Success)
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
            
            NearSDK.sendPollAnswer(.Answer1, forPoll: "poll_id") { (response, status, result) in
                XCTAssertEqual(result, SendEventResult.Success)
                XCTAssertTrue(response.content.containsInt("HTTPStatusCode"))
                expectation.fulfill()
            }
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Download recipes
    func testDownloadRecipeContentReaction() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test download recipe - content reaction")
        
        NearSDK.plugins.runAsync(CorePlugin.Recipes.name, command: "download", withArguments: JSON(dictionary: ["id": "CONTENT-RECIPE"])) { (response) in
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadRecipePollReaction() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test download recipe - poll reaction")
        
        NearSDK.plugins.runAsync(CorePlugin.Recipes.name, command: "download", withArguments: JSON(dictionary: ["id": "POLL-RECIPE"])) { (response) in
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadRecipeContentReactionViaSDK() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test download recipe - content reaction via SDK")
        
        NearSDK.downloadRecipe("CONTENT-RECIPE") { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadRecipePollReactionViaSDK() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test download recipe - poll reaction via SDK")
        
        NearSDK.downloadRecipe("POLL-RECIPE") { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Evaluate recipes by identifier
    func testEvaluateRecipeByIDContentReaction() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test evaluate downloaded recipe - content reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("CONTENT-RECIPE") { (success) in
            XCTAssertTrue(success)
            NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate-recipe-by-id", withArguments: JSON(dictionary: ["id": "CONTENT-RECIPE"]))
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateRecipeByIDPollReaction() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test evaluate downloaded recipe - poll reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.poll)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("POLL-RECIPE") { (success) in
            XCTAssertTrue(success)
            NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate-recipe-by-id", withArguments: JSON(dictionary: ["id": "POLL-RECIPE"]))
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateRecipeByIDContentReactionViaSDK() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test evaluate downloaded recipe via SDK - content reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("CONTENT-RECIPE") { (success) in
            XCTAssertTrue(success)
            
            NearSDK.evaluateRecipe("CONTENT-RECIPE") { (success, didDownloadRecipe) in
                XCTAssertTrue(success)
                XCTAssertFalse(didDownloadRecipe)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateRecipeByIDPollReactionViaSDK() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test evaluate downloaded recipe via SDK - poll reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.poll)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("POLL-RECIPE") { (success) in
            XCTAssertTrue(success)
            
            NearSDK.evaluateRecipe("POLL-RECIPE") { (success, didDownloadRecipe) in
                XCTAssertTrue(success)
                XCTAssertFalse(didDownloadRecipe)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadAndEvaluateRecipeByIDContentReactionViaSDK() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test download and evaluate recipe via SDK - content reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            expectation.fulfill()
        }
        NearSDK.evaluateRecipe("CONTENT-RECIPE") { (success, didDownloadRecipe) in
            XCTAssertTrue(success)
            XCTAssertTrue(didDownloadRecipe)
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadAndEvaluateRecipeByIDPollReactionViaSDK() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test download and evaluate recipe via SDK - poll reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.poll)
            expectation.fulfill()
        }
        NearSDK.evaluateRecipe("POLL-RECIPE") { (success, didDownloadRecipe) in
            XCTAssertTrue(success)
            XCTAssertTrue(didDownloadRecipe)
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testForceDownloadAndEvaluateRecipeByIDContentReactionViaSDK() {
        THStubs.stubOnlineContentEvaluation()
        let expectation = expectationWithDescription("test force download and evaluate recipe via SDK - content reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("CONTENT-RECIPE") { (success) in
            NearSDK.evaluateRecipe("CONTENT-RECIPE", downloadAgain: true) { (success, didDownloadRecipe) in
                XCTAssertTrue(success)
                XCTAssertTrue(didDownloadRecipe)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testForceDownloadAndEvaluateRecipeByIDPollReactionViaSDK() {
        THStubs.stubOnlinePollEvaluation()
        let expectation = expectationWithDescription("test force download and evaluate recipe via SDK - poll reaction")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.poll)
            expectation.fulfill()
        }
        NearSDK.downloadRecipe("POLL-RECIPE") { (success) in
            NearSDK.evaluateRecipe("POLL-RECIPE", downloadAgain: true) { (success, didDownloadRecipe) in
                XCTAssertTrue(success)
                XCTAssertTrue(didDownloadRecipe)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        SDKDelegate.clearHandlers()
        NearSDK.plugins.clearCache(pluginNamed: CorePlugin.Recipes.name)
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
