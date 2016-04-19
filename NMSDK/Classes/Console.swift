//
//  Console.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 19/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

class Console {
    class func info(sourceClass: AnyClass, text: String, symbol: ConsoleSymbol = .Space) {
        log(sourceClass, text: text, symbol: symbol)
    }
    class func infoLine(line: String, symbol: ConsoleSymbol = .Space) {
        log(line, symbol: symbol)
    }
    
    class func warning(sourceClass: AnyClass, text: String, symbol: ConsoleSymbol = .Space) {
        log(sourceClass, text: text, type: .Warning, symbol: symbol)
    }
    class func warningLine(line: String, symbol: ConsoleSymbol = .Space) {
        log(line, type: .Warning, symbol: symbol)
    }
    
    class func error(sourceClass: AnyClass, text: String, symbol: ConsoleSymbol = .Space) {
        log(sourceClass, text: text, type: .Error, symbol: symbol)
    }
    class func errorLine(line: String, symbol: ConsoleSymbol = .Space) {
        log(line, type: .Error, symbol: symbol)
    }
    
    private class func log(sourceClass: AnyClass, text: String, type: ConsoleOutput = .Information, symbol: ConsoleSymbol = .Space) {
        if NearSDK.consoleOutput {
            print("NearItSDK")
            print(". \(type.char) \(NSStringFromClass(sourceClass))")
            print(".   \(symbol.char) \(text)")
        }
    }
    private class func log(line: String, type: ConsoleOutput = .Information, symbol: ConsoleSymbol = .Space) {
        if NearSDK.consoleOutput {
            print(".   \(symbol.char) \(line)")
        }
    }
}
