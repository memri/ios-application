//
//  Compiler.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/14/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

extension String: Error {}

class ExprInterpreter {
    let ast: ExprNode
    let lookup: (ExprLookupNode) throws -> Any
    let execFunc: (ExprLookupNode, [Any?]) throws -> Any
    var stack: [Any] = []
    
    init(_ ast: ExprNode, _ lookup: @escaping (ExprLookupNode) throws -> Any,
         _ execFunc: @escaping (ExprLookupNode, [Any?]) throws -> Any) {
        
        self.ast = ast
        self.lookup = lookup
        self.execFunc = execFunc
    }
    
    func execute() throws -> Any? {
        return try execSingle(ast)
    }
    
    func evaluateBoolean(_ x:Any?) -> Bool {
        if let x = x as? Bool { return x }
        else if let x = x as? Int { return x != 0 }
        else if let x = x as? Double { return x != 0 }
        else if let x = x as? String { return x != "" }
        else if x == nil { return false }
        else { return true }
    }
    
    func evaluateNumber(_ x:Any?) -> Double {
        if let x = x as? Bool { return x ? 1 : 0 }
        else if let x = x as? Int { return Double(x) }
        else if let x = x as? Double { return x }
        else if let x = x as? String { return Double(x) ?? .nan }
        else if x == nil { return .nan }
        else { return .nan }
    }
    
    func compare(_ a:Any?, _ b:Any?) -> Bool {
        if let a = a as? Bool { return a == evaluateBoolean(b) }
        else if let a = a as? Int { return Double(a) == evaluateNumber(b) }
        else if let a = a as? Double { return a == evaluateNumber(b) }
        else if let a = a as? String { return a == "\(b ?? "")" }
        else if a == nil { return b == nil }
        else { return false }
    }
    
    func execSingle(_ expr:ExprNode) throws -> Any? {
        if let expr = expr as? ExprBinaryOpNode {
            let result = try execSingle(expr.lhs) ?? nil
            
//            print ("RESULT: \(String(describing: result)) :: OP: \(expr.op)")
            
            switch expr.op {
            case .ConditionEquals:
                let otherResult = try execSingle(expr.rhs)
                return compare(result, otherResult)
            case .ConditionAND:
                let boolLHS = evaluateBoolean(result)
                if !boolLHS { return false }
                else {
                    let otherResult = try execSingle(expr.rhs)
                    return evaluateBoolean(otherResult)
                }
            case .ConditionOR:
                let boolLHS = evaluateBoolean(result)
                if boolLHS { return true }
                else {
                    let otherResult = try execSingle(expr.rhs)
                    return evaluateBoolean(otherResult)
                }
            case .Division:
                let otherResult = try execSingle(expr.rhs)
                return evaluateNumber(result) / evaluateNumber(otherResult)
            case .Minus:
                let otherResult = try execSingle(expr.rhs)
                return evaluateNumber(result) - evaluateNumber(otherResult)
            case .Multiplication:
                let otherResult = try execSingle(expr.rhs)
                return evaluateNumber(result) * evaluateNumber(otherResult)
            case .Plus:
                let otherResult = try execSingle(expr.rhs)
                return evaluateNumber(result) + evaluateNumber(otherResult)
            default:
                break // this can never happen
            }
        }
        else if let expr = expr as? ExprConditionNode {
            if evaluateBoolean(try execSingle(expr.condition)) {
                return try execSingle(expr.trueExp)
            }
            else {
                return try execSingle(expr.falseExp)
            }
        }
        else if let expr = expr as? ExprStringModeNode {
            var result = [String]()
            for expr in expr.expressions {
                result.append(try execSingle(expr) as! String)
            }
            return result.joined()
        }
        else if let expr = expr as? ExprNegationNode {
            let result = try execSingle(expr.exp)
            return !evaluateBoolean(result)
        }
        else if let expr = expr as? ExprNumberNode { return expr.value }
        else if let expr = expr as? ExprStringNode { return expr.value }
        else if let expr = expr as? ExprBoolNode { return expr.value }
        else if let expr = expr as? ExprNumberExpressionNode {
            let result = try execSingle(expr.exp)
            return evaluateNumber(result)
        }
        else if let expr = expr as? ExprLookupNode {
            return try lookup(expr)
        }
        else if let expr = expr as? ExprCallNode {
            let args:[Any?] = try expr.arguments.map { return try execSingle($0) }
            return try execFunc(expr.lookup, args)
        }
        
        return nil
    }
}
