//
// ExprNodes.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

public protocol ExprNode: CustomStringConvertible {
    func toExprString() -> String
}

public struct ExprNumberNode: ExprNode {
    public let value: Double
    public var description: String {
        "NumberNode(\(value))"
    }

    public func toExprString() -> String {
        "\(value)"
    }
}

public struct ExprNumberExpressionNode: ExprNode {
    public let exp: ExprNode
    public var description: String {
        "NumberExpressionNode(\(exp))"
    }

    public func toExprString() -> String {
        "\(exp.toExprString())"
    }
}

public struct ExprBoolNode: ExprNode {
    public let value: Bool
    public var description: String {
        "BoolNode(\(value))"
    }

    public func toExprString() -> String {
        value ? "true" : "false"
    }
}

public struct ExprStringNode: ExprNode {
    public let value: String
    public var description: String {
        "StringNode(\(value))"
    }

    public func toExprString() -> String {
        "\"\(value)\""
    }
}

public struct ExprAnyNode: ExprNode {
    public let value: Any
    public var description: String {
        "AnyNode(\(value))"
    }

    public func toExprString() -> String {
        if let item = value as? Item, let uid = item.uid.value {
            return "item(\(item.genericType), \(uid))"
        }
        else {
            debugHistory.error("Not implemented serialization for: \(value)")
            return "0"
        }
    }
}

public struct ExprNilNode: ExprNode {
    public var description: String {
        "NilNode()"
    }

    public func toExprString() -> String {
        "nil"
    }
}

public struct ExprNegationNode: ExprNode {
    public let exp: ExprNode
    public var description: String {
        "NegationNode(\(exp))"
    }

    public func toExprString() -> String {
        "!\(exp.toExprString())"
    }
}

public struct ExprVariableNode: ExprNode {
    enum ExprVariableType: String, CaseIterable {
        case reverseEdge = "_~"
        case reverseEdgeItem = "~"
        case edge = "_"
        case propertyOrItem = ""
    }

    enum ExprVariableList {
        case list
        case single
    }

    var name: String
    var type: ExprVariableType = .propertyOrItem
    var list: ExprVariableList = .single

    public init(name: String) {
        self.name = name

        // TODO: This could be optimized by moving it into the expression parser
        for varType in ExprVariableType.allCases {
            if self.name.starts(with: varType.rawValue) {
                type = varType
                self.name = String(self.name.suffix(self.name.count - varType.rawValue.count))
                break
            }
        }
    }

    public var description: String {
        "VariableNode(\(name), type:\(type), list:\(list))"
    }

    public func toExprString() -> String {
        var strName = name
        if strName == "@@DEFAULT@@" { strName = "." }

        switch type {
        case .reverseEdge: return "_~\(strName)\(list == .single ? "" : "[]")"
        case .reverseEdgeItem: return "~\(strName)\(list == .single ? "" : "[]")"
        case .edge: return "_\(strName)\(list == .single ? "" : "[]")"
        case .propertyOrItem: return "\(strName)\(list == .single ? "" : "[]")"
        }
    }
}

public struct ExprLookupNode: ExprNode {
    public let sequence: [ExprNode]
    public var description: String {
        "LookupNode(\(sequence))"
    }

    public func toExprString() -> String {
        sequence.map { node -> String in
            let value = node.toExprString()
            if value == "." && sequence.count > 1 { return "" }
            return value
        }.joined(separator: ".")
    }
}

public struct ExprBinaryOpNode: ExprNode {
    public let op: ExprOperator
    public let lhs: ExprNode
    public let rhs: ExprNode
    public var description: String {
        "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }

    public func toExprString() -> String {
        "\(lhs.toExprString()) \(op) \(rhs.toExprString())"
    }
}

public struct ExprConditionNode: ExprNode {
    public let condition: ExprNode
    public let trueExp: ExprNode
    public let falseExp: ExprNode
    public var description: String {
        "ConditionNode(condition: \(condition), trueExp: \(trueExp), falseExp: \(falseExp))"
    }

    public func toExprString() -> String {
        "\(condition.toExprString()) ? \(trueExp.toExprString()) : \(falseExp.toExprString())"
    }
}

public struct ExprStringModeNode: ExprNode {
    public let expressions: [ExprNode]
    public var description: String {
        "StringModeNode(expressions: \(expressions))"
    }

    public func toExprString() -> String {
        expressions.map { node -> String in
            if let node = node as? ExprStringNode {
                return node.value
            }
            else {
                return "{\(node.toExprString())}"
            }
        }.joined(separator: "")
    }
}

public struct ExprCallNode: ExprNode {
    public let lookup: ExprLookupNode
    public let arguments: [ExprNode]
    public var description: String {
        "CallNode(lookup: \(lookup), argument: \(arguments))"
    }

    public func toExprString() -> String {
        "\(lookup.toExprString())(\(arguments.map { $0.toExprString() }.joined(separator: ", ")))"
    }
}
