//
// CVULexer.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

public enum CVUToken {
    case Operator(CVUOperator, Int, Int)
    case Bool(Bool, Int, Int)
    case Number(Double, Int, Int)
    case String(String, Int, Int)
    case Identifier(String, Int, Int)
    case NamedIdentifier(String, Int, Int)
    case StringExpression(String, Int, Int)
    case Expression(String, Int, Int)
    case Negation(Int, Int)
    case Comma(Int, Int)
    case Color(String, Int, Int)
    case SemiColon(Int, Int)
    case Colon(Int, Int)
    case Newline(Int, Int)
    case CurlyBracketOpen(Int, Int)
    case CurlyBracketClose(Int, Int)
    case BracketOpen(Int, Int)
    case BracketClose(Int, Int)
    case Nil(Int, Int)
    case EOF

    func toParts() -> [Any] {
        var parts: [Any] = []
        switch self {
        case let .Operator(value, ln, ch): parts += ["Operator", value.rawValue, ln, ch]
        case let .Bool(value, ln, ch): parts += ["Bool", value, ln, ch]
        case let .Number(value, ln, ch): parts += ["Number", value, ln, ch]
        case let .String(value, ln, ch): parts += ["String", value, ln, ch]
        case let .Identifier(value, ln, ch): parts += ["Identifier", value, ln, ch]
        case let .NamedIdentifier(value, ln, ch): parts += ["NamedIdentifier", value, ln, ch]
        case let .StringExpression(value, ln, ch): parts += ["StringExpression", value, ln, ch]
        case let .Expression(value, ln, ch): parts += ["Expression", value, ln, ch]
        case let .Negation(ln, ch): parts += ["Negation", "", ln, ch]
        case let .Comma(ln, ch): parts += ["Comma", "", ln, ch]
        case let .Color(value, ln, ch): parts += ["Color", value, ln, ch]
        case let .SemiColon(ln, ch): parts += ["SemiColon", "", ln, ch]
        case let .Colon(ln, ch): parts += ["Colon", "", ln, ch]
        case let .Newline(ln, ch): parts += ["Newline", "", ln, ch]
        case let .CurlyBracketOpen(ln, ch): parts += ["CurlyBracketOpen", "", ln, ch]
        case let .CurlyBracketClose(ln, ch): parts += ["CurlyBracketClose", "", ln, ch]
        case let .BracketOpen(ln, ch): parts += ["BracketOpen", "", ln, ch]
        case let .BracketClose(ln, ch): parts += ["BracketClose", "", ln, ch]
        case let .Nil(ln, ch): parts += ["Nil", "", ln, ch]
        case .EOF: parts += ["EOF", ""]
        }

        return parts
    }
}

public enum CVUOperator: String {
    case ConditionAND = "AND"
    case ConditionOR = "OR"
    case ConditionEquals = "="

    var precedence: Int {
        switch self {
        case .ConditionAND: return 20
        case .ConditionOR: return 30
        case .ConditionEquals: return 35
        }
    }
}

public class CVULexer {
    let input: String

    public enum Mode: Int {
        case idle = 0
        case color = 5
        case comment = 8
        case keyword = 10
        case namedIdentifier = 11
        case number = 20
        case expression = 25
        case string = 30
        case escapedString = 35
    }

    let keywords: [String: (Int, Int) -> CVUToken] = [
        "true": { ln, ch in CVUToken.Bool(true, ln, ch) },
        "True": { ln, ch in CVUToken.Bool(true, ln, ch) },
        "false": { ln, ch in CVUToken.Bool(false, ln, ch) },
        "False": { ln, ch in CVUToken.Bool(false, ln, ch) },
        "and": { ln, ch in CVUToken.Operator(CVUOperator.ConditionAND, ln, ch) },
        "AND": { ln, ch in CVUToken.Operator(CVUOperator.ConditionAND, ln, ch) },
        "or": { ln, ch in CVUToken.Operator(CVUOperator.ConditionOR, ln, ch) },
        "OR": { ln, ch in CVUToken.Operator(CVUOperator.ConditionOR, ln, ch) },
        "equals": { ln, ch in CVUToken.Operator(CVUOperator.ConditionEquals, ln, ch) },
        "EQUALS": { ln, ch in CVUToken.Operator(CVUOperator.ConditionEquals, ln, ch) },
        "not": { ln, ch in CVUToken.Negation(ln, ch) },
        "NOT": { ln, ch in CVUToken.Negation(ln, ch) },
        "nil": { ln, ch in CVUToken.Nil(ln, ch) },
        "null": { ln, ch in CVUToken.Nil(ln, ch) },
    ]

