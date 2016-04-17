//
//  THStubs.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 11/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation
import OHHTTPStubs
import NMJSON
@testable import NMSDK

class THStubs {
    class func clear() {
        OHHTTPStubs.removeAllStubs()
    }
    
    class func stubConfigurationAPIResponse() {
        stubAPBeaconForestResponse()
        stubAPRecipesResponse()
        stubAPRecipeSimpleNotificationReactions()
        stubAPRecipeContentReactions()
        stubAPRecipePollReactions()
    }
    class func corePluginNames() -> Set<String> {
        var set = Set<String>()
        for name in NearSDK.corePluginNames {
            set.insert(name)
        }
        
        return set
    }
    
    private class func stubAPBeaconForestResponse() {
        func attributes(major major: Int, minor: Int) -> [String: AnyObject] {
            return ["uuid": "00000000-0000-0000-0000-000000000000", "major": major, "minor": minor]
        }
        func parent(id: String?) -> [String: AnyObject] {
            guard let parentID = id else {
                return ["data": NSNull()]
            }
            
            return ["data": ["id": parentID, "type": "beacons"]]
        }
        func children(identifiers: [String]) -> [String: AnyObject] {
            var result = [String: AnyObject]()
            
            for id in identifiers {
                guard var data = result["data"] as? [[String: AnyObject]] else {
                    result["data"] = [["id": id, "type": "beacons"]]
                    continue
                }
                
                data.append(["id": id, "type": "beacons"])
                result["data"] = data
            }
            
            return result
        }
        func node(id: String, major: Int, minor: Int, parent parentIdentifier: String? = nil, children childrenIdentifiers: [String] = []) -> [String: AnyObject] {
            return ["id": id, "type": "beacons", "attributes": attributes(major: major, minor: minor), "relationships": ["parent": parent(parentIdentifier), "children": children(childrenIdentifiers)]]
        }
        
        let R1_1    = node("R1_1",    major: 1,    minor: 1,                   children: ["C10_1",  "C10_2"])
        let R1_2    = node("R1_2",    major: 2,    minor: 1,                   children: ["C20_1",  "C20_2"])
        
        let C10_1   = node("C10_1",   major: 10,   minor: 1, parent: "R1_1",   children: ["C101_1", "C101_2"])
        let C10_2   = node("C10_2",   major: 10,   minor: 2, parent: "R1_1")
        let C20_1   = node("C20_1",   major: 20,   minor: 1, parent: "R1_2")
        let C20_2   = node("C20_2",   major: 20,   minor: 2, parent: "R1_2")
        
        let C101_1  = node("C101_1",  major: 101,  minor: 1, parent: "C10_1",  children: ["C1000_1"])
        let C101_2  = node("C101_2",  major: 101,  minor: 2, parent: "C10_1")
        
        let C1000_1 = node("C1000_1", major: 1000, minor: 1, parent: "C101_1")
        
        stub(isHost("api.nearit.com") && isPath("/plugins/beacon-forest/beacons")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(
                JSONObject: ["data": [R1_1, R1_2], "included": [C10_1, C10_2, C20_1, C20_2, C101_1, C101_2, C1000_1]],
                statusCode: 200,
                headers: nil)
        }
    }
    private class func stubAPRecipesResponse() {
        func recipe(id: String, nodeIdentifier: String, contentIdentifier: String, contentType: String, trigger: String) -> [String: AnyObject] {
            return [
                "id": id, "type": "recipes",
                "attributes": [
                    "name": "Recipe \(id)", "pulse_ingredient_id": "beacon-forest", "pulse_slice_id": nodeIdentifier,
                    "reaction_ingredient_id": contentType, "reaction_slice_id": contentIdentifier],
                "relationships": ["pulse_flavor": ["data": ["id": trigger, "type": "pulse_flavors"]]]
            ]
        }
        
        let recipe1 = recipe("R1", nodeIdentifier: "C10_1",   contentIdentifier: "CONTENT-1",      contentType: "content-notification", trigger: "enter_region")
        let recipe2 = recipe("R2", nodeIdentifier: "C10_2",   contentIdentifier: "NOTIFICATION-1", contentType: "simple-notification",  trigger: "FLAVOR-2")
        let recipe3 = recipe("R3", nodeIdentifier: "C20_1",   contentIdentifier: "POLL-1",         contentType: "poll-notification",    trigger: "FLAVOR-3")
        let recipe4 = recipe("R4", nodeIdentifier: "C10_1",   contentIdentifier: "UNKNOWN",        contentType: "unknown",              trigger: "FLAVOR-1")
        let recipe5 = recipe("R5", nodeIdentifier: "C1000_1", contentIdentifier: "CONTENT-1",      contentType: "unknown",              trigger: "FLAVOR-1")
        
        stub(isHost("api.nearit.com") && isPath("/recipes")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [recipe1, recipe2, recipe3, recipe4, recipe5]], statusCode: 200, headers: nil)
        }
    }
    private class func stubAPRecipeContentReactions() {
        let content1 = ["id": "CONTENT-1", "type": "notifications", "attributes": ["text": "<content's title>", "content": "<content's text>", "images_ids": [], "video_link": NSNull()]]
        let content2 = ["id": "CONTENT-2", "type": "notifications", "attributes": ["text": "<content's title>", "content": "<content's text>", "images_ids": [], "video_link": NSNull()]]
        let content3 = ["id": "CONTENT-3", "type": "notifications", "attributes": ["text": "<content's title>", "content": "<content's text>", "images_ids": ["IMAGE-1", "IMAGE-2"], "video_link": NSNull()]]
        
        stub(isHost("api.nearit.com") && isPath("/plugins/content-notification/notifications")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [content1, content2, content3]], statusCode: 200, headers: nil)
        }
    }
    private class func stubAPRecipeSimpleNotificationReactions() {
        let notification1 = ["id": "NOTIFICATION-1", "type": "notifications", "attributes": ["text": "<notification's text>"]]
        let notification2 = ["id": "NOTIFICATION-2", "type": "notifications", "attributes": ["text": "<notification's text>"]]
        
        stub(isHost("api.nearit.com") && isPath("/plugins/simple-notification/notifications")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [notification1, notification2]], statusCode: 200, headers: nil)
        }
    }
    private class func stubAPRecipePollReactions() {
        let poll1 = ["id": "POLL-1", "type": "notifications", "attributes": ["text": "<poll's text>", "question": "question", "choice_1": "answer 1", "choice_2": "answer 2"]]
        let poll2 = ["id": "POLL-2", "type": "notifications", "attributes": ["text": "<poll's text>", "question": "question", "choice_1": "answer 1", "choice_2": "answer 2"]]
        
        stub(isHost("api.nearit.com") && isPath("/plugins/poll-notification/notifications")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [poll1, poll2]], statusCode: 200, headers: nil)
        }
    }
    
    class func stubBeacon(major major: Int, minor: Int) -> CLBeacon {
        return THBeacon(major: major, minor: minor, proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, proximity: CLProximity.Near)
    }
    class func stubBeaconRegion() -> CLBeaconRegion {
        return CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, identifier: "identifier")
    }
}
