//
//  Parser.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

enum ViewParseErrors:Error {
    case UnexpectedToken(ViewToken)
    case UnknownDefinition(ViewToken)
    case ExpectedCharacter(Character, ViewToken)
    case ExpectedDefinition(ViewToken)
    case ExpectedIdentifier(ViewToken)
    
    case ExpectedKey(ViewToken)
    case ExpectedString(ViewToken)
    
    case MissingQuoteClose(ViewToken)
    case MissingExpressionClose(ViewToken)
}

class ViewParser {
    let tokens: [ViewToken]
    var index = 0
    var lastToken:ViewToken? = nil
    
    private let lookup: (ExprLookupNode) throws -> Any
    private let execFunc: (ExprLookupNode, [Any?]) throws -> Any

    init(_ tokens: [ViewToken],
         lookup: @escaping (ExprLookupNode) throws -> Any,
         execFunc: @escaping (ExprLookupNode, [Any?]) throws -> Any) {
        
        self.tokens = tokens
        self.lookup = lookup
        self.execFunc = execFunc
    }

    func peekCurrentToken() -> ViewToken {
        return index >= tokens.count
            ? ViewToken.EOF
            : tokens[index]
    }

    func popCurrentToken() -> ViewToken {
        if index >= tokens.count {
            lastToken = ViewToken.EOF
            return ViewToken.EOF
        }
        
        lastToken = tokens[index]
        index += 1
        return lastToken! // Check for out of bound?
    }

    func parse() throws -> [ViewSelector] {
        index = 0
        var result = [ViewSelector]()

        while true {
            if case ViewToken.EOF = peekCurrentToken() { return result }
            if case ViewToken.Newline = peekCurrentToken() {
                _ = popCurrentToken()
                continue
            }

            result.append(try parseViewDSL())
        }
        
        return result
    }

    func parseViewDSL() throws -> ViewSelector {
        let node = try parsePrimary()
        
        if case ViewToken.Colon = peekCurrentToken() {
            _ = popCurrentToken()
        }
        
        return try parseDefinition(node)
    }

    func parsePrimary(_ skipOperator:Bool = false) throws -> ViewSelector {
        switch (peekCurrentToken()) {
        case .Identifier:
            return try parseIdentifierSelector()
        case .NamedIdentifier:
            return try parseNamedIdentifierSelector()
        case .BracketOpen:
            return try parseBracketsSelector()
        case .String:
            return try parseStringSelector()
        default:
            throw ViewParseErrors.ExpectedDefinition(popCurrentToken())
        }
    }
    
    func parseIdentifierSelector() throws -> ViewSelector {
        // Example: Person {
        guard case var ViewToken.Identifier(type, _, _) = popCurrentToken() else {
            throw ViewParseErrors.ExpectedIdentifier(lastToken!)
        }
        
        // Example: Person[name = 'john']
        if case ViewToken.BracketOpen = peekCurrentToken() {
            _ = popCurrentToken()
            if case ViewToken.BracketClose = peekCurrentToken() {
                _ = popCurrentToken()
                type += "[]"
            }
            else {
                // TODO
            }
        }
        
        return ViewDefinition(type: type)
    }
    
    func parseNamedIdentifierSelector() throws -> ViewSelector {
        // Example: "Some Name" {
        guard case let ViewToken.NamedIdentifier(name, _, _) = popCurrentToken() else {
            throw ViewParseErrors.UnexpectedToken(lastToken!)
        }
        
        return ViewDefinition(name: name)
    }
    
    // For JSON support
    func parseStringSelector() throws -> ViewSelector {
        guard case let ViewToken.String(value, _, _) = popCurrentToken() else {
            throw ViewParseErrors.UnexpectedToken(lastToken!)
        }
        
        if value.first == "." {
            return ViewDefinition(name:
                String(value.suffix(from: value.index(value.startIndex, offsetBy: 1))))
        }
        else if value.first == "[" {
            throw "Not supported yet" // TODO
        }
        else {
            return ViewDefinition(type: value)
        }
    }
    
