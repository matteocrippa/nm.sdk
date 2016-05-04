//
//  PollAnswer.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import NMJSON
import NMNet

/// A "poll answer" event.
@objc
public class PollAnswer: NSObject, EventSerializable {
    // MARK: Properties
    /// The identifier of the poll.
    public private (set) var pollID = ""
    
    /// The answer of the poll.
    public private (set) var answer = APRecipePollAnswer.Answer1
    
    /// The name of the plugin which should manage the answer.
    public var pluginName: String {
        return CorePlugin.Polls.name
    }
    
    /// The dictionary which holds event's data.
    public var body: JSON {
        return JSON(dictionary: ["answer": answer.rawValue, "notification-id": pollID])
    }
    
    // MARK: Initializers
    /// Initializes a new `PollAnswer`.
    ///
    /// - parameters:
    ///   - body: a JSON object which must include fields `poll-id` (`String`) and `answer` (`Int`, convertible to a `APRecipePollAnswer` case)
    /// - returns: nil if `body` does not include fields `poll-id` (`String`) and `answer` (`Int`, convertible to a `APRecipePollAnswer` case)
    required public init?(body: JSON) {
        super.init()
        
        guard let id = body.string("poll-id"), answerValue = body.int("answer"), pollAnswer = APRecipePollAnswer(rawValue: answerValue) else {
            return nil
        }
        
        pollID = id
        answer = pollAnswer
    }
    
    /// Initializes a new `PollAnswer`.
    /// 
    /// - parameters:
    ///   - poll: the identifier of the poll
    ///   - answer: the answer of the poll
    public init(poll id: String, answer pollAnswer: APRecipePollAnswer) {
        super.init()
        
        pollID = id
        answer = pollAnswer
    }
}
