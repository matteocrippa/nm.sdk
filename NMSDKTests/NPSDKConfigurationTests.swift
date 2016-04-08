//
//  NPSDKConfigurationTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 08/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import NMSDK

class NPSDKConfigurationTests: XCTestCase {
    var expectation: XCTestExpectation!
    let extended = THExtendedObject()
    
    override func setUp() {
        super.setUp()
        
        OHHTTPStubs.removeAllStubs()
    }
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        
        super.tearDown()
    }
}
