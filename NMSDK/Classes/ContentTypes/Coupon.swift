//
//  Coupon.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/06/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/**
 A coupon reaction.
 */
@objc
public class Coupon: NSObject {
    // MARK: Properties
    /**
     The identifier of the content.
     */
    public private (set) var id = ""
    
    /**
     The name of the coupon.
     */
    public private (set) var name = ""
    
    /**
     The details of the coupon.
     */
    public private (set) var details = ""
    
    /**
     The value of the coupon.
     */
    public private (set) var value = ""
    
    /**
     The serial number of the coupon.
     */
    public private (set) var serialNumber = ""
    
    /**
     The claim date of the coupon.
     */
    public private (set) var claimDate: NSDate?
    
    /**
     The expiration date of the coupon.
     */
    public private (set) var expirationDate: NSDate?
    
    /**
     The redeem date of the coupon.
     */
    public private (set) var redeemDate: NSDate?
    
    // MARK: Initializers
    /**
     Initializes a new `Coupon`.
     
     - parameter coupon: the source `APCoupon` instance
     */
    public init(coupon: APCoupon) {
        super.init()
        
        id = coupon.id
        name = coupon.name
        details = coupon.details
        value = coupon.value
        serialNumber = coupon.serialNumber
        claimDate = coupon.claimDate
        expirationDate = coupon.expirationDate
        redeemDate = coupon.redeemDate
    }
    
    // MARK: Properties
    /**
     Human-readable description of `Self`.
     */
    public override var description: String {
        return Console.describe(Coupon.self, properties: ("id", id), ("name", name), ("details", details), ("value", value), ("serialNumber", serialNumber), ("claimDate", claimDate), ("expirationDate", expirationDate), ("redeemDate", redeemDate))
    }
}
