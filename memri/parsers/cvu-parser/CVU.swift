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
    private let lookup: (ExprLookupNode, ViewArguments) throws -> Any
    private let execFunc: (ExprLookupNode, [Any], ViewArguments) throws -> Any
    private var parsed: [CVUParsedDefinition]? = nil
    
    init(_ code:String,
           lookup: @escaping (ExprLookupNode, ViewArguments) throws -> Any,
           execFunc: @escaping (ExprLookupNode, [Any], ViewArguments) throws -> Any) {
        
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
            let parser = CVUParser(try lexer.tokenize(), lookup:lookup, execFunc:execFunc)
            parsed = try parser.parse()
            return parsed ?? []
        }
        
    }
}
