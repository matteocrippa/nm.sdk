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
    
    // MARK: Test emptyness
    func testEmptyContent() {
        let empty = Content(content: APRecipeContent(json: JSON(dictionary: ["id": "content"]))!)
        XCTAssertTrue(empty.isEmpty)
        
        let content1 = Content(content: APRecipeContent(json: JSON(dictionary: ["id": "content", "text": "text"]))!)
        XCTAssertFalse(content1.isEmpty)
        
        let content2 = Content(content: APRecipeContent(json: JSON(dictionary: ["id": "content", "images": ["image1"]]))!)
        XCTAssertFalse(content2.isEmpty)
        
        let content3 = Content(content: APRecipeContent(json: JSON(dictionary: ["id": "content", "video": "http://sample.com/video.m4v"]))!)
        XCTAssertFalse(content3.isEmpty)
    }
    func testEmptyPoll() {
        let empty = Poll(poll: APRecipePoll(json: JSON(dictionary: ["id": "poll", "question": "", "answer-1": "", "answer-2": ""]))!)
        XCTAssertTrue(empty.isEmpty)
        
        let poll1 = Poll(poll: APRecipePoll(json: JSON(dictionary: ["id": "poll", "question": "question", "answer-1": "", "answer-2": ""]))!)
        XCTAssertFalse(poll1.isEmpty)
        
        let poll2 = Poll(poll: APRecipePoll(json: JSON(dictionary: ["id": "poll", "question": "", "answer-1": "answer", "answer-2": ""]))!)
        XCTAssertFalse(poll2.isEmpty)
        
        let poll3 = Poll(poll: APRecipePoll(json: JSON(dictionary: ["id": "poll", "question": "", "answer-1": "", "answer-2": "answer"]))!)
        XCTAssertFalse(poll3.isEmpty)
    }
    
    // MARK: Index command tests
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
        NearSDK.clearCorePluginsCache()
        NearSDK.profileID = nil
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
