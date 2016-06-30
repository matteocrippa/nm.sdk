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
import NMNet
@testable import NMSDK

class THStubs {    
    class var SDKToken: String {
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJpZGVudGlmaWVyIiwicm9sZV9rZXkiOiJhcHAifX19.8Ut6wrGrqd81pb-ObNvOUvG0o8JaJhmTvKwGQ44Nqj4"
    }
    class func clear() {
        OHHTTPStubs.removeAllStubs()
    }
    
    class func stubPostTrack() {
        stub(isHost("api.nearit.com") && pathStartsWith("/trackings")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 201, headers: nil)
        }
    }
    class func stubConfigurationAPIResponse() {
        stubAPBeaconForestResponse()
        stubAPProcessedRecipesResponse()
        
        stubAPRecipeReactions()
        stubAPCouponBlasterResponse()
        stubAPProcessedRecipesReactions()
    }
    
    class func storeSampleDeviceInstallation() {
        if let
            plugin: NPDevice = NearSDK.plugins.pluginNamed(CorePlugin.Device.name),
            sample = APDeviceInstallation(json: JSON(dictionary: ["id": "installation-id", "app-id": "app-id", "operating-system": "os", "operating-system-version": "test", "sdk-version": "test"])) {
            NearSDK.plugins.cache.store(sample, inCollection: "Installations", forPlugin: plugin)
        }
    }
    class func stubTouchPushNotification(pushID: String) {
        stub(isHost("api.nearit.com") && isPath("/plugins/push-machine/pushes/\(pushID)/received")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 201, headers: nil)
        }
        stub(isHost("api.nearit.com") && isPath("/plugins/push-machine/pushes/\(pushID)/opened")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: NSData(), statusCode: 201, headers: nil)
        }
    }
    class func stubImages(excluded exclude: [String] = []) {
        stub(isHost("api.nearit.com") && pathStartsWith("/media/images")) { (request) -> OHHTTPStubsResponse in
            let excluded = request.URL!.lastPathComponent!.stringByReplacingOccurrencesOfString(".png", withString: "")
            if exclude.contains(excluded) {
                return OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: nil)
            }
            
            let id = request.URL!.absoluteString.componentsSeparatedByString("/").last!
            let image = ["id": id, "type": "images", "attributes": ["image": ["url": "https://sample.com/images/\(id).png"]], "relationships": []]
            
            return OHHTTPStubsResponse(JSONObject: ["data": image], statusCode: 200, headers: nil)
        }
    }
    class func stubImageData(excluded exclude: [String] = []) {
        stub(isHost("sample.com") && pathStartsWith("/images")) { (request) -> OHHTTPStubsResponse in
            let excluded = request.URL!.lastPathComponent!.stringByReplacingOccurrencesOfString(".png", withString: "")
            return OHHTTPStubsResponse(data: (exclude.contains(excluded) ? NSData() : sampleImageData()), statusCode: 200, headers: nil)
        }
    }
    class func stubRequestDeviceInstallation(id: String? = nil, expectedHTTPStatusCode: HTTPStatusCode) {
        var path = "/installations"
        if let installationID = id {
            path = "\(path)/\(installationID)"
        }
        
        stub(isHost("api.nearit.com") && isPath(path)) { (request) -> OHHTTPStubsResponse in
            let resource = [
                "data": [
                    "id": "installation-id",
                    "type": "installations",
                    "attributes": ["platform": "test", "platform_version": "0", "sdk_version": "0", "device_identifier": "00000000000000000000000000000000", "app_id": "app-id"],
                ]
            ]
            
            return OHHTTPStubsResponse(JSONObject: resource, statusCode: Int32(expectedHTTPStatusCode.rawValue), headers: nil)
        }
    }
    
    class func sampleImage() -> UIImage {
        return UIImage(data: sampleImageData())!
    }
    
    private class func sampleImageData() -> NSData {
        let base64Image = "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"
        return NSData(base64EncodedString: base64Image, options: NSDataBase64DecodingOptions(rawValue: 0))!
    }
    private class func stubAPBeaconForestResponse() {
        func attributes(major major: Int, minor: Int, name: String) -> [String: AnyObject] {
            return ["uuid": "00000000-0000-0000-0000-000000000000", "major": major, "minor": minor, "name": name]
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
        func node(id: String, major: Int, minor: Int, name: String, parent parentIdentifier: String? = nil, children childrenIdentifiers: [String] = []) -> [String: AnyObject] {
            return ["id": id, "type": "beacons", "attributes": attributes(major: major, minor: minor, name: name), "relationships": ["parent": parent(parentIdentifier), "children": children(childrenIdentifiers)]]
        }
        
        let R1_1    = node("R1_1",    major: 1,    minor: 1, name: "Root 1",                                    children: ["C10_1",  "C10_2"])
        let R1_2    = node("R1_2",    major: 2,    minor: 1, name: "Root 2",                                    children: ["C20_1",  "C20_2"])
        
        let C10_1   = node("C10_1",   major: 10,   minor: 1, name: "Child 1 - Parent R1_1",    parent: "R1_1",  children: ["C101_1", "C101_2"])
        let C10_2   = node("C10_2",   major: 10,   minor: 2, name: "Child 2 - Parent R1_1",    parent: "R1_1")
        let C20_1   = node("C20_1",   major: 20,   minor: 1, name: "Child 1 - Parent R1_2",    parent: "R1_2")
        let C20_2   = node("C20_2",   major: 20,   minor: 2, name: "Child 2 - Parent R1_2",    parent: "R1_2")
        
        let C101_1  = node("C101_1",  major: 101,  minor: 1, name: "Child 1 - Parent C10_1",   parent: "C10_1", children: ["C1000_1"])
        let C101_2  = node("C101_2",  major: 101,  minor: 2, name: "Child 2 - Parent C10_1",   parent: "C10_1")
        
        let C1000_1 = node("C1000_1", major: 1000, minor: 1, name: "Child 1 - Parent C1000_1", parent: "C101_1")
        
        stub(isHost("api.nearit.com") && isPath("/plugins/beacon-forest/beacons")) { (response) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(
                JSONObject: ["data": [R1_1, R1_2], "included": [C10_1, C10_2, C20_1, C20_2, C101_1, C101_2, C1000_1]],
                statusCode: 200,
                headers: nil)
        }
    }
    private class func attributes(name: String, notification: String, pulsePlugin: String, pulseBundle: String, reactionPlugin: String, reactionBundle: String) -> [String: AnyObject] {
        return [
            "name": name, "notification": ["title": "Notification title", "body": notification],
            "pulse_plugin_id": pulsePlugin,
            "pulse_bundle_id": pulseBundle,
            "operation_plugin_id": "OP-PLUGIN",
            "operation_bundle_id": "OP-BUNDLE",
            "reaction_plugin_id": reactionPlugin,
            "reaction_bundle_id": reactionBundle,
            "created_at": "2000-01-01T00:00:00.000Z",
            "updated_at": "2000-01-01T00:00:00.000Z"
        ]
    }
    private class func relationships(pulseAction pulseAction: String, pulseBundle: String, reactionAction: String, reactionBundle: String) -> [String: AnyObject] {
        return [
            "pulse_action": ["data": ["id": pulseAction, "type": "pulse_actions"]],
            "pulse_bundle": ["data": ["id": pulseBundle, "type": "pulse_bundles"]],
            "operation_action": ["data": ["id": "OP-ACTION", "type": "pulse_actions"]],
            "operation_bundle": ["data": ["id": "OP-BUNDLE", "type": "pulse_bundles"]],
            "reaction_action": ["data": ["id": reactionAction, "type": "pulse_actions"]],
            "reaction_bundle": ["data": ["id": reactionBundle, "type": "pulse_bundles"]]
        ]
    }
    private class func recipe(id: String, nodeIdentifier: String, contentIdentifier: String, contentType: String, trigger: String) -> [String: AnyObject] {
        return [
            "id": id, "type": "recipes",
            "attributes": attributes("Recipe \(id)", notification: "Notification \(id)", pulsePlugin: "beacon-forest", pulseBundle: nodeIdentifier, reactionPlugin: contentType, reactionBundle: contentIdentifier),
            "relationships": relationships(pulseAction: trigger, pulseBundle: nodeIdentifier, reactionAction: "SHOW", reactionBundle: contentIdentifier)
        ]
    }
    class func stubAPProcessedRecipesReactions() {
        // Contents
        let content = [
            "id": "CONTENT", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"],
            "relationships": ["images": ["data": [["id": "IMAGE", "type": "images"]]]]
        ]
        let content1 = [
            "id": "CONTENT-1", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let content2 = [
            "id": "CONTENT-2", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let content3 = [
            "id": "CONTENT-3", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"],
            "relationships": ["images": ["data": [["id": "IMAGE-1", "type": "images"], ["id": "IMAGE-1", "type": "images"]]]]
        ]
        
        for c in [content, content1, content2, content3] {
            let id = (c["id"] as! String)
            stub(isHost("api.nearit.com") && isPath("/plugins/content-notification/contents/\(id)")) { (request) -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(JSONObject: ["data": content], statusCode: 200, headers: nil)
            }
        }
        
        // Polls
        let poll = [
            "id": "POLL", "type": "notifications",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let poll1 = [
            "id": "POLL-1", "type": "notifications",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let poll2 = [
            "id": "POLL-2", "type": "notifications",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        
        for p in [poll, poll1, poll2] {
            let id = (p["id"] as! String)
            stub(isHost("api.nearit.com") && isPath("/plugins/poll-notification/polls/\(id)")) { (request) -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(JSONObject: ["data": poll], statusCode: 200, headers: nil)
            }
        }
    }
    class func stubAPCouponBlasterResponse() {
        stub(isHost("api.nearit.com") && pathStartsWith("/plugins/coupon-blaster/claims")) { (request) -> OHHTTPStubsResponse in
            let included: [String: AnyObject] = [
                "id": "COUPON-TEMPLATE-1",
                "type": "coupons",
                "attributes": [
                    "app_id": "00000000-0000-0000-0000-000000000000",
                    "name": "Coupon Name",
                    "description": "Description (\"100% Off!\")",
                    "value": "64% discount",
                    "expires_at": "2016-01-01T00:00:00.000Z",
                    "icon_id": "00000000-0000-0000-0000-000000000000"
                ]
            ]
            let response: [String: AnyObject] = [
                "data": [
                    [
                        "id": "COUPON-1", "type": "claims",
                        "attributes": [
                            "profile_id": "00000000-0000-0000-0000-000000000000",
                            "serial_number": "000000000000",
                            "claimed_at": "2016-01-01T00:00:00.000Z",
                            "redeemed_at": NSNull()
                        ],
                        "relationships": [
                            "coupon": [
                                "data": ["id": "COUPON-TEMPLATE-1", "type": "coupons"]
                            ]
                        ]
                    ]
                ],
                "included": [included]
            ]
            
            return OHHTTPStubsResponse(JSONObject: response, statusCode: 200, headers: nil)
        }
    }
    
    class func stubAPProcessedRecipesResponse() {
        let recipe1 = recipe("R1", nodeIdentifier: "C10_1",   contentIdentifier: "CONTENT-1",      contentType: "content-notification", trigger: "enter_region")
        let recipe2 = recipe("R2", nodeIdentifier: "C20_1",   contentIdentifier: "POLL-1",         contentType: "poll-notification",    trigger: "EVENT-3")
        let recipe3 = recipe("R41", nodeIdentifier: "C10_1",   contentIdentifier: "UNKNOWN",        contentType: "unknown",              trigger: "EVENT-1")
        let recipe4 = recipe("R51", nodeIdentifier: "C1000_1", contentIdentifier: "CONTENT-1",      contentType: "unknown",              trigger: "EVENT-1")
        
        let recipe5 = recipe("RC", nodeIdentifier: "C10_1",   contentIdentifier: "CONTENT",      contentType: "content-notification", trigger: "enter_region")
        let recipe6 = recipe("RP", nodeIdentifier: "C10_2",   contentIdentifier: "POLL",         contentType: "poll-notification",    trigger: "enter_region")
        let recipe7 = recipe("CP1", nodeIdentifier: "R1_1",   contentIdentifier: "COUPON-1",      contentType: "coupon-blaster", trigger: "enter_region")
        let recipe8 = recipe("JS1", nodeIdentifier: "R1_2",   contentIdentifier: "OBJECT-1",      contentType: "json-sender", trigger: "enter_region")
        
        stub(isHost("api.nearit.com") && isPath("/recipes/process")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [recipe1, recipe2, recipe3, recipe4, recipe5, recipe6, recipe7, recipe8]], statusCode: 200, headers: nil)
        }
    }
    private class func stubAPRecipeReactions() {
        let content1 = [
            "id": "CONTENT-1", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let content2 = [
            "id": "CONTENT-2", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let content3 = [
            "id": "CONTENT-3", "type": "notifications",
            "attributes": ["content": "<content's text>", "video_link": NSNull(), "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"],
            "relationships": ["images": ["data": [["id": "IMAGE-1", "type": "images"], ["id": "IMAGE-1", "type": "images"]]]]
        ]
        
        let poll1 = [
            "id": "POLL-1", "type": "notifications",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let poll2 = [
            "id": "POLL-2", "type": "notifications",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        
        let object1 = [
            "id": "OBJECT-1", "type": "json_contents",
            "attributes": ["content": ["json": ["key": "value 1"]], "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        let object2 = [
            "id": "OBJECT-2", "type": "json_contents",
            "attributes": ["content": ["json": ["key": "value 2"]], "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        
        stub(isHost("api.nearit.com") && isPath("/plugins/content-notification/contents")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [content1, content2, content3]], statusCode: 200, headers: nil)
        }
        stub(isHost("api.nearit.com") && isPath("/plugins/poll-notification/polls")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [poll1, poll2]], statusCode: 200, headers: nil)
        }
        stub(isHost("api.nearit.com") && isPath("/plugins/json-sender/json_contents")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": [object1, object2]], statusCode: 200, headers: nil)
        }
    }
    
    class func stubContentEvaluation() {
        let onlineRecipe = recipe("CONTENT-RECIPE", nodeIdentifier: "X", contentIdentifier: "CONTENT-ONLINE-EVALUATION", contentType: "content-notification", trigger: "online")
        let content = ["id": "CONTENT-ONLINE-EVALUATION", "type": "contents", "attributes": ["content": "<content's text>", "images": [], "video_link": NSNull()]]
        
        stub(isHost("api.nearit.com") && isPath("/recipes/CONTENT-RECIPE")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": onlineRecipe, "included": [content]], statusCode: 200, headers: nil)
        }
    }
    class func stubPollEvaluation() {
        let onlineRecipe = recipe("POLL-RECIPE", nodeIdentifier: "X", contentIdentifier: "POLL-ONLINE-EVALUATION", contentType: "poll-notification", trigger: "online")
        let poll = ["id": "POLL-ONLINE-EVALUATION", "type": "polls", "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2"]]
        
        stub(isHost("api.nearit.com") && isPath("/recipes/POLL-RECIPE")) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: ["data": onlineRecipe, "included": [poll]], statusCode: 200, headers: nil)
        }
    }
    class func stubAPRecipePostPollAnswer(answer: APRecipePollAnswer, pollID: String) {
        stub(isHost("api.nearit.com") && isPath("/plugins/poll-notification/polls/\(pollID)/answers")) { (request) -> OHHTTPStubsResponse in
            let responseResource = [
                "data": [
                    "id": "00000000-0000-0000-0000-000000000000",
                    "type": "answers",
                    "attributes": ["answer": answer.rawValue],
                    "relationships":["notification": ["data": ["id": pollID, "type":"notifications"]]]]
            ]
            
            return OHHTTPStubsResponse(JSONObject: responseResource, statusCode: 201, headers: nil)
        }
    }
    
    private class func onlineEvaluationResult(recipeID: String, reactionType: String, reactionObjects: [[String: AnyObject]]) -> [String: AnyObject] {
        let recipe: [String: AnyObject] = [
            "id": recipeID,
            "type": "recipes",
            "attributes": [
                "name": "recipe",
                "notification": ["title": "Notification title", "body": "Notification body"],
                "pulse_plugin_id": "IN-PLUGIN",
                "pulse_bundle_id": "IN-BUNDLE",
                "operation_plugin_id": "OP-PLUGIN",
                "operation_bundle_id": "OP-BUNDLE",
                "reaction_plugin_id": "OUT-PLUGIN",
                "reaction_bundle_id": "REACTION-ID",
                "created_at": "2000-01-01T00:00:00.000Z",
                "updated_at": "2000-01-01T00:00:00.000Z",
                "labels": ["online": true]
            ],
            "relationships": [
                "pulse_action": ["data": ["id": "IN-ACTION", "type": "pulse_actions"]],
                "pulse_bundle": ["data": ["id": "IN-BUNDLE", "type": "pulse_bundles"]],
                "operation_action": ["data": ["id": "OP-ACTION", "type": "pulse_actions"]],
                "operation_bundle": ["data": ["id": "OP-BUNDLE", "type": "pulse_bundles"]],
                "reaction_action": ["data": ["id": "OUT-ACTION", "type": "pulse_actions"]],
                "reaction_bundle": ["data": ["id": "REACTION-ID", "type": "pulse_bundles"]]
            ]
        ]
        
        var result: [String: AnyObject] = [
            "data": recipe
        ]
        
        var included: [[String: AnyObject]] = [recipe]
        for object in reactionObjects {
            included.append(object)
        }
        
        result["included"] = included
        return result
    }
    class func stubOnlineEvaluationContent(recipeID: String, byID: Bool) {
        let path = (byID ? "/recipes/\(recipeID)/evaluate" : "/recipes/evaluate")
        let content = [
            "id": "REACTION-ID", "type": "contents",
            "attributes": ["content": "The <b>text</b> of the <i>content</i>", "video_link": "https://sample.nearit.com/image.jpg", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"],
            "relationships": ["images": ["data": [["id": "IMAGE-1", "type": "images"], ["id": "IMAGE-2", "type": "images"]]]]]
        
        let reaction = onlineEvaluationResult(recipeID, reactionType: "contents", reactionObjects: [content])
        stub(isHost("api.nearit.com") && isPath(path)) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: reaction, statusCode: 200, headers: nil)
        }
    }
    class func stubOnlineEvaluationPoll(recipeID: String, byID: Bool) {
        let path = (byID ? "/recipes/\(recipeID)/evaluate" : "/recipes/evaluate")
        let poll = [
            "id": "REACTION-ID", "type": "polls",
            "attributes": ["question": "question", "choice_1": "answer 1", "choice_2": "answer 2", "created_at": "2000-01-01T00:00:00.000Z", "updated_at": "2000-01-01T00:00:00.000Z"]
        ]
        
        let reaction = onlineEvaluationResult(recipeID, reactionType: "polls", reactionObjects: [poll])
        stub(isHost("api.nearit.com") && isPath(path)) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: reaction, statusCode: 200, headers: nil)
        }
    }
    class func stubOnlineEvaluationCoupon(recipeID: String, byID: Bool) {
        let path = (byID ? "/recipes/\(recipeID)/evaluate" : "/recipes/evaluate")
        let coupon: [String: AnyObject] = [
            "id": "REACTION-ID",
            "type": "coupons",
            "attributes": [
                "app_id": "00000000-0000-0000-0000-000000000000",
                "name": "Coupon Name",
                "description": "Description (\"100% Off!\")",
                "value": "64% discount",
                "expires_at": "2016-01-01T00:00:00.000Z",
                "icon_id": "00000000-0000-0000-0000-000000000000"
            ]
        ]
        let claim: [String: AnyObject] = [
            "id": "00000000-0000-0000-0000-000000000000", "type": "claims",
            "attributes": [
                "profile_id": "00000000-0000-0000-0000-000000000000",
                "serial_number": "000000000000",
                "claimed_at": "2016-01-00T00:00:00.000Z",
                "redeemed_at": NSNull()
            ],
            "relationships": [
                "coupon": [
                    "data": ["id": "REACTION-ID", "type": "coupons"]
                ]
            ]
        ]
        
        let reaction = onlineEvaluationResult(recipeID, reactionType: "coupons", reactionObjects: [coupon, claim])
        stub(isHost("api.nearit.com") && isPath(path)) { (request) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(JSONObject: reaction, statusCode: 200, headers: nil)
        }
    }
    
    class func stubBeacon(major major: Int, minor: Int) -> CLBeacon {
        return THBeacon(major: major, minor: minor, proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, proximity: CLProximity.Near)
    }
    class func stubBeaconRegion() -> CLBeaconRegion {
        return CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "00000000-0000-0000-0000-000000000000")!, identifier: "identifier")
    }
}
