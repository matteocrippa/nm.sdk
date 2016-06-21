//
//  NPCouponBlaster.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/06/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMPlug
import NMJSON
import NMNet

class NPCouponBlaster: Plugin {
    // MARK: Plugin override
    override var name: String {
        return CorePlugin.CouponBlaster.name
    }
    override var version: String {
        return "0.1"
    }
    override var commands: [String: RunHandler] {
        return ["clear": clear, "read": read, "index": index]
    }
    override var asyncCommands: [String: RunAsyncHandler] {
        return ["download": download]
    }
    
    // MARK: Index
    private func read(arguments: JSON, sender: String?) -> PluginResponse {
        guard let id = arguments.string("content-id") else {
            Console.commandError(NPCouponBlaster.self, command: "read", requiredParameters: ["content-id"])
            return PluginResponse.cannotRun("read", requiredParameters: ["content-id"])
        }
        
        guard let reaction = coupon(id) else {
            Console.commandWarning(NPCouponBlaster.self, command: "read", cause: "Content \"\(id) \" not found")
            return PluginResponse.warning("Content \"\(id)\" not found", command: "read")
        }
        
        return PluginResponse.ok(reaction.json, command: "read")
    }
    private func index(arguments: JSON, sender: String?) -> PluginResponse {
        guard let resources: [APCoupon] = hub?.cache.resourcesIn(collection: "Reactions", forPlugin: self) else {
            return PluginResponse.warning("No coupons found", command: "index")
        }
        
        return PluginResponse.ok(JSON(dictionary: ["coupons": resources]), command: "index")
    }
    private func coupon(id: String) -> APCoupon? {
        guard let resource: APCoupon = hub?.cache.resource(id, inCollection: "Reactions", forPlugin: self) else {
            return nil
        }
        
        return resource
    }
    private func clear(arguments: JSON, sender: String?) -> PluginResponse {
        guard let pluginHub = hub else {
            return PluginResponse.cannotRun("clear")
        }
        
        pluginHub.cache.removeAllResourcesWithPlugin(self)
        return PluginResponse.ok(command: "clear")
    }
    
    // MARK: Download
    private func download(arguments: JSON, sender: String?, completionHandler: ResponseHandler?) -> Void {
        guard let appToken = arguments.string("app-token"), profileID = arguments.string("profile-id") else {
            Console.commandError(NPCouponBlaster.self, command: "download", requiredParameters: ["app-token", "profile-id"], optionalParameters: ["timeout-interval"])
            completionHandler?(response: PluginResponse.cannotRun("download", requiredParameters: ["app-token", "profile-id"], optionalParameters: ["timeout-interval"]))
            return
        }
        
        API.authorizationToken = appToken
        API.timeoutInterval = arguments.double("timeout-interval") ?? 10.0
        
        Console.info(NPCouponBlaster.self, text: "Downloading coupons...", symbol: .Download)
        APCouponBlaster.requestCouponsForProfileID(profileID) { (coupons, status) in
            if status.codeClass != .Successful {
                Console.commandError(NPCouponBlaster.self, command: "download")
                Console.errorLine("HTTPStatusCode \(status.rawValue)")
                completionHandler?(response: PluginResponse.error("HTTPStatusCode \(status.rawValue)", command: "download"))
                return
            }
            
            Console.info(NPCouponBlaster.self, text: "Saving coupons...")
            for coupon in coupons {
                self.hub?.cache.store(coupon, inCollection: "Reactions", forPlugin: self)
                
                Console.infoLine(coupon.id, symbol: .Add)
                Console.infoLine("           name: \(coupon.name)")
                Console.infoLine("  serial number: \(coupon.serialNumber)")
                Console.infoLine("        details: \(coupon.details)")
                Console.infoLine("          value: \(coupon.value)")
                Console.infoLine("expiration date: \(coupon.expirationDate ?? "-")")
                Console.infoLine("     claim date: \(coupon.claimDate ?? "-")")
                Console.infoLine("    redeem date: \(coupon.redeemDate ?? "-")")
            }
            
            Console.infoLine("coupons saved: \(coupons.count)")
            completionHandler?(response: PluginResponse.ok(command: "download"))
        }
    }
}
