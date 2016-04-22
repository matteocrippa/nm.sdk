//
//  NPDeviceTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 22/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMPlug
import NMJSON
import NMNet
import OHHTTPStubs
@testable import NMSDK

class NPDeviceTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    func testObtainInstallationIdentifier() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        
        THStubs.stubRequestDeviceInstallation(expectedHTTPStatusCode: .Created)
        let expectation = expectationWithDescription("test obtain installation identifier")
        SDKDelegate.didReceiveEvent = { (event) in
            XCTAssertEqual(event.from, CorePlugin.Device.name)
            XCTAssertEqual(event.content.string("status"), "obtained")
            
            expectation.fulfill()
        }
        
        clearDeviceInstallations()
        let response = NearSDK.plugins.run(CorePlugin.Device.name, withArguments: JSON(dictionary: ["do": "sync", "app-token": token, "apns-token": "00000000-0000-0000-0000-000000000000"]))
        XCTAssertEqual(response.status, PluginResponseStatus.OK)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testUpdateInstallationIdentifier() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
        
        THStubs.stubRequestDeviceInstallation("installation-id", expectedHTTPStatusCode: .OK)
        let expectation = expectationWithDescription("test update installation identifier")
        SDKDelegate.didReceiveEvent = { (event) in
            XCTAssertEqual(event.from, CorePlugin.Device.name)
            XCTAssertEqual(event.content.string("status"), "updated")
            
            expectation.fulfill()
        }
        
        storeSampleDeviceInstallation()
        let response = NearSDK.plugins.run(CorePlugin.Device.name, withArguments: JSON(dictionary: ["do": "sync", "app-token": token, "apns-token": "00000000-0000-0000-0000-000000000000"]))
        XCTAssertEqual(response.status, PluginResponseStatus.OK)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func clearDeviceInstallations() {
        if let plugin: NPDevice = NearSDK.plugins.pluginNamed(CorePlugin.Device.name) {
            NearSDK.plugins.cache.removeAllResourcesWithPlugin(plugin)
        }
    }
    private func storeSampleDeviceInstallation() {
        if let plugin: NPDevice = NearSDK.plugins.pluginNamed(CorePlugin.Device.name) {
            NearSDK.plugins.cache.removeAllResourcesWithPlugin(plugin)
            
            if let sample = APDeviceInstallation(json: JSON(dictionary: ["id": "installation-id", "app-id": "app-id", "operating-system": "os", "operating-system-version": "test", "sdk-version": "test"])) {
                NearSDK.plugins.cache.store(sample, inCollection: "Installations", forPlugin: plugin)
            }
        }
    }
    private func reset() {
        SDKDelegate.clearHandlers()
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
