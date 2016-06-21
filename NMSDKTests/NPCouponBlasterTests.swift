//
//  NPCouponBlasterTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/06/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMNet
import NMPlug
@testable import NMSDK

class NPCouponBlasterTests: XCTestCase {
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
    func testEvaluateBeaconForestCouponReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test evaluate coupon reaction with NPRecipes")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            NearSDK.profileID = "identifier"
            NearSDK.downloadProcessedRecipes { (success, recipes, contents, polls) in
                NearSDK.downloadCoupons({ (success) in
                    XCTAssertTrue(success)
                    
                    let args = JSON(dictionary: ["pulse-plugin": "beacon-forest", "pulse-bundle": "R1_1", "pulse-action": "enter_region"])
                    let response = NearSDK.plugins.run(CorePlugin.Recipes.name, command: "evaluate", withArguments: args)
                    XCTAssertEqual(response.status, PluginResponseStatus.OK)
                })
            }
        }
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNil(recipe.content)
            XCTAssertNil(recipe.poll)
            XCTAssertNotNil(recipe.coupon)
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
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
