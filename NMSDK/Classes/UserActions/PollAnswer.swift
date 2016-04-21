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

/// A "poll answer" event
@objc
public class PollAnswer: NSObject, EventSerializable {
    public private (set) var pollID = ""
    public private (set) var answer = APRecipePollAnswer.Answer1
    
    /// The name of the plugin which should manage the answer
    public var pluginName: String {
        return CorePlugin.Polls.name
    }
    
    /// The dictionary which holds event's data
    public var body: JSON {
        return JSON(dictionary: ["answer": answer.rawValue, "notification_id": pollID])
    }
    
    /// Returns an instance of PollAnswer or nil
    required public init?(body: JSON) {
        super.init()
        
        guard let id = body.string("poll-id"), answerValue = body.int("answer"), pollAnswer = APRecipePollAnswer(rawValue: answerValue) else {
            return nil
        }
        
        pollID = id
        answer = pollAnswer
    }
    
    /// Returns an instance of PollAnswer with a give poll identifier and an answer
    public init(poll id: String, answer pollAnswer: APRecipePollAnswer) {
        super.init()
        
        pollID = id
        answer = pollAnswer
    }
}
