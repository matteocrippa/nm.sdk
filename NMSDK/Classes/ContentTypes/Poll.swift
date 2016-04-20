//
//  Poll.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 15/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMNet

/// A content reaction
@objc
public class Poll: NSObject {
    /// The identifier of the poll
    public private (set) var id = ""
    
    /// The question of the poll
    public var question = ""
    
    /// The text of the poll - may be a short title
    public var text = ""
    
    /// The text of the first answer
    public var answer1 = ""
    
    /// The text of the second answer
    public var answer2 = ""
    
    init(poll: APRecipePoll) {
        super.init()
        
        id = poll.id
        question = poll.question
        text = poll.text
        answer1 = poll.answer1
        answer2 = poll.answer2
    }
}
