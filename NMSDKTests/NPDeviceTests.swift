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
            
        }
        
        NearSDK.plugins.runAsync(
            CorePlugin.Device.name,
            command: "refresh",
            withArguments: JSON(dictionary: ["app-token": THStubs.SDKToken, "apns-token": "00000000-0000-0000-0000-000000000000"])) { (response) in
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
                
                guard let statusValue = response.content.int("status"), _ = response.content.object("installation") as? DeviceInstallation else {
                    XCTFail("invalid response content")
                    return
                }
                
                XCTAssertEqual(DeviceInstallationStatus(rawValue: statusValue), DeviceInstallationStatus.Updated)
                expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testUpdateInstallationIdentifierViaSDK() {
        storeSampleDeviceInstallation()
        
        THStubs.stubRequestDeviceInstallation("installation-id", expectedHTTPStatusCode: .OK)
        let expectation = expectationWithDescription("test update installation identifier via SDK")
        
        NearSDK.refreshInstallationID(APNSToken: "00000000-0000-0000-0000-000000000000") { (status, installation) in
            XCTAssertEqual(status, DeviceInstallationStatus.Updated)
            XCTAssertNotNil(installation)
            XCTAssertNotNil(installation?.apnsToken)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Receive new installation identifier
    func testReceiveInstallationIdentifier() {
        THStubs.stubRequestDeviceInstallation(expectedHTTPStatusCode: .Created)
        let expectation = expectationWithDescription("test receive installation identifier")
        
        NearSDK.plugins.runAsync(
            CorePlugin.Device.name,
            command: "refresh",
            withArguments: JSON(dictionary: ["app-token": THStubs.SDKToken, "apns-token": "00000000-0000-0000-0000-000000000000"])) { (response) in
                XCTAssertEqual(response.status, PluginResponseStatus.OK)
                
                guard let statusValue = response.content.int("status"), _ = response.content.object("installation") as? DeviceInstallation else {
                    XCTFail("invalid response content")
                    return
                }
                
                XCTAssertEqual(DeviceInstallationStatus(rawValue: statusValue), DeviceInstallationStatus.Received)
                expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testReceiveInstallationIdentifierViaSDK() {
        THStubs.stubRequestDeviceInstallation(expectedHTTPStatusCode: .Created)
        let expectation = expectationWithDescription("test receive installation identifier via SDK")
        
        NearSDK.refreshInstallationID(APNSToken: "00000000-0000-0000-0000-000000000000") { (status, installation) in
            XCTAssertEqual(status, DeviceInstallationStatus.Received)
            XCTAssertNotNil(installation)
            XCTAssertNotNil(installation?.apnsToken)
            
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
        
        SDKDelegate.clearHandlers()
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = true
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