    init(input: String) {
        self.input = input
    }

    public func tokenize() throws -> [CVUToken] {
        var tokens = [CVUToken]()

        var isMode: Mode = .idle
        var keyword = [String]()

        func addToken(_ token: CVUToken? = nil) {
            if isMode == .number {
                tokens.append(.Number(Double(keyword.joined()) ?? .nan, ln, ch))
                keyword = []
                isMode = .idle
            }
            else if isMode == .color {
                tokens.append(.Color(keyword.joined(), ln, ch))
                keyword = []
                isMode = .idle
            }
            else if isMode == .keyword || isMode == .namedIdentifier {
                let kw = keyword.joined()

                if let f = keywords[kw] { tokens.append(f(ln, ch)) }
                else if isMode == .namedIdentifier {
                    tokens.append(.NamedIdentifier(kw, ln, ch - kw.count - 1))
                }
                else { tokens.append(.Identifier(kw, ln, ch - kw.count)) }

                keyword = []
                isMode = .idle
            }

            if token != nil { tokens.append(token!) }
        }

        var ln = 0, ch = -1, startChar: Character = " "
        var lastChar: Character = " ", isStringExpression = false
        input.forEach { c in
            ch += 1

            if isMode.rawValue >= Mode.string.rawValue {
                if isMode == .escapedString {
                    keyword.append(String(c))
                    isMode = .string
                }
                else if c == "\\" {
                    isMode = .escapedString
                }
                else if isMode == .string, c == startChar {
                    if isStringExpression {
                        tokens.append(.StringExpression(keyword.joined(), ln, ch))
                    }
                    else {
                        tokens.append(.String(keyword.joined(), ln, ch))
                    }

                    keyword = []
                    isMode = .idle
                    isStringExpression = false
                    return
                }
                else {
                    keyword.append(String(c))
                }

                if c == "{" { isStringExpression = true }

                return
            }

            if isMode == .expression {
                if c == "}", lastChar == "}" {
                    if case let CVUToken.CurlyBracketOpen(ln, ch) = tokens.popLast()! {
                        _ = keyword.popLast()

                        tokens.append(.Expression(keyword.joined(), ln, ch))
                        keyword = []
                        isMode = .idle
                    }
                }
                else {
                    keyword.append(String(c))
                    lastChar = c
                }

                return
            }

            if isMode == .comment {
                if c == "/", lastChar == "*" { isMode = .idle }
                lastChar = c
                return
            }

            switch c {
            case "\n":
                addToken(.Newline(ln, ch))
                ln += 1
                ch = 0
            case "!": addToken(.Negation(ln, ch))
            case "[": addToken(.BracketOpen(ln, ch))
            case "]": addToken(.BracketClose(ln, ch))
            case "=": addToken(.Operator(CVUOperator.ConditionEquals, ln, ch))
            case ",": addToken(.Comma(ln, ch))
            case ":": addToken(.Colon(ln, ch))
            case ";": addToken(.SemiColon(ln, ch))
            case "'", "\"":
                isMode = .string
                startChar = c
            case " ", "\t": addToken()
            case "/":
                isMode = .comment // TODO: check for * after /
            case "-":
                if isMode == .idle { fallthrough }
                else { keyword.append("-") }
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                if isMode == .idle { isMode = .number }
                keyword.append(String(c))
            case "#":
                isMode = .color
            case "{":
                if lastChar == "{" {
                    isMode = .expression
                }
                else { addToken(.CurlyBracketOpen(ln, ch)) }
            case "}":
                addToken(.CurlyBracketClose(ln, ch))
            case ".":
                if isMode == .idle { isMode = .namedIdentifier }
                else if isMode == .number { keyword.append(String(c)) }
                else { fallthrough }
            default:
                if isMode == .idle { isMode = .keyword }
                keyword.append(String(c))
            }

            lastChar = c
        }

        if keyword.count > 0 {
            addToken()
        }

        if isMode == .string {
            throw CVUParseErrors.MissingQuoteClose(CVUToken.EOF)
        }
        else if isMode == .expression {
            throw CVUParseErrors.MissingExpressionClose(CVUToken.EOF)
        }
        else if isMode != .idle {
            // TODO:
            throw "Unhandled error mode: \(isMode)"
        }

        return tokens
    }
}
