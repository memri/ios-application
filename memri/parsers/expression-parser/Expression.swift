//
//  Expression.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/16/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

public class Expression: CustomStringConvertible {
    let code: String
    let startInStringMode: Bool
    private let lookup: (ExprLookupNode, ViewArguments) throws -> Any
    private let execFunc: (ExprLookupNode, [Any], ViewArguments) throws -> Any
    
    private var interpreter:ExprInterpreter? = nil
    private var parsed = false
    
    public var description: String {
        return "Expression(\(code), startInStringMode:\(startInStringMode))"
    }
    
    init(_ code:String, startInStringMode:Bool,
           lookup: @escaping (ExprLookupNode, ViewArguments) throws -> Any,
           execFunc: @escaping (ExprLookupNode, [Any], ViewArguments) throws -> Any) {
        
        self.code = code
        self.startInStringMode = startInStringMode
        self.lookup = lookup
        self.execFunc = execFunc
    }
    
    private func parse() throws {
        let lexer = ExprLexer(input: code, startInStringMode: startInStringMode)
        let parser = ExprParser(try lexer.tokenize())
        interpreter = ExprInterpreter(try parser.parse(), lookup, execFunc)
        parsed = true
    }
    
    public func execute() throws -> Any? {
        if !parsed { try parse() }
        
        return try interpreter!.execute()
    }
}
