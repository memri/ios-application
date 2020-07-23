//
// Expression.swift
// Copyright © 2020 memri. All rights reserved.

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
        let code = ast?.toExprString() ?? self.code
        return startInStringMode ? "\"\(code)\"" : "{{\(code)}}"
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

    init(
        _ code: String,
        startInStringMode: Bool,
        lookup: @escaping (ExprLookupNode, ViewArguments?) throws -> Any?,
        execFunc: @escaping (ExprLookupNode, [Any?], ViewArguments?) throws -> Any?
    ) {
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
                    }
                    else if let obj = lookupValue as? Object {
                        let name = lastProperty.name

                        guard obj.objectSchema[name]?.type == .bool else {
                            throw "'\(name)' is not a boolean property"
                        }

                        DatabaseController.writeSync { _ in
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

    public func getTypeOfItem(_ viewArguments: ViewArguments) throws
        -> (PropertyType, Item, String) {
        if !parsed { try parse() }

        if let node = ast as? ExprLookupNode {
            var sequence = node.sequence
            if let lastProperty = sequence.popLast() as? ExprVariableNode {
                let lookupNode = ExprLookupNode(sequence: sequence)
                if let dataItem = try lookup(lookupNode, viewArguments) as? Item {
                    if let propType = dataItem.objectSchema[lastProperty.name]?.type {
                        return (propType, dataItem, lastProperty.name)
                    }
                    else if let propType = PropertyType(rawValue: 7) {
                        #warning(
                            "This requires a local version a browsable schema that describes the types of edges"
                        )
                        //                        if let item = dataItem.edge(lastProperty.name)?.item() {
                        return (propType, dataItem, lastProperty.name)
                        //                        }
                    }
                }
            }
        }

        throw "Exception: Unable to fetch type of property referenced in expression. Perhaps expression is not a pure lookup?"
    }

    func compile(_ viewArguments: ViewArguments?) throws -> Expression {
        let copy = Expression(
            code,
            startInStringMode: startInStringMode,
            lookup: lookup,
            execFunc: execFunc
        )

        if parsed, let ast = ast {
            copy.interpreter = ExprInterpreter(ast, lookup, execFunc)
            copy.parsed = true
        }
        else {
            try copy.parse()
        }

        copy.ast = try copy.interpreter?.compile(viewArguments)

        return copy
    }

    private func parse() throws {
        let lexer = ExprLexer(input: code, startInStringMode: startInStringMode)
        let parser = ExprParser(try lexer.tokenize())

        ast = try parser.parse()

        // TODO: Error handlign
        if let ast = ast {
            interpreter = ExprInterpreter(ast, lookup, execFunc)
            parsed = true
        }
        else {
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
        if T.self == Bool.self { return ExprInterpreter.evaluateBoolean(value) as? T }
        if T.self == Double.self { return ExprInterpreter.evaluateNumber(value) as? T }
        if T.self == Int.self { return ExprInterpreter.evaluateNumber(value) as? T }
        if T.self == String.self { return ExprInterpreter.evaluateString(value) as? T }
        if T.self == Date.self { return ExprInterpreter.evaluateDateTime(value) as? T }

        return value as? T
    }

    public func execute(_ args: ViewArguments? = nil) throws -> Any? {
        if !parsed { try parse() }

        return try interpreter?.execute(args)
    }

    public class func resolve<T>(
        _ object: Any?,
        _ viewArguments: ViewArguments? = nil,
        dontResolveItems: Bool = false
    ) throws -> T? {
        if var dict = object as? [String: Any?] {
            for (key, value) in dict {
                dict[key] = try resolve(value, viewArguments, dontResolveItems: dontResolveItems)
            }
            return dict as? T
        }
        else if var list = object as? [Any?] {
            for i in 0 ..< list.count {
                list[i] = try resolve(list[i], viewArguments, dontResolveItems: dontResolveItems)
            }
            return list as? T
        }
        else if let expr = object as? Expression {
            let value = try expr.execute(viewArguments)
            if dontResolveItems, let item = value as? Item {
                return ItemReference(to: item) as? T
            }
            else { return value as? T }
        }
        else {
            return object as? T
        }
    }
}