    func parseBracketsSelector(_ token:ViewToken? = nil) throws -> ViewSelector {
        guard case ViewToken.BracketOpen = (token ?? popCurrentToken()) else {
            throw ViewParseErrors.ExpectedCharacter("[", lastToken!)
        }
        let typeToken = token ?? lastToken!
        
        guard case let ViewToken.Identifier(type, _, _) = popCurrentToken() else {
            throw ViewParseErrors.ExpectedIdentifier(lastToken!)
        }
        
        guard case let ViewToken.Operator(op, _, _) = popCurrentToken() else {
            throw ViewParseErrors.ExpectedCharacter("=", lastToken!)
        }
        
        if case ViewOperator.ConditionEquals = op {
            guard case let ViewToken.String(name, _, _) = popCurrentToken() else {
                throw ViewParseErrors.ExpectedString(lastToken!)
            }
            
            guard case ViewToken.BracketClose = popCurrentToken() else {
                throw ViewParseErrors.ExpectedCharacter("]", lastToken!)
            }
            
            switch type {
            case "style": return ViewStyleDefinition(name)
            case "color": return ViewColorDefinition(name)
            case "renderer": return ViewRendererDefinition(name)
            case "language": return ViewLanguageDefinition(name)
            default:
                throw ViewParseErrors.UnknownDefinition(typeToken)
            }
        }
        else {
            throw ViewParseErrors.ExpectedCharacter("=", lastToken!)
        }
    }

    func createExpression(_ code:String, startInStringMode:Bool = false) -> Expression {
        return Expression(code, startInStringMode: startInStringMode,
                          lookup: lookup, execFunc: execFunc)
    }
    
