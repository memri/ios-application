//
//  Parser.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

enum ExprParseErrors:Error {
    case UnexpectedToken(ExprToken)
    case UndefinedOperator(String)

    case ExpectedCharacter(Character)
    case ExpectedExpression(ExprToken)
    case ExpectedArgumentList
    case ExpectedIdentifier
    case ExpectedConditionElse
    
    case MissingQuoteClose
}

class ExprParser {
    let tokens: [ExprToken]
    var index = 0
    var lastToken:ExprToken? = nil
    var countStringModeNodes = 0

    init(_ tokens: [ExprToken]) {
        self.tokens = tokens
    }

    func peekCurrentToken() -> ExprToken {
        return index >= tokens.count
            ? ExprToken.EOF
            : tokens[index]
    }

    func popCurrentToken() -> ExprToken {
        if index >= tokens.count {
            lastToken = ExprToken.EOF
            return ExprToken.EOF
        }
        
        lastToken = tokens[index]
        index += 1
        return lastToken ?? ExprToken.EOF // Check for out of bound?
    }

    func parse() throws -> ExprNode {
        index = 0
        let result = try parseExpression()
        
        if case ExprToken.EOF = popCurrentToken() {
            return result
        }
        throw ExprParseErrors.UnexpectedToken(lastToken!)
    }

    func parseExpression() throws -> ExprNode {
        let node = try parsePrimary()
        return try parseBinaryOp(node)
    }

    func parsePrimary(_ skipOperator:Bool = false) throws -> ExprNode {
        switch (peekCurrentToken()) {
        case .Negation:
            return try parseNegation()
        case .Identifier:
            return try parseIdentifier()
        case .Number:
            return try parseNumber()
        case .String:
            return try parseString()
        case .Bool:
            return try parseBool()
        case .CurlyBracketOpen:
            return try parseCurlyBrackets()
        case .ParensOpen:
            return try parseParens()
        case .Period:
            return try parsePeriod()
        case .Operator:
            if skipOperator { fallthrough }
            else { return try parseOperator() } // start with + or -
        default:
            throw ExprParseErrors.ExpectedExpression(popCurrentToken())
        }
    }
    
    func parseLookupExpression() throws -> ExprNode {
        return try parseExpression() // TODO maybe: This could be limited to int and string
    }
    
    func parseIntExpressionComponent() throws -> ExprNode {
        return try parsePrimary(true)
    }
    
    func parseNumber() throws -> ExprNode {
        guard case let ExprToken.Number(value, _) = popCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        return ExprNumberNode(value: value)
    }

    func parseString() throws -> ExprNode {
        guard case let ExprToken.String(value, _) = popCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        return ExprStringNode(value: value)
    }

    func parseBool() throws -> ExprNode {
        guard case let ExprToken.Bool(value, _) = popCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        return ExprBoolNode(value: value)
    }

    func parsePeriod() throws -> ExprNode {
        guard case ExprToken.Period = peekCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        return try parseIdentifier(ExprVariableNode(name: "__DEFAULT__"))
    }

    func parseOperator() throws -> ExprNode {
        guard case let ExprToken.Operator(op, _) = popCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        if op == .Minus {
            let exp = try parseIntExpressionComponent()
            return ExprBinaryOpNode(op: ExprOperator.Multiplication, lhs: ExprNumberNode(value: -1), rhs: exp)
        }
        else if op == .Plus {
            let exp = try parseIntExpressionComponent()
            return ExprNumberExpressionNode(exp: exp)
        }
        else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
    }

    func parseNegation() throws -> ExprNode {
        guard case ExprToken.Negation = popCurrentToken() else {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }

        let exp = try parsePrimary()

        return ExprNegationNode(exp: exp)
    }
    
    func parseCurlyBrackets() throws -> ExprNode {
        guard case ExprToken.CurlyBracketOpen = popCurrentToken() else {
            throw ExprParseErrors.ExpectedCharacter("{")
        }
        
        return try parseStringMode()
    }

    func parseParens() throws -> ExprNode {
        guard case ExprToken.ParensOpen = popCurrentToken() else {
            throw ExprParseErrors.ExpectedCharacter("(")
        }

        let exp = try parseExpression()

        guard case ExprToken.ParensClose = popCurrentToken() else {
            throw ExprParseErrors.ExpectedCharacter(")")
        }

        return exp
    }

