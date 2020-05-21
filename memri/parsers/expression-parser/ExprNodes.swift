//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public protocol ExprNode: CustomStringConvertible {
}

public struct ExprNumberNode: ExprNode {
    public let value: Double
    public var description: String {
        return "NumberNode(\(value))"
    }
}

public struct ExprNumberExpressionNode: ExprNode {
    public let exp: ExprNode
    public var description: String {
        return "NumberExpressionNode(\(exp))"
    }
}

public struct ExprBoolNode: ExprNode {
    public let value: Bool
    public var description: String {
        return "BoolNode(\(value))"
    }
}

public struct ExprStringNode: ExprNode {
    public let value: String
    public var description: String {
        return "StringNode(\(value))"
    }
}

public struct ExprNegationNode: ExprNode {
    public let exp: ExprNode
    public var description: String {
        return "NegationNode(\(exp))"
    }
}

public struct ExprVariableNode: ExprNode {
    public let name: String
    public var description: String {
        return "VariableNode(\(name))"
    }
}

public struct ExprLookupNode: ExprNode {
    public let sequence: [ExprNode]
    public var description: String {
        return "LookupNode(\(sequence))"
    }
}

public struct ExprBinaryOpNode: ExprNode {
    public let op: ExprOperator
    public let lhs: ExprNode
    public let rhs: ExprNode
    public var description: String {
        return "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }
}

public struct ExprConditionNode: ExprNode {
    public let condition: ExprNode
    public let trueExp: ExprNode
    public let falseExp: ExprNode
    public var description: String {
        return "ConditionNode(condition: \(condition), trueExp: \(trueExp), falseExp: \(falseExp))"
    }
}

public struct ExprStringModeNode: ExprNode {
    public let expressions: [ExprNode]
    public var description: String {
        return "StringModeNode(expressions: \(expressions))"
    }
}

public struct ExprCallNode: ExprNode {
    public let lookup: ExprLookupNode
    public let arguments: [ExprNode]
    public var description: String {
        return "CallNode(lookup: \(lookup), argument: \(arguments))"
    }
}
