//
//  ConsoleSymbol.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 19/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

enum ConsoleSymbol {
    case Space
    case Add
    case To
    
    var char: String {
        switch self {
        case .Space:
            return " "
        case .Add:
            return "\u{2795}"
        case .To:
            return "\u{279E}"
        }
    }
}
