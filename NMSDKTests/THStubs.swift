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
        let root1 = [
            "id": "PARENT-1", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 1, "minor": 1],
            "relationships": [
                "parent": ["data": NSNull()],
                "children": ["data": [["id": "CHILD-1.PARENT-1", "type": "beacons"], ["id": "CHILD-2.PARENT-1", "type": "beacons"]]]]]
        let root2 = [
            "id": "PARENT-2", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 1, "minor": 2],
            "relationships": [
                "parent": ["data": NSNull()],
                "children": ["data": [["id": "CHILD-1.PARENT-2", "type": "beacons"], ["id": "CHILD-2.PARENT-2", "type": "beacons"]]]]]
        
        let included1 = [
            "id": "CHILD-1.PARENT-1", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 10, "minor": 1],
            "relationships": [
                "parent": ["data": ["id": "PARENT-1", "type": "beacons"]],
                "children": ["data": []]]]
        let included2 = [
            "id": "CHILD-2.PARENT-1", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 10, "minor": 2],
            "relationships": [
                "parent": ["data": ["id": "PARENT-1", "type": "beacons"]],
                "children": ["data": []]]]
        let included3 = [
            "id": "CHILD-1.PARENT-2", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 20, "minor": 1],
            "relationships": [
                "parent": ["data": ["id": "PARENT-2", "type": "beacons"]],
                "children": ["data": []]]]
        let included4 = [
            "id": "CHILD-2.PARENT-2", "type": "beacons",
            "attributes": ["uuid": "00000000-0000-0000-0000-000000000000", "major": 20, "minor": 2],
            "relationships": [
                "parent": ["data": ["id": "PARENT-2", "type": "beacons"]],
                "children": ["data": []]]]
        
        stub(isHost("api.nearit.com") && isPath("/plugins/beacon-forest/beacons")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [root1, root2], "included": [included1, included2, included3, included4]], statusCode: 200, headers: nil)
        }
    }
    private class func stubAPRecipesResponse() {
        let recipe1 = [
            "id": "RECIPE-1", "type": "recipes",
            "attributes": [
                "name": "Recipe 1 name", "pulse_ingredient_id": "beacon-forest", "pulse_slice_id": "CHILD-1.PARENT-1",
                "reaction_ingredient_id": "content-notification", "reaction_slice_id": "CONTENT-1"],
            "relationships": ["pulse_flavor": ["data": ["id": "FLAVOR-1", "type": "pulse_flavors"]]]
        ]
        let recipe2 = [
            "id": "RECIPE-2", "type": "recipes",
            "attributes": [
                "name": "Recipe 2 name", "pulse_ingredient_id": "beacon-forest", "pulse_slice_id": "CHILD-2.PARENT-1",
                "reaction_ingredient_id": "simple-notification", "reaction_slice_id": "CONTENT-2"],
            "relationships": ["pulse_flavor": ["data": ["id": "FLAVOR-2", "type": "pulse_flavors"]]]
        ]
        let recipe3 = [
            "id": "RECIPE-3", "type": "recipes",
            "attributes": [
                "name": "Recipe 3 name", "pulse_ingredient_id": "beacon-forest", "pulse_slice_id": "CHILD-1.PARENT-2",
                "reaction_ingredient_id": "poll-notification", "reaction_slice_id": "CONTENT-1"],
            "relationships": ["pulse_flavor": ["data": ["id": "FLAVOR-3", "type": "pulse_flavors"]]]
        ]
        
        stub(isHost("api.nearit.com") && isPath("/recipes")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [recipe1, recipe2, recipe3]], statusCode: 200, headers: nil)
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
