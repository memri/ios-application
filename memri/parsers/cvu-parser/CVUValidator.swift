//
//  CVUValidator.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class CVUValidator {
	// Based on keyword when its added to the dict
	let knownActions: [String: String] = {
		var result = [String: String]()
		for name in ActionFamily.allCases {
			result[name.rawValue.lowercased()] = name.rawValue
		}
		return result
	}()

	// Only when key is this should it parse the properties
	let knownUIElements: [String: String] = {
		var result = [String: String]()
		for name in UIElementFamily.allCases {
			result[name.rawValue.lowercased()] = name.rawValue
		}
		return result
	}()

	var warnings: [String] = []
	var errors: [String] = []

	func valueToTruncatedString(_ value: Any) -> String {
		let str = "\(value)"
		if str.count < 20 { return str }
		return str.prefix(17) + "..."
	}

	// Check syntax errors in colors
	func validateColor(_: Color) {
		// Note this is only possible inside the parser...
	}

	/// Forces parsing of expression
	func validateExpression(_ expr: Expression) {
		do { try expr.validate() }
		catch {
			errors.append(error.localizedDescription)
		}
	}

	// Check that there are no fields that are not known UIElement properties (warn)
	// Check that they have the right type (error)
	// Error if required fields are missing (e.g. text for Text, image for Image)
	func validateUIElement(_ element: UIElement) {
		func validate(_ prop: UIElementProperties, _ key: String, _ value: Any) {
			if !prop.validate(key, value) {
				errors.append("Invalid property value '\(valueToTruncatedString(value))' for '\(key)' at element \(element.type).")
			}
		}

		for (key, value) in element.properties {
			if let prop = UIElementProperties(rawValue: key) {
				if key == "frame" {
					if let list = value as? [Any?] {
						if let v = list[0] { validate(prop, "minWidth", v) }
						if let v = list[1] { validate(prop, "maxWidth", v) }
						if let v = list[2] { validate(prop, "minHeight", v) }
						if let v = list[3] { validate(prop, "maxHeight", v) }
						if let v = list[4] { validate(prop, "align", v) }
						continue
					}
				} else if key == "cornerborder" {
					if let list = value as? [Any] {
						validate(prop, "border", [list[0], list[1]])
						validate(prop, "cornerRadius", list[2])
						continue
					}
				} else {
					value.map { validate(prop, key, $0) }
					continue
				}
			}

			warnings.append("Unknown property '\(key)' for element \(element.type).")
		}

		for child in element.children {
			validateUIElement(child)
		}
	}

	// Check that there are no fields that are not known Action properties (warn)
	// Check that they have the right type (error)
	func validateAction(_ action: Action) {
		for (key, value) in action.values {
			if let prop = ActionProperties(rawValue: key) {
				if !prop.validate(key, value) {
					errors.append("Invalid property value '\(valueToTruncatedString(value ?? "null"))' for '\(key)' at action \(action.name.rawValue).")
				}
			} else {
				warnings.append("Unknown property '\(key)' for action \(action.name.rawValue).")
			}
		}
	}

	func validateDefinition(_ definition: CVUParsedDefinition) {
		func check(_ definition: CVUParsedDefinition, _ validate: (String, Any) throws -> Bool) {
            for (key, value) in definition.parsed ?? [:] {
				if value is Expression { continue }

				do {
					try value.map {
						if !(try validate(key, $0)) {
							errors.append("Invalid property value '\(valueToTruncatedString($0))' for '\(key)' at definition \(definition.selector ?? "").")
						}
					}
				} catch {
					warnings.append("Unknown property '\(key)' for definition \(definition.selector ?? "").")
				}
			}
		}

		if definition is CVUParsedSessionsDefinition {
			check(definition) { key, value in
				switch key {
				case "currentSessionIndex": return value is Double
				case "sessionDefinitions": return value is [CVUParsedSessionDefinition]
				default: throw "Unknown"
				}
			}
		} else if definition is CVUParsedSessionDefinition {
			check(definition) { key, value in
				switch key {
				case "name": return value is String
				case "currentViewIndex": return value is Double
				case "viewDefinitions": return value is [CVUParsedViewDefinition]
				case "editMode", "showFilterPanel", "showContextPane": return value is Bool
				case "screenshot": return value is File
				default: throw "Unknown"
				}
			}
		} else if definition is CVUParsedViewDefinition {
			check(definition) { key, value in
				switch key {
				case "name", "emptyResultText", "title", "subTitle", "filterText",
					 "activeRenderer", "defaultRenderer", "backTitle", "searchHint":
					return value is String
				case "userState": return value is UserState
				case "datasourceDefinition": return value is CVUParsedDatasourceDefinition
				case "viewArguments": return value is ViewArguments
				case "showLabels": return value is Bool
				case "actionButton", "editActionButton":
					if let value = value as? Action { validateAction(value) }
					else { return false }
				case "sortFields":
					if let value = value as? [Any] { return value is [String] }
					else { return value is String }
				case "editButtons", "filterButtons", "actionItems",
					 "navigateItems", "contextButtons":
					if let value = value as? [Any] {
						for action in value {
							if let action = action as? Action { validateAction(action) }
							else {
								errors.append("Expected action definition but found '\(valueToTruncatedString(action))' at property '\(key)' of \(definition.selector ?? "")")
							}
						}
					} else if let action = value as? Action { validateAction(action) }
					else { return false }
				case "include":
					if let value = value as? [Any] {
						return value[0] is String && value[1] is [String: Any]
					} else { return value is String }
				case "renderDefinitions": return value is [CVUParsedRendererDefinition]
				default: throw "Unknown"
				}

				return true
			}
		} else if definition is CVUParsedRendererDefinition {
			// TODO: support all the renderer properties
			//            check(definition) { (key, value) in
			//                if (definition.parsed[key] as? [String:Any?])?["children"] != nil
			//                    && !definition.parsed["groups"]?.contains(key) .. also need to check the schema of the thing it renders too complex for now {
			//                    return false
			//                }
			//                return true
			//            }

			if let children = definition.parsed?["children"] as? [Any] {
				for child in children {
					if let element = child as? UIElement { validateUIElement(element) }
					else {
						errors.append("Expected element definition but found '\(valueToTruncatedString(child))' in \(definition.selector ?? "")")
					}
				}
			}
		}
		// TODO: Color, Style, Language
	}

	func debug() {
		if errors.count > 0 {
			print("ERRORS:\n" + errors.joined(separator: "\n"))
		}
		if warnings.count > 0 {
			print("WARNINGS:\n" + warnings.joined(separator: "\n"))
		} else if errors.count == 0 {
			print("Nothing to report")
		}
	}

	func validate(_ definitions: [CVUParsedDefinition]) -> Bool {
		warnings = []
		errors = []

		for def in definitions {
			validateDefinition(def)
		}

		return errors.count == 0
	}
}
