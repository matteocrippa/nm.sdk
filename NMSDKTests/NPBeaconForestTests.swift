//
//  NPBeaconForestTests.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 17/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import XCTest
import NMJSON
import NMPlug
import CoreLocation
import OHHTTPStubs
@testable import NMSDK

class NPBeaconForestTests: XCTestCase {
    let SDKDelegate = THSDKDelegate()
    
    override func setUp() {
        super.setUp()
        
        reset()
    }
    override func tearDown() {
        reset()
        
        super.tearDown()
    }
    
    // MARK: Read configuration
    func testReadConfiguration() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test read configuration")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let response = NearSDK.plugins.run(CorePlugin.BeaconForest.name, command: "read-nodes")
            guard let nodes = response.content.dictionaryArray("nodes") else {
                XCTFail("nil nodes")
                return
            }
            
            XCTAssertEqual(nodes.count, 9)
            XCTAssertNotNil(nodes.first?["name"])
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testTreeStructure() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test tree structure")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let tests: [(id: String, parent: String?, children: [String])] = [
                ("R1_1",    nil,      ["C10_1",  "C10_2"]),
                ("R1_2",    nil,      ["C20_1",  "C20_2"]),
                ("C10_1",   "R1_1",   ["C101_1", "C101_2"]),
                ("C10_2",   "R1_1",   []),
                ("C20_1",   "R1_2",   []),
                ("C20_2",   "R1_2",   []),
                ("C101_1",  "C10_1",  ["C1000_1"]),
                ("C101_2",  "C10_1",  []),
                ("C1000_1", "C101_1", [])
            ]
            
            for configurationTest in tests {
                let response = NearSDK.plugins.run(CorePlugin.BeaconForest.name, command: "read-node", withArguments: JSON(dictionary: ["id": configurationTest.id]))
                
                XCTAssertEqual(response.content.string("node.id"), configurationTest.id)
                XCTAssertEqual(response.content.stringArray("node.children")!, configurationTest.children)
                XCTAssertEqual(response.content.string("node.parent"), configurationTest.parent == nil ? "-" : configurationTest.parent)
            }
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testSimulateEnterRegion() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test simulate enter")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let enterTests: [(id: String, target: [String])] = [
                ("R1_1",    ["R1_1", "R1_2", "C10_1", "C10_2"]),
                ("R1_2",    ["R1_1", "R1_2", "C20_1", "C20_2"]),
                ("C10_1",   ["C10_1", "C10_2", "C101_1", "C101_2"]),
                ("C10_2",   ["C10_1", "C10_2", "R1_1", "R1_2"]),
                ("C101_1",  ["C101_1", "C101_2", "C1000_1"]),
                ("C101_2",  ["C101_1", "C101_2", "C10_1", "C10_2"]),
                ("C1000_1", ["C101_1", "C101_2", "C1000_1"])
            ]
            
            for test in enterTests {
                let response = NearSDK.plugins.run(CorePlugin.BeaconForest.name, command: "read-next-nodes", withArguments: JSON(dictionary: ["when": "enter", "node-id": test.id]))
                XCTAssertEqual(response.content.stringArray("monitored-regions", emptyIfNil: true)!.sort(), test.target.sort())
            }
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testSimulateExitRegion() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test simulate exit")
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            let exitTests: [(id: String, target: [String])] = [
                ("R1_1", ["R1_1", "R1_2"]),
                ("C10_1", ["R1_1", "R1_2", "C10_1", "C10_2"]),
                ("C20_2", ["R1_1", "R1_2", "C20_1", "C20_2"]),
                ("C101_1", ["C101_1", "C101_2", "C10_1", "C10_2"]),
                ("C1000_1", ["C1000_1", "C101_1", "C101_2"])
            ]
            
            for test in exitTests {
                let response = NearSDK.plugins.run(CorePlugin.BeaconForest.name, command: "read-next-nodes", withArguments: JSON(dictionary: ["when": "exit", "node-id": test.id]))
                XCTAssertEqual(response.content.stringArray("monitored-regions", emptyIfNil: true)!.sort(), test.target.sort())
            }
            
            expectation.fulfill()
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Contents, polls, events
    func testEnterRegionReaction() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test read configuration")
        
        SDKDelegate.didEvaluateRecipe = { (recipe) in
            XCTAssertNotNil(recipe.content)
            expectation.fulfill()
        }
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            guard let beaconForest: NPBeaconForest = NearSDK.plugins.pluginNamed(CorePlugin.BeaconForest.name) else {
                XCTFail("sdk plugin NPBeaconForest cannot be found")
                return
            }
            
            beaconForest.locationManager(CLLocationManager(), didEnterRegion: THRegion(identifier: "C10_1"))
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    func testSendBeaconDetected() {
        THStubs.stubConfigurationAPIResponse()
        let expectation = expectationWithDescription("test send beacon detected")
        
        stub(isHost("api.nearit.com") && isPath("/plugins/beacon-forest/trackings")) { (request) -> OHHTTPStubsResponse in
            expectation.fulfill()
            return OHHTTPStubsResponse(data: NSData(), statusCode: 201, headers: nil)
        }
        
        SDKDelegate.sdkDidSync = { (errors) in
            XCTAssertEqual(errors.count, 0)
            
            guard let beaconForest: NPBeaconForest = NearSDK.plugins.pluginNamed(CorePlugin.BeaconForest.name) else {
                XCTFail("sdk plugin NPBeaconForest cannot be found")
                return
            }
            
            beaconForest.locationManager(CLLocationManager(), didEnterRegion: THRegion(identifier: "C10_1"))
        }
        
        XCTAssertTrue(NearSDK.start(appToken: THStubs.SDKToken))
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: Helper functions
    private func reset() {
        SDKDelegate.clearHandlers()
        NearSDK.clearImageCache()
        NearSDK.forwardCoreEvents = false
        NearSDK.delegate = SDKDelegate
        THStubs.clear()
    }
}