    func parseDict(_ UIElementName:String? = nil) throws -> [String:Any] {
        var dict = [String:Any]()
        var stack = [Any]()
        
        let forUIElement = knownUIElements[UIElementName ?? ""] != nil
        var lastKey:String? = nil
        var isArrayMode = false
        
        func setPropertyValue(){
            if stack.count > 0 {
                if forUIElement, let convert = specialTypedProperties[lastKey!] {
                    if !isArrayMode && stack.count == 1 {
                        dict[lastKey!] = convert(stack[0], UIElementName!)
                    }
                    else if isArrayMode || stack.count > 0 {
                        dict[lastKey!] = convert(stack, UIElementName!)
                    }
                }
                else {
                    if !isArrayMode && stack.count == 1 { dict[lastKey!] = stack[0] }
                    else if isArrayMode || stack.count > 0 { dict[lastKey!] = stack }
                }
            
                stack = []
            }
        }
        
        func addUIElement(_ type:String, _ properties: inout [String:Any]){
            var children = dict["children"] as? [UIElement] ?? [UIElement]()
            let subChildren = properties.removeValue(forKey: "children")
            children.append(UIElement(type: type,
                                      children: subChildren as? [UIElement] ?? [],
                                      properties: properties))
            dict["children"] = children
        }
        
        while true {
            switch (popCurrentToken()) {
            case let .Bool(v, _, _):
                stack.append(v)
            case .BracketOpen(_, _):
                if stack.count == 0 && lastKey != nil {
                    isArrayMode = true
                }
                else {
                    setPropertyValue()
                    
                    // SELECTOR - currently only supporting renderers
                    if let selector = try parseBracketsSelector(lastToken) as? ViewRendererDefinition {
                        var value = dict["renderDefinitions"] as? [ViewRendererDefinition] ?? [ViewRendererDefinition]()
                        value.append(selector)
                        dict["renderDefinitions"] = value
                        _ = try parseDefinition(selector)
                        lastKey = nil
                    }
                    else {
                        // TODO other defininitions
                    }
                }
            case .BracketClose(_, _):
                if isArrayMode {
                    setPropertyValue()
                    isArrayMode = false
                    lastKey = nil
                }
                else {
                    throw ViewParseErrors.UnexpectedToken(lastToken!) // We should never get here
                }
            case .CurlyBracketOpen(_, _):
                stack.append(try parseDict(lastKey!))
            case .CurlyBracketClose(_, _):
                setPropertyValue()
                if forUIElement { processCompoundProperties(&dict) }
                return dict // DONE
            case .Colon(_, _):
                throw ViewParseErrors.ExpectedKey(lastToken!)
            case let .Expression(v, _, _):
                stack.append(createExpression(v))
            case let .Color(value, _, _) :
                stack.append(Color(hex: value))
            case let .Identifier(value, _, _):
                if lastKey == nil {
                    switch peekCurrentToken() {
                        case ViewToken.Colon: _ = popCurrentToken()
                        case ViewToken.CurlyBracketOpen: _ = 1
                        default:
                            throw ViewParseErrors.ExpectedKey(lastToken!)
                    }
                    
                    if knownUIElements[value] != nil {
                        var properties:[String:Any] = [:]
                        if case ViewToken.CurlyBracketOpen = peekCurrentToken() {
                            _ = popCurrentToken()
                            properties = try parseDict(value)
                        }
                        
                        addUIElement(value, &properties)
                        continue
                    }
                    
                    lastKey = value
                }
                else if knownActions[value] != nil {
                    var options:[String:Any] = [:]
                    outerLoop: while true {
                        switch peekCurrentToken() {
                        case .Comma:
                            if isArrayMode { _ = popCurrentToken() }
                        case .CurlyBracketOpen:
                            _ = popCurrentToken()
                            options = try parseDict()
                        default:
                            break outerLoop
                        }
                    }
                    
                    stack.append(Action(
                        name: value,
                        icon: options["icon"] as? String ?? "",
                        title: options["title"] as? String ?? "",
                        showTitle: options["showTitle"] as? Bool ?? false,
                        binding: options["binding"] as? Expression,
                        hasState: options["hasState"] as? Bool ?? false,
                        opensView: options["opensView"] as? Bool ?? false,
                        color: options["color"] as? String ?? "",
                        backgroundColor: options["backgroundColor"] as? String ?? "",
                        activeColor: options["activeColor"] as? String ?? "",
                        inactiveColor: options["inactiveColor"] as? String ?? "",
                        activeBackgroundColor: options["activeBackgroundColor"] as? String ?? "",
                        inactiveBackgroundColor: options["inactiveBackgroundColor"] as? String ?? "",
                        arguments: options["arguments"] as? [Any] ?? [],
                        renderType: options["renderType"] as? String ?? "",
                        
                        hasStateValue: options["hasStateValue"] as? Bool ?? false,
                        
                    ))
                }
                else {
                    stack.append(value)
                }
            case .Newline(_, _):
                if stack.count == 0 { continue }
                else { fallthrough }
            case .Comma(_, _):
                if isArrayMode { continue } // IGNORE
                fallthrough
            case .SemiColon(_, _):
                setPropertyValue()
                lastKey = nil
            case .Nil(_, _):
                let x:String? = nil
                stack.append(x as Any)
            case let .Number(value, _, _):
                stack.append(forUIElement ? CGFloat(value) : value)
            case let .String(value, _, _):
                if !isArrayMode,
                    case ViewToken.Colon = peekCurrentToken() {
                    
                    setPropertyValue() // TODO: Is this every necessary?
                    _ = popCurrentToken()
                    lastKey = value
                }
                else if lastKey == nil { lastKey = value }
                else { stack.append(value) }
            case let .StringExpression(v, _, _):
                stack.append(createExpression(v, startInStringMode: true))
            default:
                throw ViewParseErrors.UnexpectedToken(lastToken!)
            }
        }
    }

    func parseDefinition(_ selector: ViewSelector) throws -> ViewSelector {
        while true {
            if case ViewToken.Newline = peekCurrentToken() {
                _ = popCurrentToken()
            }
            else {
                guard case ViewToken.CurlyBracketOpen = popCurrentToken() else {
                    throw ViewParseErrors.ExpectedCharacter("{", lastToken!)
                }
                
                break
            }
        }
        
        selector.parsed = try parseDict()
        return selector
    }
    
//    func parseConditionOp(_ conditionNode: ViewNode) throws -> ViewNode {
//        let trueExp = try parseViewession()
//
//        guard case let ViewToken.Operator(op, _) = popCurrentToken() else {
//            throw ViewParseErrors.ExpectedConditionElse
//        }
//
//        if op != .ConditionElse {
//            throw ViewParseErrors.ExpectedConditionElse
//        }
//
//        let falseExp = try parseViewession()
//
//        return ViewConditionNode(condition: conditionNode, trueExp: trueExp, falseExp: falseExp)
//    }
    
