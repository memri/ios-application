//
//  Parser.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class CVUParser {
    let main: Main
    let tokens: [CVUToken]
    var index = 0
    var lastToken:CVUToken? = nil
    
    private let lookup: (ExprLookupNode, ViewArguments) throws -> Any?
    private let execFunc: (ExprLookupNode, [Any], ViewArguments) throws -> Any?

    init(_ tokens: [CVUToken], _ main:Main,
         lookup: @escaping (ExprLookupNode, ViewArguments) throws -> Any?,
         execFunc: @escaping (ExprLookupNode, [Any], ViewArguments) throws -> Any?) {
        
        self.main = main
        self.tokens = tokens
        self.lookup = lookup
        self.execFunc = execFunc
    }

    func peekCurrentToken() -> CVUToken {
        return index >= tokens.count
            ? CVUToken.EOF
            : tokens[index]
    }

    func popCurrentToken() -> CVUToken {
        if index >= tokens.count {
            lastToken = CVUToken.EOF
            return CVUToken.EOF
        }
        
        lastToken = tokens[index]
        index += 1
        return lastToken! // Check for out of bound?
    }

    func parse() throws -> [CVUParsedDefinition] {
        index = 0
        var result = [CVUParsedDefinition]()

        while true {
            if case CVUToken.EOF = peekCurrentToken() { return result }
            if case CVUToken.Newline = peekCurrentToken() {
                _ = popCurrentToken()
                continue
            }

            var dsl = try parseViewDSL()
            if dsl["sessions"] != nil {
                dsl = CVUParsedSessionsDefinition(dsl.selector ?? "", name: dsl.name,
                                             domain: dsl.domain, parsed: dsl.parsed)
            }
            else if dsl["views"] != nil {
                dsl = CVUParsedSessionDefinition(dsl.selector ?? "", name: dsl.name,
                                             domain: dsl.domain, parsed: dsl.parsed)
            }
            
            result.append(dsl)
        }
        
        return result
    }

    func parseViewDSL() throws -> CVUParsedDefinition {
        let node = try parsePrimary()
        
        if case CVUToken.Colon = peekCurrentToken() {
            _ = popCurrentToken()
        }
        
        return try parseDefinition(node)
    }

    func parsePrimary(_ skipOperator:Bool = false) throws -> CVUParsedDefinition {
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
            throw CVUParseErrors.ExpectedDefinition(popCurrentToken())
        }
    }
    
    func parseIdentifierSelector() throws -> CVUParsedDefinition {
        // Example: Person {
        guard case var CVUToken.Identifier(type, _, _) = popCurrentToken() else {
            throw CVUParseErrors.ExpectedIdentifier(lastToken!)
        }
        
        // Example: Person[name = 'john']
        if case CVUToken.BracketOpen = peekCurrentToken() {
            _ = popCurrentToken()
            if case CVUToken.BracketClose = peekCurrentToken() {
                _ = popCurrentToken()
                type += "[]"
            }
            else {
                // TODO
            }
        }
        
        return CVUParsedViewDefinition(type, type: type)
    }
    
    func parseNamedIdentifierSelector() throws -> CVUParsedDefinition {
        // Example: "Some Name" {
        guard case let CVUToken.NamedIdentifier(name, _, _) = popCurrentToken() else {
            throw CVUParseErrors.UnexpectedToken(lastToken!)
        }
        
        return CVUParsedViewDefinition(".\(name)", name: name)
    }
    
    // For JSON support
    func parseStringSelector() throws -> CVUParsedDefinition {
        guard case let CVUToken.String(value, _, _) = popCurrentToken() else {
            throw CVUParseErrors.UnexpectedToken(lastToken!)
        }
        
        if value.first == "." {
            return CVUParsedViewDefinition(value, name:
                String(value.suffix(from: value.index(value.startIndex, offsetBy: 1))))
        }
        else if value.first == "[" {
            throw "Not supported yet" // TODO
        }
        else {
            return CVUParsedViewDefinition(value, type: value)
        }
    }
    
    func parseBracketsSelector(_ token:CVUToken? = nil) throws -> CVUParsedDefinition {
        guard case CVUToken.BracketOpen = (token ?? popCurrentToken()) else {
            throw CVUParseErrors.ExpectedCharacter("[", lastToken!)
        }
        let typeToken = token ?? lastToken!
        
        guard case let CVUToken.Identifier(type, _, _) = popCurrentToken() else {
            throw CVUParseErrors.ExpectedIdentifier(lastToken!)
        }
        
        // TODO Only allow inside other definition
        if ["session", "view"].contains(type), case CVUToken.BracketClose = peekCurrentToken() {
            _ = popCurrentToken()
            switch type {
            case "session": return CVUParsedSessionDefinition("[session]")
            case "view": return CVUParsedViewDefinition("[view]")
            default: _ = 1 // Can never get here
            }
        }
        
        guard case let CVUToken.Operator(op, _, _) = popCurrentToken() else {
            throw CVUParseErrors.ExpectedCharacter("=", lastToken!)
        }
        
        if case CVUOperator.ConditionEquals = op {
            var name:String
            
            if case let CVUToken.String(nm, _, _) = popCurrentToken() { name = nm }
            else if case let CVUToken.Identifier(nm, _, _) = lastToken! { name = nm }
            else {
                throw CVUParseErrors.ExpectedString(lastToken!)
            }
            
            guard case CVUToken.BracketClose = popCurrentToken() else {
                throw CVUParseErrors.ExpectedCharacter("]", lastToken!)
            }
            
            switch type {
            case "sessions": return CVUParsedSessionsDefinition("[sessions = \(name)]", name:name)
            case "session": return CVUParsedSessionDefinition("[session = \(name)]", name:name)
            case "view": return CVUParsedViewDefinition("[view = \(name)]", name:name)
            case "style": return CVUParsedStyleDefinition("[style = \(name)]", name:name)
            case "datasource": return CVUParsedDatasourceDefinition("[datasource = \(name)]", name:name)
            case "color": return CVUParsedColorDefinition("[color = \(name)]", name:name)
            case "renderer": return CVUParsedRendererDefinition("[renderer = \(name)]", name:name)
            case "language": return CVUParsedLanguageDefinition("[language = \(name)]", name:name)
            default:
                throw CVUParseErrors.UnknownDefinition(typeToken)
            }
        }
        else {
            throw CVUParseErrors.ExpectedCharacter("=", lastToken!)
        }
    }

    func createExpression(_ code:String, startInStringMode:Bool = false) -> Expression {
        return Expression(code, startInStringMode: startInStringMode,
                          lookup: lookup, execFunc: execFunc)
    }
    
    func parseDict(_ uiElementName:String? = nil) throws -> [String:Any?] {
        var dict = [String:Any?]()
        var stack = [Any?]()
        
        let forUIElement = knownUIElements[uiElementName?.lowercased() ?? ""] != nil
        var lastKey:String? = nil
        var isArrayMode = false
        
        func setPropertyValue(){
            if stack.count > 0 {
                if forUIElement, let convert = specialTypedProperties[lastKey!] {
                    if !isArrayMode && stack.count == 1 {
                        dict[lastKey!] = convert(stack[0], uiElementName!)
                    }
                    else if isArrayMode || stack.count > 0 {
                        dict[lastKey!] = convert(stack, uiElementName!)
                    }
                }
                else {
                    if !isArrayMode && stack.count == 1 { dict[lastKey!] = stack[0] }
                    else if isArrayMode || stack.count > 0 { dict[lastKey!] = stack }
                }
            
                stack = []
            }
        }
        
        func addUIElement(_ type:UIElementFamily, _ properties: inout [String:Any?]){
            var children = dict["children"] as? [UIElement] ?? [UIElement]()
            let subChildren = properties.removeValue(forKey: "children")
            children.append(UIElement(type,
                                      children: subChildren as? [UIElement] ?? [],
                                      properties: properties))
            dict["children"] = children
        }
        
        while true {
//            print(peekCurrentToken())
            switch (popCurrentToken()) {
            case let .Bool(v, _, _):
                stack.append(v)
            case .BracketOpen(_, _):
                if stack.count == 0 && lastKey != nil {
                    isArrayMode = true
                }
                else {
                    setPropertyValue()
                    
                    // SELECTOR - currently not yet implemented: style, color, language
                    // TODO remove code duplication
                    let selector = try parseBracketsSelector(lastToken)
                    if let selector = selector as? CVUParsedRendererDefinition {
                        var value = dict["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [CVUParsedRendererDefinition]()
                        value.append(selector)
                        dict["renderDefinitions"] = value
                        _ = try parseDefinition(selector)
                        lastKey = nil
                    }
                    else if let selector = selector as? CVUParsedSessionDefinition {
                        var value = dict["sessionDefinitions"] as? [CVUParsedSessionDefinition] ?? [CVUParsedSessionDefinition]()
                        value.append(selector)
                        dict["sessionDefinitions"] = value
                        _ = try parseDefinition(selector)
                        lastKey = nil
                    }
                    else if let selector = selector as? CVUParsedViewDefinition {
                        var value = dict["viewDefinitions"] as? [CVUParsedViewDefinition] ?? [CVUParsedViewDefinition]()
                        value.append(selector)
                        dict["viewDefinitions"] = value
                        _ = try parseDefinition(selector)
                        lastKey = nil
                    }
                    else if let selector = selector as? CVUParsedDatasourceDefinition {
                        dict["datasourceDefinition"] = selector
                        _ = try parseDefinition(selector)
                        lastKey = nil
                    }
                    else {
                        // TODO other defininitions
                        print("this inline definition is not yet supported")
                    }
                }
            case .BracketClose(_, _):
                if isArrayMode {
                    setPropertyValue()
                    isArrayMode = false
                    lastKey = nil
                }
                else {
                    throw CVUParseErrors.UnexpectedToken(lastToken!) // We should never get here
                }
            case .CurlyBracketOpen(_, _):
                stack.append(try parseDict(lastKey!))
            case .CurlyBracketClose(_, _):
                setPropertyValue()
                if forUIElement { processCompoundProperties(&dict) }
                return dict // DONE
            case .Colon(_, _):
                throw CVUParseErrors.ExpectedKey(lastToken!)
            case let .Expression(v, _, _):
                stack.append(createExpression(v))
            case let .Color(value, _, _) :
                stack.append(Color(hex: value))
            case let .Identifier(value, _, _):
                if lastKey == nil {
                    let nextToken = peekCurrentToken()
                    if case CVUToken.Colon = nextToken {
                        _ = popCurrentToken()
                        lastKey = value
                    }
                    else {
                        if let type = knownUIElements[value.lowercased()] {
                            var properties:[String:Any?] = [:]
                            if case CVUToken.CurlyBracketOpen = peekCurrentToken() {
                                _ = popCurrentToken()
                                properties = try parseDict(value)
                            }
                            
                            addUIElement(type, &properties)
                            continue
                        }
                        else if value.lowercased() == "datasource" {
                            
                        }
                        else if case CVUToken.CurlyBracketOpen = nextToken { }
                        else {
                            throw CVUParseErrors.ExpectedKey(lastToken!)
                        }
                    }
                    
                    lastKey = value
                }
                else if let name = knownActions[value.lowercased()] {
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
                    
                    let arguments = options.removeValue(forKey: "arguments") as? [String:Any] ?? [:]
                    if let actionFamily = ActionFamily(rawValue: name) {
                        let ActionType = ActionFamily.getType(actionFamily)()
                        stack.append(ActionType.init(main, arguments:arguments, values:options))
                    }
                    else {
                        // TODO ERROR REPORTING
                    }
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
                    case CVUToken.Colon = peekCurrentToken() {
                    
                    setPropertyValue() // TODO: Is this every necessary?
                    _ = popCurrentToken()
                    lastKey = value
                }
                else if lastKey == nil { lastKey = value }
                else { stack.append(value) }
            case let .StringExpression(v, _, _):
                stack.append(createExpression(v, startInStringMode: true))
            default:
                throw CVUParseErrors.UnexpectedToken(lastToken!)
            }
        }
    }

    func parseDefinition(_ selector: CVUParsedDefinition) throws -> CVUParsedDefinition {
        while true {
            if case CVUToken.Newline = peekCurrentToken() {
                _ = popCurrentToken()
            }
            else {
                guard case CVUToken.CurlyBracketOpen = popCurrentToken() else {
                    throw CVUParseErrors.ExpectedCharacter("{", lastToken!)
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
    let knownActions:[String:String] = {
        var result = [String:String]()
        for name in ActionFamily.allCases {
            result[name.rawValue.lowercased()] = name.rawValue
        }
        return result
    }()
    // Only when key is this should it parse the properties
    let knownUIElements:[String:UIElementFamily] = {
        var result = [String:UIElementFamily]()
        for name in UIElementFamily.allCases {
            result[name.rawValue.lowercased()] = name
        }
        return result
    }()
        
    // Same as above to be converted once per dict
    let frameProperties = ["minWidth":1, "maxWidth":1, "minHeight":1, "maxHeight":1, "align":1]
    // Based on key when its added to the dict (only needed within rendererDefinition / UIElement)
    let specialTypedProperties = [
        "alignment": { (value:Any?, type:String) -> Any? in
            switch value as? String {
            case "left": return HorizontalAlignment.leading
            case "top": return VerticalAlignment.top
            case "right": return HorizontalAlignment.trailing
            case "bottom": return VerticalAlignment.bottom
            case "center":
                if type == "ZStack" { return Alignment.center }
                return type == "VStack"
                    ? HorizontalAlignment.center
                    : VerticalAlignment.center
            default:
                return value // TODO Test if this crashes the view renderer
            }
        },
        "align": { (value:Any?, type:String) -> Any? in
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
                return value // TODO Test if this crashes the view renderer
            }
        },
        "textAlign": { (value:Any?, type:String) -> Any? in
            switch value as? String {
            case "left": return TextAlignment.leading
            case "center": return TextAlignment.center
            case "right": return TextAlignment.trailing
            default:
                return value // TODO Test if this crashes the view renderer
            }
        },
        "font": { (input:Any?, type:String) -> Any? in
            if var value = input as? [Any?] {
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
                        default:
                            // TODO Warn user
                            value[1] = Font.Weight.regular
                        }
                    }
                }
                return value
            }
            // TODO Warn user
            return input
        }
    ]
    
    func processCompoundProperties(_ dict: inout [String:Any?]) {
        for (name,_) in frameProperties {
            if dict[name] != nil {

                let values:[Any?] = [
                    dict["minWidth"] as Any?,
                    dict["maxWidth"] as Any?,
                    dict["minHeight"] as Any?,
                    dict["maxHeight"] as Any?,
                    dict["align"] as Any?
                ]

                dict["minWidth"] = nil
                dict["maxWidth"] = nil
                dict["minHeight"] = nil
                dict["maxHeight"] = nil
                dict["align"] = nil

                dict["frame"] = values
                break
            }
        }

        if dict["cornerRadius"] != nil && dict["border"] != nil {
            var value = dict["border"] as? [Any?] ?? []
            value.append(dict["cornerRadius"] ?? 0)

            dict["cornerborder"] = value as Any?
            dict["border"] = nil
        }
    }
}
