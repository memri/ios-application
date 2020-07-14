//
//  Compiler.swift
//
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation
import RealmSwift

class ExprInterpreter {
	let ast: ExprNode
	let lookup: (ExprLookupNode, ViewArguments?) throws -> Any?
	let execFunc: (ExprLookupNode, [Any?], ViewArguments?) throws -> Any?
	var stack: [Any] = []

	init(_ ast: ExprNode,
		 _ lookup: @escaping (ExprLookupNode, ViewArguments?) throws -> Any?,
		 _ execFunc: @escaping (ExprLookupNode, [Any?], ViewArguments?) throws -> Any?) {
		self.ast = ast
		self.lookup = lookup
		self.execFunc = execFunc
	}

	func execute(_ args: ViewArguments? = nil) throws -> Any? {
		try execSingle(ast, args)
	}

	class func evaluateBoolean(_ x: Any?) -> Bool {
		if let x = x as? Bool { return x }
		else if let x = x as? Int { return x != 0 }
		else if let x = x as? Double { return x != 0 }
		else if let x = x as? String { return x != "" }
		else if let x = x as? ListBase { return x.count > 0 }
		else if let x = x as? [Int] { return x.count > 0 }
		else if let x = x as? [Double] { return x.count > 0 }
		else if let x = x as? [String] { return x.count > 0 }
		else if let x = x as? [Bool] { return x.count > 0 }
        else if let x = x as? [Edge] { return x.count > 0 }
        else if let x = x as? [Item] { return x.count > 0 }
        else if let x = x as? Results<Edge> { return x.count > 0 }
        else if let x = x as? Results<Item> { return x.count > 0 }
		else if x == nil { return false }
		else { return true }
	}

	class func evaluateNumber(_ x: Any?) -> Double {
		if let x = x as? Bool { return x ? 1 : 0 }
		else if let x = x as? Int { return Double(x) }
		else if let x = x as? Double { return x }
		else if let x = x as? String { return Double(x) ?? .nan }
		else if x == nil { return .nan }
		else { return .nan }
	}
	
	class func evaluateDateTime(_ x: Any?) -> Date? {
		return x as? Date
	}

	class func evaluateString(_ x: Any?, _ defaultValue: String = "") -> String {
		if let x = x as? Bool { return x ? "true" : "false" }
		else if let x = x as? Int { return String(x) }
		else if let x = x as? Double { return String(x) }
		else if let x = x as? String { return x }
        else if let x = x as? Date {
            let formatter = DateFormatter()
            formatter.dateFormat = Settings.shared.get("user/formatting/date") // "HH:mm    dd/MM/yyyy"
            return formatter.string(from: x)
        }
		else if x == nil { return defaultValue }
		else { return defaultValue }
	}

	func compare(_ a: Any?, _ b: Any?) -> Bool {
		if let a = a as? Bool { return a == IP.evaluateBoolean(b) }
		else if let a = a as? Int { return Double(a) == IP.evaluateNumber(b) }
		else if let a = a as? Double { return a == IP.evaluateNumber(b) }
		else if let a = a as? String { return a == "\(b ?? "")" }
		else if let a = a as? Item, let b = b as? Item { return a == b }
		else if a == nil { return b == nil }
		else { return false }
	}

	func execSingle(_ expr: ExprNode, _ args: ViewArguments?) throws -> Any? {
		if let expr = expr as? ExprBinaryOpNode {
			let result = try execSingle(expr.lhs, args) ?? nil

			switch expr.op {
			case .ConditionEquals:
				let otherResult = try execSingle(expr.rhs, args)
				return compare(result, otherResult)
			case .ConditionAND:
				let boolLHS = IP.evaluateBoolean(result)
				if !boolLHS { return false }
				else {
					let otherResult = try execSingle(expr.rhs, args)
					return otherResult // IP.evaluateBoolean(otherResult)
				}
			case .ConditionOR:
				let boolLHS = result // IP.evaluateBoolean(result)
				if IP.evaluateBoolean(boolLHS) { return boolLHS }
				else {
					let otherResult = try execSingle(expr.rhs, args)
					return otherResult // IP.evaluateBoolean(otherResult)
				}
			case .Division:
				let otherResult = try execSingle(expr.rhs, args)
				return IP.evaluateNumber(result) / IP.evaluateNumber(otherResult)
			case .Minus:
				let otherResult = try execSingle(expr.rhs, args)
				return IP.evaluateNumber(result) - IP.evaluateNumber(otherResult)
			case .Multiplication:
				let otherResult = try execSingle(expr.rhs, args)
				return IP.evaluateNumber(result) * IP.evaluateNumber(otherResult)
			case .Plus:
				let otherResult = try execSingle(expr.rhs, args)
				return IP.evaluateNumber(result) + IP.evaluateNumber(otherResult)
			default:
				break // this can never happen
			}
		} else if let expr = expr as? ExprConditionNode {
			if IP.evaluateBoolean(try execSingle(expr.condition, args)) {
				return try execSingle(expr.trueExp, args)
			} else {
				return try execSingle(expr.falseExp, args)
			}
		} else if let expr = expr as? ExprStringModeNode {
			var result = [String]()
			for expr in expr.expressions {
				result.append(IP.evaluateString(try execSingle(expr, args), ""))
			}
			return result.joined()
		} else if let expr = expr as? ExprNegationNode {
			let result = try execSingle(expr.exp, args)
			return !IP.evaluateBoolean(result)
		} else if let expr = expr as? ExprNumberNode { return expr.value }
		else if let expr = expr as? ExprStringNode { return expr.value }
		else if let expr = expr as? ExprBoolNode { return expr.value }
		else if let expr = expr as? ExprNumberExpressionNode {
			let result = try execSingle(expr.exp, args)
			return IP.evaluateNumber(result)
		} else if let expr = expr as? ExprLookupNode {
            let x = try lookup(expr, args)
			return x
		} else if let expr = expr as? ExprCallNode {
			let fArgs: [Any?] = try expr.arguments.map { try execSingle($0, args) }
			return try execFunc(expr.lookup, fArgs, args)
		}

		return nil
	}
}

private typealias IP = ExprInterpreter
