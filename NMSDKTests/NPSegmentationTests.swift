//
//  NPSegmentationTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 18/05/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMNet
import NMPlug
import OHHTTPStubs
@testable import NMSDK

class NPSegmentationTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    // MARK: Segmentation management
    func testAssignKnownProfileID() {
        NearSDK.profileID = nil
        XCTAssertNil(NearSDK.profileID)
        
        NearSDK.profileID = "identifier"
        XCTAssertEqual(NearSDK.profileID, "identifier")
    }
    func testRequestNewProfileID() {
        THStubs.storeSampleDeviceInstallation()
        stub(isHost("api.nearit.com") && isPath("/plugins/congrego/profiles")) { (request) -> OHHTTPStubsResponse in
            let response = [
                "data": [
                    "id": "00000000-0000-0000-0000-000000000000", "type": "profiles", "attributes": ["app_id": "00000000-0000-0000-0000-000000000000"],
                    "relationships": ["data_points": ["data": []], "installations": ["data": []]]]
            ]
            
            return OHHTTPStubsResponse(JSONObject: response, statusCode: 201, headers: nil)
        }

        let expectation = expectationWithDescription("test request new profile identifier")
        NearSDK.requestNewProfileID { (id) in
            XCTAssertNotNil(NearSDK.profileID)
            XCTAssertNotNil(id)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testUpdateInstallationID() {
        THStubs.storeSampleDeviceInstallation()
        NearSDK.profileID = "00000000-0000-0000-0000-000000000000"
        stub(isHost("api.nearit.com") && isPath("/plugins/congrego/profiles/00000000-0000-0000-0000-000000000000/installations")) { (request) -> OHHTTPStubsResponse in
            let response = [
                "data": [
                    "id": "00000000-0000-0000-0000-000000000000", "type": "profiles", "attributes": ["app_id": "00000000-0000-0000-0000-000000000000"],
                    "relationships": ["data_points": ["data": []], "installations": ["data": []]]]
            ]
            
            return OHHTTPStubsResponse(JSONObject: response, statusCode: 201, headers: nil)
        }
        
        let expectation = expectationWithDescription("test update installation identifier")
        NearSDK.linkProfileToInstallation { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testAddDataPoints() {
        NearSDK.profileID = "00000000-0000-0000-0000-000000000000"
        stub(isHost("api.nearit.com") && isPath("/plugins/congrego/profiles/00000000-0000-0000-0000-000000000000/data_points")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 201, headers: nil)
        }
        
        let expectation = expectationWithDescription("test add data points")
        NearSDK.addProfileDataPoints(["key": "value"]) { (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        NearSDK.profileID = nil
        SDKDelegate.clearHandlers()
        NearSDK.clearCorePluginsCache()
        NearSDK.profileID = nil
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
