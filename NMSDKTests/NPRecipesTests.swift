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
    func testPropagateRecipeEvaluation() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test propagate recipe evaluation")
        
        let plugin = THSamplePlugin()
        NearSDK.plugins.plug(plugin)
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C10_1", "pulse-action": "enter_region"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didReceiveDidEvaluateRecipeCommand = { (contents) in
            NearSDK.plugins.unplug(plugin.name)
            
            XCTAssertTrue(contents.containsJSON("evaluation.reaction"))
            XCTAssertTrue(contents.containsJSON("evaluation.recipe"))
            XCTAssertEqual(contents.string("pulse.action"), "enter_region")
            XCTAssertEqual(contents.string("pulse.bundle"), "C10_1")
            XCTAssertEqual(contents.string("pulse.plugin"), "beacon-forest")
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testEvaluateBeaconForestJSONObjectReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate json object reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "R1_2", "pulse-action": "enter_region"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNil(recipe.content)
            XCTAssertNil(recipe.poll)
            XCTAssertNotNil(recipe.customJSONObject)
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
            
            let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "C10_1", "pulse-action": "enter_region"])
            let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
            XCTAssertEqual(response.status, PluginResponseStatus.OK)
        }
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            XCTAssertNil(recipe.poll)
            XCTAssertNil(recipe.customJSONObject)
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
            XCTAssertNil(recipe.customJSONObject)
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
            
            XCTAssertEqual(triggers.count, 7)
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
            
            NearSDK.sendEvent(PollAnswer(poll: "poll_id", answer: .Answer1, profileID: "profile-id", recipeID: "recipe-id")) { (response, status, result) in
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
                XCTAssertEqual(status.codeClass, HTTPStatusCodeClass.Successful)
                XCTAssertEqual(result, SendEventResult.Success)
                expectation.fulfill()
            }
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
            
            NearSDK.profileID = "profile-id"
            NearSDK.sendPollAnswer(.Answer1, forPoll: "poll_id", recipeID: "recipe-id") { (response, status, result) in
                XCTAssertEqual(result, SendEventResult.Success)
                XCTAssertTrue(response.content.containsInt("HTTPStatusCode"))
                
                NearSDK.profileID = nil
                expectation.fulfill()
            }
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Download recipes
    func testDownloadRecipeContentReaction() {
        THStubs.stubContentEvaluation()
        let expectation = expectationWithDescription("test download recipe - content reaction")
        
        NearSDK.downloadRecipe("CONTENT-RECIPE") { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testDownloadRecipePollReaction() {
        THStubs.stubPollEvaluation()
        let expectation = expectationWithDescription("test download recipe - poll reaction")
        
        NearSDK.downloadRecipe("POLL-RECIPE") { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Evaluate recipes by identifier
    func testEvaluateRecipeByIDContentReaction() {
        THStubs.stubContentEvaluation()
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
        THStubs.stubPollEvaluation()
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
        THStubs.stubContentEvaluation()
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
        THStubs.stubPollEvaluation()
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
        THStubs.stubContentEvaluation()
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
        THStubs.stubPollEvaluation()
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
        THStubs.stubContentEvaluation()
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
        THStubs.stubPollEvaluation()
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
    
    // MARK: Online evaluation - pulses
    func testOnlineEvaluationWithPulse_Content() {
        THStubs.stubOnlineEvaluationContent("RECIPE-ID", byID: false)
        let expectation = expectationWithDescription("test evaluate online recipe with pulse - content reaction")
        
        NearSDK.evaluateOnlinePulse(plugin: "IN-PLUGIN", action: "IN-ACTION", bundle: "IN-BUNDLE") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNotNil(recipe?.content)
            XCTAssertNil(recipe?.poll)
            XCTAssertNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testOnlineEvaluationWithPulse_Coupon() {
        THStubs.stubOnlineEvaluationCoupon("RECIPE-ID", byID: false)
        let expectation = expectationWithDescription("test evaluate online recipe with pulse - coupon reaction")
        
        NearSDK.evaluateOnlinePulse(plugin: "IN-PLUGIN", action: "IN-ACTION", bundle: "IN-BUNDLE") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNil(recipe?.content)
            XCTAssertNil(recipe?.poll)
            XCTAssertNotNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testOnlineEvaluationWithPulse_Poll() {
        THStubs.stubOnlineEvaluationPoll("RECIPE-ID", byID: false)
        let expectation = expectationWithDescription("test evaluate online recipe with pulse - poll reaction")
        
        NearSDK.evaluateOnlinePulse(plugin: "IN-PLUGIN", action: "IN-ACTION", bundle: "IN-BUNDLE") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNil(recipe?.content)
            XCTAssertNotNil(recipe?.poll)
            XCTAssertNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Online evaluation - identifiers
    func testOnlineEvaluationWithID_Content() {
        THStubs.stubOnlineEvaluationContent("RECIPE-ID", byID: true)
        let expectation = expectationWithDescription("test evaluate online recipe with id - content reaction")
        
        NearSDK.evaluateOnlineRecipe(id: "RECIPE-ID") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNotNil(recipe?.content)
            XCTAssertNil(recipe?.poll)
            XCTAssertNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testOnlineEvaluationWithID_Coupon() {
        THStubs.stubOnlineEvaluationCoupon("RECIPE-ID", byID: true)
        let expectation = expectationWithDescription("test evaluate online recipe with id - coupon reaction")
        
        NearSDK.evaluateOnlineRecipe(id: "RECIPE-ID") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNil(recipe?.content)
            XCTAssertNil(recipe?.poll)
            XCTAssertNotNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testOnlineEvaluationWithID_Poll() {
        THStubs.stubOnlineEvaluationPoll("RECIPE-ID", byID: true)
        let expectation = expectationWithDescription("test evaluate online recipe with id - poll reaction")
        
        NearSDK.evaluateOnlineRecipe(id: "RECIPE-ID") { (recipe, success) in
            XCTAssertNotNil(recipe)
            XCTAssertNil(recipe?.content)
            XCTAssertNotNil(recipe?.poll)
            XCTAssertNil(recipe?.coupon)
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Segmentation
    func testProcessedRecipes() {
        THStubs.storeSampleDeviceInstallation()
        THStubs.stubAPProcessedRecipesResponse()
        THStubs.stubAPProcessedRecipesReactions()
        
        let expectation = expectationWithDescription("test download processed recipes")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            switch recipe.id {
            case "RC":
                XCTAssertNotNil(recipe.content)
                NearSDK.evaluateRecipe("RP") { (success, didDownloadRecipe) in
                    XCTAssertTrue(success)
                }
            case "RP":
                XCTAssertNotNil(recipe.poll)
                expectation.fulfill()
            default:
                XCTFail("unknown recipe")
            }
        }
        NearSDK.downloadProcessedRecipes() { (success, recipes, contents, polls) in
            XCTAssertTrue(success)
            XCTAssertEqual(recipes.count, 8)
            XCTAssertEqual(contents.count, 2)
            XCTAssertEqual(polls.count, 2)
            XCTAssertEqual(contents[0].status, HTTPSimpleStatusCode.OK)
            XCTAssertEqual(polls[0].status, HTTPSimpleStatusCode.OK)
            
            NearSDK.evaluateRecipe("RC") { (success, didDownloadRecipe) in
                XCTAssertTrue(success)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testProcessedRecipesPartiallyCachedReactions() {
        THStubs.storeSampleDeviceInstallation()
        THStubs.stubAPProcessedRecipesResponse()
        THStubs.stubAPProcessedRecipesReactions()
        
        let resource = APIResource(
            type: "notifications",
            id: "CONTENT",
            attributes: JSON(dictionary: ["content": "<content's text>", "images_ids": [], "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]), relationships: [ :])
        NearSDK.plugins.run(CorePlugin.Contents.name, command: "store-online-resource", withArguments: JSON(dictionary: ["resource": resource]))
        
        let expectation = expectationWithDescription("test download processed recipes - partially cached reactions")
        
        NearSDK.downloadProcessedRecipes() { (success, recipes, contents, polls) in
            XCTAssertTrue(success)
            XCTAssertEqual(recipes.count, 8)
            XCTAssertEqual(contents.count, 2)
            XCTAssertEqual(polls.count, 2)
            XCTAssertEqual(contents[0].status, HTTPSimpleStatusCode.OK)
            XCTAssertEqual(polls[0].status, HTTPSimpleStatusCode.OK)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        SDKDelegate.clearHandlers()
        NearSDK.clearCorePluginsCache()
        NearSDK.profileID = nil
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
