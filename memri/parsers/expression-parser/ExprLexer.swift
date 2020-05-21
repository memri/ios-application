//
//  memri-parser
//
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

public enum ExprToken {
    case Operator(ExprOperator, Int)
    case Bool(Bool, Int)
    case Identifier(String, Int)
    case Number(Double, Int)
    case Negation(Int)
    case Comma(Int)
    case ParensOpen(Int)
    case ParensClose(Int)
    case CurlyBracketOpen(Int)
    case CurlyBracketClose(Int)
    case BracketOpen(Int)
    case BracketClose(Int)
    case String(String, Int)
    case Period(Int)
    case Other(String, Int)
    case EOF
}

public enum ExprOperator: String {
    case ConditionStart = "?"
    case ConditionElse = ":"
    case ConditionAND = "AND"
    case ConditionOR = "OR"
    case ConditionEquals = "="
    case Plus = "+"
    case Minus = "-"
    case Multiplication = "*"
    case Division = "/"
    
    var precedence: Int {
        switch self {
        case .ConditionStart: return 5
        case .ConditionElse: return 10
        case .ConditionAND: return 20
        case .ConditionOR: return 30
        case .ConditionEquals: return 35
        case .Plus: return 40
        case .Minus: return 40
        case .Multiplication: return 50
        case .Division: return 50
        }
    }
}

public class ExprLexer {
    let input: String
    let startInStringMode: Bool
    
    public enum Mode: Int {
        case idle = 0
        case keyword = 10
        case number = 20
        case string = 30
        case escapedString = 35
    }
    
    let keywords:[String:(Int) -> ExprToken] = [
        "true": { i in ExprToken.Bool(true, i) },
        "True": { i in ExprToken.Bool(true, i) },
        "false": { i in ExprToken.Bool(false, i) },
        "False": { i in ExprToken.Bool(false, i) },
        "and": { i in ExprToken.Operator(ExprOperator.ConditionAND, i) },
        "AND": { i in ExprToken.Operator(ExprOperator.ConditionAND, i) },
        "or": { i in ExprToken.Operator(ExprOperator.ConditionOR, i) },
        "OR": { i in ExprToken.Operator(ExprOperator.ConditionOR, i) },
        "equals": { i in ExprToken.Operator(ExprOperator.ConditionEquals, i) },
        "EQUALS": { i in ExprToken.Operator(ExprOperator.ConditionEquals, i) }
    ]
    
    init(input: String, startInStringMode: Bool = false) {
        self.input = input
        self.startInStringMode = startInStringMode
    }
    
    public func tokenize() throws -> [ExprToken] {
        var tokens = [ExprToken]()
        
        var isMode:Mode = startInStringMode ? .string : .idle
        var keyword = [String]()
        
        func addToken(_ token:ExprToken? = nil){
            if isMode == .number {
                tokens.append(.Number(Double(keyword.joined()) ?? .nan, i))
                keyword = []
                isMode = .idle
            }
            else if isMode == .keyword {
                let kw = keyword.joined()
                
                if let f = keywords[kw] { tokens.append(f(i)) }
                else { tokens.append(.Identifier(kw, i)) }
                
                keyword = []
                isMode = .idle
            }
            
            if token != nil { tokens.append(token!) }
        }
        
        var i = -1
        try input.forEach { c in
            i += 1
            
            if isMode.rawValue >= Mode.string.rawValue {
                if isMode == .string
                  && (c == "'" || c == "\"" || startInStringMode && c == "{") {
                    if keyword.count > 0 || i > 0 || c != "{" {
                        addToken(.String(keyword.joined(), i))
                    }
                    if c == "{" { addToken(.CurlyBracketOpen(i)) }
                    keyword = []
                    isMode = .idle
                    return
                }
                
                if isMode == .escapedString {
                    keyword.append(String(c))
                    isMode = .string
                }
                else if c == "\\" {
                    isMode = .escapedString
                }
                else {
                    keyword.append(String(c))
                }
                
                return
            }
            
            switch(c){
            case "*": addToken(.Operator(ExprOperator.Multiplication, i))
            case "/": addToken(.Operator(ExprOperator.Division, i))
            case "+": addToken(.Operator(ExprOperator.Plus, i))
            case "-": addToken(.Operator(ExprOperator.Minus, i))
            case "!": addToken(.Negation(i))
            case "?": addToken(.Operator(ExprOperator.ConditionStart, i))
            case ":": addToken(.Operator(ExprOperator.ConditionElse, i))
            case "(": addToken(.ParensOpen(i))
            case ")": addToken(.ParensClose(i))
            case "[": addToken(.BracketOpen(i))
            case "]": addToken(.BracketClose(i))
            case "=": addToken(.Operator(ExprOperator.ConditionEquals, i))
            case ",": addToken(.Comma(i))
            case "'", "\"":
                isMode = .string
            case ".":
                if isMode == .number { keyword.append(String(c)) }
                else { addToken(.Period(i)) }
            case " ", "\t": addToken()
            case "0","1","2","3","4","5","6","7","8","9":
                if isMode == .idle { isMode = .number }
                keyword.append(String(c))
            case "{":
                if startInStringMode {
                    addToken(.CurlyBracketOpen(i))
                    isMode = .idle
                }
                else { throw ExprParseErrors.UnexpectedToken(.CurlyBracketOpen(i)) }
            case "}":
                if startInStringMode {
                    addToken(.CurlyBracketClose(i))
                    isMode = .string
                }
                else { throw ExprParseErrors.UnexpectedToken(.CurlyBracketOpen(i)) }
            default:
                isMode = .keyword
                keyword.append(String(c))
            }
        }
        
        if keyword.count > 0 {
            addToken()
        }
        
        if startInStringMode {
            if keyword.count > 0 {
                addToken(.String(keyword.joined(), input.count - keyword.count))
            }
        }
        else if isMode == .string {
            throw ExprParseErrors.MissingQuoteClose
        }
        
        return tokens
    }
}
