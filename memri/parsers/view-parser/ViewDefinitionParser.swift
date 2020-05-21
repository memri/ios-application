//
//  Viewession.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/16/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

public class ViewDefinitionParser {
    let code: String
    private let lookup: (ExprLookupNode) throws -> Any
    private let execFunc: (ExprLookupNode, [Any?]) throws -> Any
    private var parsed: [ViewSelector]? = nil
    
    init(_ code:String,
           lookup: @escaping (ExprLookupNode) throws -> Any,
           execFunc: @escaping (ExprLookupNode, [Any?]) throws -> Any) {
        
        self.code = code
        self.lookup = lookup
        self.execFunc = execFunc
    }
    
    func parse() throws -> [ViewSelector] {
        if let parsed = parsed {
            return parsed
        }
        else {
            let lexer = ViewLexer(input: code)
            let parser = ViewParser(try lexer.tokenize(), lookup:lookup, execFunc:execFunc)
            parsed = try parser.parse()
            return parsed!
        }
        
    }
}
