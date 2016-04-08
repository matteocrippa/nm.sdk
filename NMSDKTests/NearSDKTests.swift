//
//  NearSDKTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
@testable import NMSDK

class NearSDKTests: XCTestCase {
    func testAssignAppToken() {
        let appToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        NearSDK.appToken = appToken
        
        XCTAssertEqual(NearSDK.appToken, appToken)
        XCTAssertEqual(NearSDK.appIdentifier, "identifier")
        
        NearSDK.appToken = "invalid app token"
        XCTAssertTrue(NearSDK.appToken.isEmpty)
        XCTAssertNil(NearSDK.appIdentifier)
    }
    func testAssignAPITimeoutInterval() {
        NearSDK.apiTimeoutInterval = 15
        XCTAssertEqualWithAccuracy(NearSDK.apiTimeoutInterval, 15.0, accuracy: DBL_EPSILON)
        
        NearSDK.apiTimeoutInterval = 0
        XCTAssertEqualWithAccuracy(NearSDK.apiTimeoutInterval, 10.0, accuracy: DBL_EPSILON)
        
        NearSDK.apiTimeoutInterval = -1
        XCTAssertEqualWithAccuracy(NearSDK.apiTimeoutInterval, 10.0, accuracy: DBL_EPSILON)
    }
}
