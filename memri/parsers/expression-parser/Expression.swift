//
//  Expression.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/16/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Expression : CVUToString {
    let code: String
    let startInStringMode: Bool
    private let lookup: (ExprLookupNode, ViewArguments) throws -> Any
    private let execFunc: (ExprLookupNode, [Any], ViewArguments) throws -> Any
    
    private var interpreter:ExprInterpreter? = nil
    private var parsed = false
    private var ast: ExprNode? = nil
    
    func toCVUString(_ depth:Int, _ tab:String) -> String {
        startInStringMode ? "\"\(code)\"" : "{{\(code)}}"
    }
    
    public var description: String {
        toCVUString(0, "    ")
    }
    
    init(_ code:String, startInStringMode:Bool = false) {
        self.code = code
        self.startInStringMode = startInStringMode
        self.lookup = {_,_ in 1 }
        self.execFunc = {_,_,_ in 1 }
    }
    
    init(_ code:String, startInStringMode:Bool,
           lookup: @escaping (ExprLookupNode, ViewArguments) throws -> Any,
           execFunc: @escaping (ExprLookupNode, [Any], ViewArguments) throws -> Any) {
        
        self.code = code
        self.startInStringMode = startInStringMode
        self.lookup = lookup
        self.execFunc = execFunc
    }
    
    public func isTrue() throws -> Bool {
        let x = try self.execute()
        return ExprInterpreter.evaluateBoolean(x)
    }
    
    public func toggleBool() throws {
        if let node = ast as? ExprLookupNode {
            var sequence = node.sequence
            if let lastProperty = sequence.popLast() as? ExprVariableNode {
                let lookupNode = ExprLookupNode(sequence: sequence)
                if let obj = try self.lookup(lookupNode, ViewArguments()) as? Object {
                    obj[lastProperty.name] =
                        !ExprInterpreter.evaluateBoolean(obj[lastProperty.name])
                    return
                }
            }
        }
            
        throw "Exception: unable to toggle expression that is not a pure lookup"
    }
    
    public func getTypeOfDataItem() throws -> (PropertyType, DataItem, String){
        // Analyze AST
        // Call lookup
        // Return information
        return (PropertyType.string, DataItem(), "")
    }
    
    private func parse() throws {
        let lexer = ExprLexer(input: code, startInStringMode: startInStringMode)
        let parser = ExprParser(try lexer.tokenize())
        ast = try parser.parse()
        interpreter = ExprInterpreter(ast!, lookup, execFunc)
        parsed = true
    }
    
    public func execute(_ args:ViewArguments? = nil) throws -> Any? {
        if !parsed { try parse() }
        
        return try interpreter?.execute(args ?? ViewArguments())
    }
}
