//
//  Viewession.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/16/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

public class CVU {
    let code: String
    let main: MemriContext
    private let lookup: (ExprLookupNode, ViewArguments) throws -> Any
    private let execFunc: (ExprLookupNode, [Any], ViewArguments) throws -> Any
    private var parsed: [CVUParsedDefinition]? = nil
    
    init(_ code:String, _ main: MemriContext,
           lookup: @escaping (ExprLookupNode, ViewArguments) throws -> Any,
           execFunc: @escaping (ExprLookupNode, [Any], ViewArguments) throws -> Any) {
        
        self.main = main
        self.code = code
        self.lookup = lookup
        self.execFunc = execFunc
    }
    
    func parse() throws -> [CVUParsedDefinition] {
        if let parsed = parsed {
            return parsed
        }
        else {
            let lexer = CVULexer(input: code)
            let parser = CVUParser(try lexer.tokenize(), main, lookup:lookup, execFunc:execFunc)
            parsed = try parser.parse()
            return parsed ?? []
        }
        
    }
}
