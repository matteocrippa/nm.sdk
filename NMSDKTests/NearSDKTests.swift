//
//  NearSDKTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import Foundation
import NMJSON
@testable import NMSDK

class NearSDKTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    func testAssignAppToken() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        NearSDK.token = token
        
        XCTAssertEqual(NearSDK.token, token)
        XCTAssertEqual(NearSDK.appID, "identifier")
        
        NearSDK.token = "invalid app token"
        XCTAssertTrue(NearSDK.token.isEmpty)
        XCTAssertNil(NearSDK.appID)
    }
    func testAssignAPITimeoutInterval() {
        NearSDK.timeoutInterval = 15
        XCTAssertEqualWithAccuracy(NearSDK.timeoutInterval, 15.0, accuracy: DBL_EPSILON)
        
        NearSDK.timeoutInterval = 0
        XCTAssertEqualWithAccuracy(NearSDK.timeoutInterval, 10.0, accuracy: DBL_EPSILON)
        
        NearSDK.timeoutInterval = -1
        XCTAssertEqualWithAccuracy(NearSDK.timeoutInterval, 10.0, accuracy: DBL_EPSILON)
    }
    func testStart() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test NearSDK.start")
        
        var pluginNames = THStubs.corePluginNames()
        SDKDelegate.didReceiveEvent = { (event) -> Void in
            pluginNames.remove(event.from)
            if pluginNames.count <= 0 {
                expectation.fulfill()
            }
        }
        
        XCTAssertTrue(NearSDK.start(token: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testStartFail() {
        let expectation = expectationWithDescription("test NearSDK.start fail")
        SDKDelegate.didReceiveError = { (error, message) -> Void in
            XCTAssertEqual(error, NearSDKError.TokenNotFoundInAppConfiguration)
            expectation.fulfill()
        }
        
        XCTAssertFalse(NearSDK.start())
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testDownloadImages() {
        THStubs.stubImages()
        THStubs.stubImageData()
        
        let expectation = expectationWithDescription("test get images")
        NearSDK.imagesWithIdentifiers(["image_1", "image_2"]) { (images, downloaded, notFound) in
            XCTAssertEqual(images.count, 2)
            XCTAssertEqual(downloaded.count, 2)
            XCTAssertEqual(notFound.count, 0)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testPartiallyCachedImages() {
        THStubs.stubImages()
        THStubs.stubImageData()
        
        let expectation = expectationWithDescription("test get images")
        NearSDK.plugins.run(CorePlugin.ImageCache.name, withArguments: JSON(dictionary: ["do": "store", "images": [["id": "image_1", "image": THStubs.sampleImage()]]]))
        NearSDK.imagesWithIdentifiers(["image_1", "image_2"]) { (images, downloaded, notFound) in
            XCTAssertEqual(images.count, 2)
            XCTAssertEqual(downloaded.count, 1)
            XCTAssertEqual(notFound.count, 0)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testCachedImages() {
        let expectation = expectationWithDescription("test get images")
        let arguments = JSON(dictionary: ["do": "store", "images": [["id": "image_1", "image": THStubs.sampleImage()], ["id": "image_2", "image": THStubs.sampleImage()]]])
        
        NearSDK.plugins.run(CorePlugin.ImageCache.name, withArguments: arguments)
        NearSDK.imagesWithIdentifiers(["image_1", "image_2"]) { (images, downloaded, notFound) in
            XCTAssertEqual(images.count, 2)
            XCTAssertEqual(downloaded.count, 0)
            XCTAssertEqual(notFound.count, 0)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testPartiallyCachedAndMissingImages() {
        THStubs.stubImages(excluded: ["image_4"])
        THStubs.stubImageData(excluded: ["image_3"])
        
        let expectation = expectationWithDescription("test get images")
        NearSDK.plugins.run(CorePlugin.ImageCache.name, withArguments: JSON(dictionary: ["do": "store", "images": [["id": "image_1", "image": THStubs.sampleImage()]]]))
        NearSDK.imagesWithIdentifiers(["image_1", "image_2", "image_3", "image_4"]) { (images, downloaded, notFound) in
            XCTAssertEqual(images.count, 2)
            XCTAssertEqual(downloaded.count, 1)
            XCTAssertEqual(notFound.count, 2)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        SDKDelegate.didReceiveNotifications = nil
        SDKDelegate.didReceiveContents = nil
        SDKDelegate.didReceivePolls = nil
        SDKDelegate.didReceiveEvent = nil
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
