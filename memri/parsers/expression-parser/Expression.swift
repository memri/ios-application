//
//  Expression.swift
//  memri-parser
//
//  Created by Ruben Daniels on 5/16/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Expression: CVUToString {
	let code: String
	let startInStringMode: Bool
	var lookup: (ExprLookupNode, ViewArguments?) throws -> Any?
	var execFunc: (ExprLookupNode, [Any?], ViewArguments?) throws -> Any?

	var context: MemriContext?

	private var interpreter: ExprInterpreter?
	private var parsed = false
	private var ast: ExprNode?

	func toCVUString(_: Int, _: String) -> String {
		startInStringMode ? "\"\(code)\"" : "{{\(code)}}"
	}

	public var description: String {
		toCVUString(0, "    ")
	}

	init(_ code: String, startInStringMode: Bool = false) {
		self.code = code
		self.startInStringMode = startInStringMode
		lookup = { _, _ in 1 }
		execFunc = { _, _, _ in 1 }
	}

	init(_ code: String, startInStringMode: Bool,
		 lookup: @escaping (ExprLookupNode, ViewArguments?) throws -> Any?,
		 execFunc: @escaping (ExprLookupNode, [Any?], ViewArguments?) throws -> Any?) {
		self.code = code
		self.startInStringMode = startInStringMode
		self.lookup = lookup
		self.execFunc = execFunc
	}

	public func isTrue() throws -> Bool {
		let x: Bool? = try execForReturnType()
		return x ?? false
	}

	public func toggleBool() throws {
		if !parsed { try parse() }

		if let node = ast as? ExprLookupNode {
			var sequence = node.sequence
			if let lastProperty = sequence.popLast() as? ExprVariableNode {
				let lookupNode = ExprLookupNode(sequence: sequence)
				let lookupValue = try lookup(lookupNode, nil)

				if let context = context {
					if let obj = lookupValue as? UserState {
						obj.set(lastProperty.name, !(obj.get(lastProperty.name) ?? false))
                        return
					} else if let obj = lookupValue as? Object {
                        let name = lastProperty.name
                        
                        guard obj.objectSchema[name]?.type == .bool else {
                            throw "'\(name)' is not a boolean property"
                        }
                        
						realmWrite(context.realm) { _ in
							obj[name] = !(obj[name] as? Bool ?? false)
						}
                        return
					}
					else if var obj = lookupValue as? Subscriptable {
                        obj[lastProperty.name] = !(obj[lastProperty.name] as? Bool ?? false)
                        return
					}
				}
			}
		}

		throw "Exception: Unable to toggle expression. Perhaps expression is not a pure lookup?"
	}

	public func getTypeOfItem(_ viewArguments: ViewArguments) throws -> (PropertyType, Item, String) {
		if !parsed { try parse() }

		if let node = ast as? ExprLookupNode {
			var sequence = node.sequence
			if let lastProperty = sequence.popLast() as? ExprVariableNode {
				let lookupNode = ExprLookupNode(sequence: sequence)
				if let dataItem = try lookup(lookupNode, viewArguments) as? Item {
					if let propType = dataItem.objectSchema[lastProperty.name]?.type {
						return (propType, dataItem, lastProperty.name)
					} else if let propType = PropertyType(rawValue: 7) {
						#warning("This requires a local version a browsable schema that describes the types of edges")
						//                        if let item = dataItem.edge(lastProperty.name)?.item() {
						return (propType, dataItem, lastProperty.name)
						//                        }
					}
				}
			}
		}

		throw "Exception: Unable to fetch type of property referenced in expression. Perhaps expression is not a pure lookup?"
	}

	private func parse() throws {
		let lexer = ExprLexer(input: code, startInStringMode: startInStringMode)
		let parser = ExprParser(try lexer.tokenize())
		ast = try parser.parse()

		// TODO: Error handlign
		if let ast = ast {
			interpreter = ExprInterpreter(ast, lookup, execFunc)
			parsed = true
		} else {
			throw "Exception: unexpected error occurred."
		}
	}

	public func validate() throws {
		try parse()
	}

	public func execForReturnType<T>(_: T.Type = T.self, args: ViewArguments? = nil) throws -> T? {
		if !parsed { try parse() }

		let value = try interpreter?.execute(args)

		if value == nil { return nil }
		if let value = value as? T { return value }
		if T.self == Bool.self { return ExprInterpreter.evaluateBoolean(value) as? T }
		if T.self == Double.self { return ExprInterpreter.evaluateNumber(value) as? T }
		if T.self == Int.self { return ExprInterpreter.evaluateNumber(value) as? T }
		if T.self == String.self { return ExprInterpreter.evaluateString(value) as? T }

		return nil
	}

	public func execute(_ args: ViewArguments? = nil) throws -> Any? {
		if !parsed { try parse() }

		return try interpreter?.execute(args)
	}
}
