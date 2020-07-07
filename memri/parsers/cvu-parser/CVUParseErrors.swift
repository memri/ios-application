//
//  CVUParseErrors.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

enum CVUParseErrors: Error {
	case UnexpectedToken(CVUToken)
	case UnknownDefinition(CVUToken)
	case ExpectedCharacter(Character, CVUToken)
	case ExpectedDefinition(CVUToken)
	case ExpectedIdentifier(CVUToken)

	case ExpectedKey(CVUToken)
	case ExpectedString(CVUToken)

	case MissingQuoteClose(CVUToken)
	case MissingExpressionClose(CVUToken)

	func toString(_ code: String) -> String {
		var message = ""
		var parts: [Any]

		func loc(_ parts: [Any]) -> String {
			if parts[safe: 2] as? String == "" { return "at the end of the file" }
			else {
				let line = (parts[safe: 2] as? Int ?? -2) + 1
				let char = (parts[safe: 3] as? Int ?? -2) + 1
				return "at line:\(line) and character:\(char)"
			}
		}
		func displayToken(_ parts: [Any]) -> String {
			"\(parts[0])" + ((parts[1] as? String ?? "x") != "" ? "('\(parts[1])')" : "")
		}

		switch self {
		case let .UnexpectedToken(token):
			parts = token.toParts()
			message = "Unexpected \(displayToken(parts)) found \(loc(parts))"
		case let .UnknownDefinition(token):
			parts = token.toParts()
			message = "Unknown Definition type '\(displayToken(parts))' found \(loc(parts))"
		case let .ExpectedCharacter(char, token):
			parts = token.toParts()
			message = "Expected Character \(char) and found \(displayToken(parts)) instead \(loc(parts))"
		case let .ExpectedDefinition(token):
			parts = token.toParts()
			message = "Expected Definition and found \(displayToken(parts)) instead \(loc(parts))"
		case let .ExpectedIdentifier(token):
			parts = token.toParts()
			message = "Expected Identifier and found \(displayToken(parts)) instead \(loc(parts))"
		case let .ExpectedKey(token):
			parts = token.toParts()
			message = "Expected Key and found \(displayToken(parts)) instead \(loc(parts))"
		case let .ExpectedString(token):
			parts = token.toParts()
			message = "Expected String and found \(displayToken(parts)) instead \(loc(parts))"
		case let .MissingQuoteClose(token):
			parts = token.toParts()
			message = "Missing quote \(loc(parts))"
		case let .MissingExpressionClose(token):
			parts = token.toParts()
			message = "Missing expression close token '}}' \(loc(parts))"
		}

		let lines = code.split(separator: "\n")
		if let line = parts[safe: 2] as? Int {
			let ch = parts[safe: 3] as? Int ?? 0
			let beforeLines = lines[max(0, line - 10) ... max(0, line - 1)].joined(separator: "\n")
			let afterLines = lines[line ... min(line + 10, lines.count)].joined(separator: "\n")

			return message + "\n\n"
				+ beforeLines + "\n"
				+ Array(0 ..< ch - 1).map { _ in "-" }.joined() + "^\n"
				+ afterLines
		} else {
			return message
		}
	}
}