    // Based on keyword when its added to the dict
    // Should be loaded from the outside
    let knownActions = ["star":1, "openView":1, "openViewByName":1, "showContextPane":1, "toggleEditMode":1, "showStarred":1, "toggleFilterPanel":1, "showSharePanel":1, "addToPanel":1, "duplicate":1]
    // Only when key is this should it parse the properties
    // Should be loaded from the outside
    let knownUIElements = ["VStack":1, "HStack":1, "Image":1, "Text":1, "FlowStack":1]
    // Same as above to be converted once per dict
    let frameProperties = ["minwidth":1, "maxwidth":1, "minheight":1, "maxheight":1, "align":1]
    // Based on key when its added to the dict (only needed within rendererDefinition / UIElement)
    let specialTypedProperties = [
        "alignment": { (value:Any, type:String) -> Any in
            switch value as? String {
            case "left": return HorizontalAlignment.leading
            case "top": return VerticalAlignment.top
            case "right": return HorizontalAlignment.trailing
            case "bottom": return VerticalAlignment.bottom
            case "center":
                if type == "zstack" { return Alignment.center }
                return type == "vstack"
                    ? HorizontalAlignment.center
                    : VerticalAlignment.center
            default:
                let x:String? = nil
                return x as Any
            }
        },
        "align": { (value:Any, type:String) -> Any in
            switch value as? String{
            case "left": return Alignment.leading
            case "top": return Alignment.top
            case "right": return Alignment.trailing
            case "bottom": return Alignment.bottom
            case "center": return Alignment.center
            case "lefttop", "topleft": return Alignment.topLeading
            case "righttop", "topright": return Alignment.topTrailing
            case "leftbottom", "bottomleft": return Alignment.bottomLeading
            case "rightbottom", "bottomright": return Alignment.bottomTrailing
            default:
                let x:String? = nil
                return x as Any
            }
        },
        "textalign": { (value:Any, type:String) -> Any in
            switch value as? String {
            case "left": return TextAlignment.leading
            case "center": return TextAlignment.center
            case "right": return TextAlignment.trailing
            default:
                let x:String? = nil
                return x as Any
            }
        },
        "font": { (input:Any, type:String) -> Any in
            if var value = input as? [Any] {
                if let _ = value[0] as? CGFloat {
                    if value.count == 1 {
                        value.append(Font.Weight.regular)
                    }
                    else {
                        switch value[1] as? String {
                        case "regular": value[1] = Font.Weight.regular
                        case "bold": value[1] = Font.Weight.bold
                        case "semibold": value[1] = Font.Weight.semibold
                        case "heavy": value[1] = Font.Weight.heavy
                        case "light": value[1] = Font.Weight.light
                        case "ultralight": value[1] = Font.Weight.ultraLight
                        case "black": value[1] = Font.Weight.black
                        default: value[1] = Font.Weight.regular
                        }
                    }
                }
                return value
            }
            return input
        }
    ]
    
    func processCompoundProperties(_ dict: inout [String:Any]) {
        for (name,_) in frameProperties {
            if dict[name] != nil {

                let values:[Any] = [
                    dict["minwidth"] as Any,
                    dict["maxwidth"] as Any,
                    dict["minheight"] as Any,
                    dict["maxheight"] as Any,
                    dict["align"] as Any
                ]

                dict["minwidth"] = nil
                dict["maxwidth"] = nil
                dict["minheight"] = nil
                dict["maxheight"] = nil
                dict["align"] = nil

                dict["frame"] = values
                break
            }
        }

        if dict["cornerradius"] != nil && dict["border"] != nil {
            var value = dict["border"] as! [Any]
            value.append(dict["cornerradius"]!)

            dict["cornerborder"] = value as Any
            dict["border"] = nil
        }
    }
}
