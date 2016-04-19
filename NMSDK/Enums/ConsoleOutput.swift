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
            return "ℹ️"
        case .Warning:
            return "⚠️"
        case .Error:
            return "⛔️"
        }
    }
}
