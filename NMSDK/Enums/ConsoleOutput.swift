//
//  ConsoleOutput.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 19/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

enum ConsoleOutput {
    case Information
    case Warning
    case Error
    
    var char: String {
        switch self {
        case .Information:
            return "\u{2139}"
        case .Warning:
            return "\u{26A0}"
        case .Error:
            return "\u{2757}"
        }
    }
}
