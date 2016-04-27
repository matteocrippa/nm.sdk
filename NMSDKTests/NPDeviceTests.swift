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
    
    // MARK: Update existing installation identifier
    func testUpdateInstallationIdentifier() {
        storeSampleDeviceInstallation()
        
        THStubs.stubRequestDeviceInstallation("installation-id", expectedHTTPStatusCode: .OK)
        let expectation = expectationWithDescription("test update installation identifier")
        
        SDKDelegate.didReceiveEvent = { (event) in
            XCTAssertEqual(event.from, CorePlugin.Device.name)
            XCTAssertEqual(event.content.string("status"), "updated")
            expectation.fulfill()
        }
        
        let response = NearSDK.plugins.run(CorePlugin.Device.name, withArguments: JSON(dictionary: ["do": "sync", "app-token": THStubs.SDKToken, "apns-token": "00000000-0000-0000-0000-000000000000"]))
        XCTAssertEqual(response.status, PluginResponseStatus.OK)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testUpdateInstallationIdentifierViaSDK() {
        storeSampleDeviceInstallation()
        
        THStubs.stubRequestDeviceInstallation("installation-id", expectedHTTPStatusCode: .OK)
        let expectation = expectationWithDescription("test update installation identifier via SDK")
        
        NearSDK.refreshInstallationID(APNSToken: "00000000-0000-0000-0000-000000000000") { (status, installation) in
            XCTAssertEqual(status, DeviceInstallationStatus.Updated)
            XCTAssertNotNil(installation)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Receive new installation identifier
    func testReceiveInstallationIdentifier() {
        THStubs.stubRequestDeviceInstallation(expectedHTTPStatusCode: .Created)
        let expectation = expectationWithDescription("test receive installation identifier")
        
        SDKDelegate.didReceiveEvent = { (event) in
            XCTAssertEqual(event.from, CorePlugin.Device.name)
            XCTAssertEqual(event.content.string("status"), "received")
            expectation.fulfill()
        }
        
        let response = NearSDK.plugins.run(CorePlugin.Device.name, withArguments: JSON(dictionary: ["do": "sync", "app-token": THStubs.SDKToken, "apns-token": "00000000-0000-0000-0000-000000000000"]))
        XCTAssertEqual(response.status, PluginResponseStatus.OK)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testReceiveInstallationIdentifierViaSDK() {
        THStubs.stubRequestDeviceInstallation(expectedHTTPStatusCode: .Created)
        let expectation = expectationWithDescription("test receive installation identifier via SDK")
        
        NearSDK.refreshInstallationID(APNSToken: "00000000-0000-0000-0000-000000000000") { (status, installation) in
            XCTAssertEqual(status, DeviceInstallationStatus.Received)
            XCTAssertNotNil(installation)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func storeSampleDeviceInstallation() {
        if let
            plugin: NPDevice = NearSDK.plugins.pluginNamed(CorePlugin.Device.name),
            sample = APDeviceInstallation(json: JSON(dictionary: ["id": "installation-id", "app-id": "app-id", "operating-system": "os", "operating-system-version": "test", "sdk-version": "test"])) {
                NearSDK.plugins.cache.store(sample, inCollection: "Installations", forPlugin: plugin)
        }
    }
    private func reset() {
        if let plugin: NPDevice = NearSDK.plugins.pluginNamed(CorePlugin.Device.name) {
            NearSDK.plugins.cache.removeAllResourcesWithPlugin(plugin)
        }
        
        NearSDK.consoleOutput = true
        SDKDelegate.clearHandlers()
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