    func parseIdentifier(_ defaultNode:ExprVariableNode? = nil) throws -> ExprNode {
        var sequence = [ExprNode]()
        
        if let defaultNode = defaultNode { sequence.append(defaultNode) }
        else {
            guard case let ExprToken.Identifier(name, _) = popCurrentToken() else {
                throw ExprParseErrors.UnexpectedToken(lastToken!)
            }
            sequence.append(ExprVariableNode(name: name))
        }
        
        while true {
            if case ExprToken.BracketOpen = peekCurrentToken() {
                _ = popCurrentToken()
                
                let exp = try parseLookupExpression()
                sequence.append(ExprLookupNode(sequence: [exp]))
                
                guard case ExprToken.BracketClose = popCurrentToken() else {
                    throw ExprParseErrors.ExpectedCharacter("]")
                }
            }
            
            if case ExprToken.Period = peekCurrentToken() {
                _ = popCurrentToken()
            }
            else {
                break
            }
            
            if case let ExprToken.Identifier(name, _) = popCurrentToken() {
                sequence.append(ExprVariableNode(name: name))
            }
            else if case ExprToken.EOF = lastToken! {
                return ExprLookupNode(sequence: sequence)
            }
            else {
                throw ExprParseErrors.ExpectedIdentifier
            }
        }
        
        let node = ExprLookupNode(sequence: sequence)

        guard case ExprToken.ParensOpen = peekCurrentToken() else {
            return node
        }
        _ = popCurrentToken()

        var arguments = [ExprNode]()
        if case ExprToken.ParensClose = peekCurrentToken() {
            // Do nothing
        }
        else {
            while true {
                let argument = try parseExpression()
                arguments.append(argument)

                if case ExprToken.ParensClose = peekCurrentToken() {
                    break
                }

                guard case ExprToken.Comma = popCurrentToken() else {
                    throw ExprParseErrors.ExpectedArgumentList
                }
            }
        }

        _ = popCurrentToken()
        return ExprCallNode(lookup: node, arguments: arguments)
    }

    func getCurrentTokenPrecedence() throws -> Int {
        guard index < tokens.count else { return -1 }

        let nextToken = peekCurrentToken()
        guard case let ExprToken.Operator(op, _) = nextToken else {
            if case ExprToken.CurlyBracketOpen = nextToken { return 1 }
            if case ExprToken.CurlyBracketClose = nextToken { return 2 }
            
            return -1
        }
        
        return op.precedence
    }

    func parseBinaryOp(_ node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        var lhs = node
        while true {
            let tokenPrecedence = try getCurrentTokenPrecedence()
            if tokenPrecedence < exprPrecedence {
                return lhs
            }
            
            let nextToken = peekCurrentToken()
            if case let ExprToken.Operator(op, _) = nextToken, op == .ConditionElse { return lhs }
            if case ExprToken.CurlyBracketClose = nextToken { return lhs }

            guard case let ExprToken.Operator(op, _) = popCurrentToken() else {
                if case ExprToken.CurlyBracketOpen = lastToken! {
                    return try parseStringMode(lhs)
                }
                
                throw ExprParseErrors.UnexpectedToken(lastToken!)
            }
            
            if op == .ConditionStart { return try parseConditionOp(lhs) }

            var rhs = try parsePrimary()
            let nextPrecedence = try getCurrentTokenPrecedence()

            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(rhs, exprPrecedence: tokenPrecedence+1)
            }
            lhs = ExprBinaryOpNode(op: op, lhs: lhs, rhs: rhs)
        }
    }
    
    func parseConditionOp(_ conditionNode: ExprNode) throws -> ExprNode {
        let trueExp = try parseExpression()
        
        guard case let ExprToken.Operator(op, _) = popCurrentToken() else {
            throw ExprParseErrors.ExpectedConditionElse
        }
        
        if op != .ConditionElse {
            throw ExprParseErrors.ExpectedConditionElse
        }
        
        let falseExp = try parseExpression()
        
        return ExprConditionNode(condition: conditionNode, trueExp: trueExp, falseExp: falseExp)
    }
    
    func parseStringMode(_ firstNode: ExprNode? = nil) throws -> ExprNode {
        countStringModeNodes += 1
        if countStringModeNodes > 1 {
            throw ExprParseErrors.UnexpectedToken(lastToken!)
        }
        
        var expressions = [ExprNode]()
        if let firstNode = firstNode { expressions.append(firstNode) }
        
        while true {
            let nextToken = peekCurrentToken()
            if case ExprToken.EOF = nextToken { break }
            if case ExprToken.String = nextToken {
                expressions.append(try parseString())
                continue
            }
            if case ExprToken.CurlyBracketOpen = nextToken {
                _ = popCurrentToken()
            }
            
            expressions.append(try parseExpression())
            
            guard case ExprToken.CurlyBracketClose = popCurrentToken() else {
                if case ExprToken.EOF = lastToken! { break }
                throw ExprParseErrors.ExpectedCharacter("}")
            }
        }
        
        return ExprStringModeNode(expressions: expressions)
    }
}
