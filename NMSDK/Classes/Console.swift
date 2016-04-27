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
    
    class func describe(sourceClass: AnyClass, properties: (String, AnyObject?)...) -> String {
        var descriptionComponents = ["\n\(ConsoleOutput.Information.char)NearSDK", "\(ConsoleSymbol.Square.char)\(NSStringFromClass(sourceClass))"]
        
        var longestPropertyName = 0
        for (key, _) in properties where key.characters.count > longestPropertyName {
            longestPropertyName = key.characters.count
        }
        
        func paddedPropertyName(name: String) -> String {
            if name.characters.count >= longestPropertyName {
                return "  \(ConsoleSymbol.Space.char)\(name):"
            }
            
            let padLength = (longestPropertyName - name.characters.count)
            return "  \(ConsoleSymbol.Space.char)".stringByPaddingToLength(padLength + 4, withString: " ", startingAtIndex: 0) + "\(name):"
        }
        
        for (name, value) in properties {
            guard let unwrappedValue = value else {
                descriptionComponents.append("\(paddedPropertyName(name)) nil")
                continue
            }
            
            descriptionComponents.append("\(paddedPropertyName(name)) \(unwrappedValue)")
        }
        
        return descriptionComponents.joinWithSeparator("\n")
    }
    
    private class func log(sourceClass: AnyClass, text: String, type: ConsoleOutput = .Information, symbol: ConsoleSymbol = .Space) {
        if NearSDK.consoleOutput {
            print("\n\(type.char)NearSDK")
            print("\(ConsoleSymbol.Square.char)\(NSStringFromClass(sourceClass))")
            print("  \(symbol.char)\(text)")
        }
    }
    private class func log(line: String, type: ConsoleOutput = .Information, symbol: ConsoleSymbol = .Space) {
        if NearSDK.consoleOutput {
            print("  \(symbol.char)\(line)")
        }
    }
}
