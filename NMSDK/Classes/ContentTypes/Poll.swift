//
//  Poll.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMCache
import NMNet

/**
 A poll reaction.
 */
@objc
public class Poll: NSObject {
    // MARK: Properties
    /**
     The identifier of the poll.
     */
    public private (set) var id = ""
    
    /**
     The question of the poll.
     */
    public var question = ""
    
    /**
     The text of the first answer.
     */
    public var answer1 = ""
    
    /**
     The text of the second answer.
     */
    public var answer2 = ""
    
    /**
     The creation date of the poll.
     */
    public private (set) var creationDate: NSDate?
    
    /**
     The last update date of the poll.
     */
    public private (set) var lastUpdate: NSDate?
    
    // MARK: Initializers
    /**
     Initializes a new `Poll`.
     
     - parameter poll: the source `APRecipePoll` instance
     */
    public init(poll: APRecipePoll) {
        super.init()
        
        id = poll.id
        question = poll.question
        answer1 = poll.answer1
        answer2 = poll.answer2
        
        creationDate = poll.creationDate
        lastUpdate = poll.lastUpdate
    }
    
    // MARK: Properties
    /**
     Human-readable description of `Self`.
     */
    public override var description: String {
        return Console.describe(Poll.self, properties: ("id", id), ("question", question), ("answer1", answer1), ("answer2", answer2))
    }
}
