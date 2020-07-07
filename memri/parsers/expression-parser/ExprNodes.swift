//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public protocol ExprNode: CustomStringConvertible {}

public struct ExprNumberNode: ExprNode {
	public let value: Double
	public var description: String {
		"NumberNode(\(value))"
	}
}

public struct ExprNumberExpressionNode: ExprNode {
	public let exp: ExprNode
	public var description: String {
		"NumberExpressionNode(\(exp))"
	}
}

public struct ExprBoolNode: ExprNode {
	public let value: Bool
	public var description: String {
		"BoolNode(\(value))"
	}
}

public struct ExprStringNode: ExprNode {
	public let value: String
	public var description: String {
		"StringNode(\(value))"
	}
}

public struct ExprNegationNode: ExprNode {
	public let exp: ExprNode
	public var description: String {
		"NegationNode(\(exp))"
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
}

public struct ExprLookupNode: ExprNode {
	public let sequence: [ExprNode]
	public var description: String {
		"LookupNode(\(sequence))"
	}
}

public struct ExprBinaryOpNode: ExprNode {
	public let op: ExprOperator
	public let lhs: ExprNode
	public let rhs: ExprNode
	public var description: String {
		"BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
	}
}

public struct ExprConditionNode: ExprNode {
	public let condition: ExprNode
	public let trueExp: ExprNode
	public let falseExp: ExprNode
	public var description: String {
		"ConditionNode(condition: \(condition), trueExp: \(trueExp), falseExp: \(falseExp))"
	}
}

public struct ExprStringModeNode: ExprNode {
	public let expressions: [ExprNode]
	public var description: String {
		"StringModeNode(expressions: \(expressions))"
	}
}

public struct ExprCallNode: ExprNode {
	public let lookup: ExprLookupNode
	public let arguments: [ExprNode]
	public var description: String {
		"CallNode(lookup: \(lookup), argument: \(arguments))"
	}
}
