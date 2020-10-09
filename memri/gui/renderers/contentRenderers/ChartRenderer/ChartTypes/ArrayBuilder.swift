//
//  ArrayBuilder.swift
//  memri
//
//  Created by Toby Brennan on 30/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

@_functionBuilder struct ArrayBuilder<Element> {
    typealias Result = [Element]
    
    public static func buildExpression(_ element: Element) -> Result {
        [element]
    }
    public static func buildExpression(_ elementArray: [Element]) -> Result {
        elementArray
    }
    public static func buildBlock(_ elements: Result...) -> Result {
        elements.flatMap { $0 }
    }
    public static func buildIf(_ elements: Result?) -> Result {
        elements ?? []
    }
    
    public static func buildEither(first elements: Result) -> Result {
        elements
    }
    public static func buildEither(second elements: Result) -> Result {
        elements
    }
}
