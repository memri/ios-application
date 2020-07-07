import Combine
import Foundation
import RealmSwift
import SwiftUI

// TODO: Move to integrate with some of the sessions features so that Sessions can be nested
public class Views {
	///
	let languages = Languages()
	///
	var context: MemriContext?

	private var recursionCounter = 0
	private var realm: Realm

	init(_ rlm: Realm) {
		realm = rlm
	}

	public func load(_ mn: MemriContext, _ callback: () throws -> Void) throws {
		// Store context for use within createCascadingView)
		context = mn

		try setCurrentLanguage(context?.settings.get("user/language") ?? "English")

		// Done
		try callback()
	}

	// TODO: refactor when implementing settings UI call this when changing the language
	public func setCurrentLanguage(_ language: String) throws {
		languages.currentLanguage = language

		let definitions = try fetchDefinitions(type: "language")
			.compactMap { try self.parseDefinition($0) }

		languages.load(definitions)
	}

	// TODO: Refactor: distinguish between views and sessions
	// Load the default views from the package
	public func install() throws {
		guard let context = context else {
			throw "Context is not set"
		}

		let code = getDefaultViewContents()

		do {
			let cvu = CVU(code, context, lookup: lookupValueOfVariables, execFunc: executeFunction)
			let parsedDefinitions = try cvu.parse() // TODO: this could be optimized

			let validator = CVUValidator()
			if !validator.validate(parsedDefinitions) {
				validator.debug()
				if validator.warnings.count > 0 {
					for message in validator.warnings { debugHistory.warn(message) }
				}
				if validator.errors.count > 0 {
					for message in validator.errors { debugHistory.error(message) }
					throw "Exception: Errors in default view set:    \n\(validator.errors.joined(separator: "\n    "))"
				}
			}

			// Loop over lookup table with named views
			for def in parsedDefinitions {
				var values: [String: Any?] = [
					"selector": def.selector,
					"name": def.name,
					"domain": "defaults",
					"definition": def.description,
				]

				guard let selector = def.selector else {
					throw "Exception: selector on parsed CVU is not defined"
				}

				if def is CVUParsedViewDefinition {
					values["type"] = "view"
					//                    values["query"] = (def as! CVUParsedViewDefinition)?.query ?? ""
				} else if def is CVUParsedRendererDefinition { values["type"] = "renderer" }
				else if def is CVUParsedDatasourceDefinition { values["type"] = "datasource" }
				else if def is CVUParsedStyleDefinition { values["type"] = "style" }
				else if def is CVUParsedColorDefinition { values["type"] = "color" }
				else if def is CVUParsedLanguageDefinition { values["type"] = "language" }
				else if def is CVUParsedSessionsDefinition { values["type"] = "sessions" }
				else if def is CVUParsedSessionDefinition { values["type"] = "session" }
				else { throw "Exception: unknown definition" }

				// Store definition
				_ = try Cache.createItem(CVUStoredDefinition.self, values: values,
										 unique: "selector = '\(selector)' and domain = 'defaults'")
			}
		} catch {
			if let error = error as? CVUParseErrors {
				// TODO: Fatal error handling
				throw "Parse Error: \(error.toString(code))"
			} else {
				throw error
			}
		}
	}

	public class func formatDate(_ date: Date?) -> String {
		let showAgoDate: Bool? = Settings.get("user/general/gui/showDateAgo")

		if let date = date {
			// Compare against 36 hours ago
			if showAgoDate == false || date.timeIntervalSince(Date(timeIntervalSinceNow: -129_600)) < 0 {
				let dateFormatter = DateFormatter()

				dateFormatter.dateFormat = Settings.get("user/formatting/date") ?? "yyyy/MM/dd HH:mm"
				dateFormatter.locale = Locale(identifier: "en_US")
				dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

				return dateFormatter.string(from: date)
			} else {
				return date.timestampString ?? ""
			}
		} else {
			return "never"
		}
	}

	public class func formatDateSinceCreated(_ date: Date?) -> String {
		if let date = date {
			return date.timeDelta ?? ""
		} else {
			return "never"
		}
	}

	func resolveEdge(_: Edge) throws -> Item {
		// TODO: REFACTOR: implement
		throw "not implemented"
	}

	func getGlobalReference(_ name: String, viewArguments: ViewArguments?) throws -> Any? {
		// Fetch the value of the right property on the right object
		switch name {
		case "setting":
			let f = { (args: [Any?]?) -> Any? in // (value:String) -> Any? in
				#warning("Toby, how can we re-architect this?")
				if let value = args?[0] as? String {
					if let x = Settings.get(value, type: Double.self) { return x }
					else if let x = Settings.get(value, type: Int.self) { return x }
					else if let x = Settings.get(value, type: String.self) { return x }
					else if let x = Settings.get(value, type: Bool.self) { return x }
				}
				return ""
			}
			#warning("@Ruben: I don't quite understand what this is doing... it returns a function, is it meant to return the result instead?? If so should be `return f()`")
			return f
		case "me": return realm.objects(Person.self).filter("ANY allEdges.type = 'me'").first
		case "context": return context
		case "sessions": return context?.sessions
		case "currentSession": fallthrough
		case "session":
			return context?.currentSession
		case "view": return context?.cascadingView
		case "dataItem":
			if let itemRef: Item = viewArguments?.get(".") {
				return itemRef
			} else if let item = context?.cascadingView?.resultSet.singletonItem {
				return item
			} else {
				throw "Exception: Missing object for property getter"
			}
		default:
			if let value: Any = viewArguments?.get(name) { return value }
			throw "Exception: Unknown object for property getter: \(name)"
		}
	}

	func lookupValueOfVariables(lookup: ExprLookupNode, viewArguments: ViewArguments?) throws -> Any? {
		let x = try lookupValueOfVariables(
			lookup: lookup,
			viewArguments: viewArguments,
			isFunction: false
		)
		return x
	}

	func lookupValueOfVariables(lookup: ExprLookupNode,
								viewArguments: ViewArguments?,
								isFunction: Bool = false) throws -> Any? {
		var value: Any?
		var first = true

		// TODO: support language lookup: {$name}
		// TODO: support .label.~label to get all items that share at least one label with dataItem

		recursionCounter += 1

		if recursionCounter > 4 {
			recursionCounter = 0
			throw "Exception: Recursion detected while expanding variable \(lookup)"
		}

		var i = 0
		for node in lookup.sequence {
			i += 1

			if let node = node as? ExprVariableNode {
				if first {
					// TODO: move to CVU validator??
					if node.list == .list || node.type != .propertyOrItem {
						throw "Unexpected edge lookup. No source specified"
					}

					let name = node.name == "@@DEFAULT@@" ? "dataItem" : node.name
					do {
						value = try getGlobalReference(name, viewArguments: viewArguments)
						first = false

						if isFunction, i == lookup.sequence.count {
							break
						}

					} catch {
						recursionCounter = 0
						throw error
					}
				} else if isFunction, i == lookup.sequence.count {
					value = (value as? Item)?.functions[node.name]
					if value == nil {
						// TODO: parse [blah]
						recursionCounter = 0
						let message = "Exception: Invalid function call. Could not find"
						throw "\(message) \(node.name)"
					}
					break
				} else if let dataItem = value as? Item {
					switch node.name {
					case "genericType": value = dataItem.genericType
					default:
						if node.list == .single {
							switch node.type {
							case .reverseEdge: value = dataItem.reverseEdge(node.name)
							case .reverseEdgeItem: value = dataItem.reverseEdge(node.name)?.source()
							case .edge: value = dataItem.edge(node.name)
							case .propertyOrItem: value = dataItem.get(node.name)
							}
						} else {
							switch node.type {
							case .reverseEdge: value = dataItem.reverseEdges(node.name)
							case .reverseEdgeItem: value = dataItem.reverseEdges(node.name)?.sources()
							case .edge: value = dataItem.edges(node.name)
							case .propertyOrItem: value = dataItem.edges(node.name)?.items()
							}
						}
					}
				} else if let v = value as? String {
					switch node.name {
					case "uppercased": value = v.uppercased()
					case "lowercased": value = v.lowercased()
					case "camelCaseToWords": value = v.camelCaseToWords()
					case "plural": value = v + "s" // TODO:
					case "firstUppercased": value = v.capitalizingFirst()
					default:
						// TODO: Warn
						debugHistory.warn("Could not find property \(node.name) on string")
					}
				} else if let v = value as? Edge {
					switch node.name {
					case "source": value = v.source()
					case "target": value = v.target()
					case "item": value = v.item()
					case "label": value = v.label
					case "type": value = v.type
					case "sequence": value = v.sequence
					default:
						// TODO: Warn
						debugHistory.warn("Could not find property \(node.name) on edge")
					}
				} else if let v = value as? RealmSwift.Results<Edge> {
					switch node.name {
					case "count": value = v.count
					case "first": value = v.first
					case "last": value = v.last
					//                        case "sum": value = v.sum
					case "min": value = v.min
					case "max": value = v.max
					case "items": value = v.items()
					default:
						// TODO: Warn
						debugHistory.warn("Could not find property \(node.name) on list of edges")
					}
				} else if let v = value as? RealmSwift.ListBase {
					switch node.name {
					case "count": value = v.count
					default:
						// TODO: Warn
						debugHistory.warn("Could not find property \(node.name) on list")
					}
				} else if let v = value as? MemriContext {
					value = v[node.name]
				} else if let v = value as? UserState {
					value = v.get(node.name)
				} else if let v = value as? CascadingView {
					value = v[node.name]
				} else if let v = value as? CascadingDatasource {
					value = v[node.name]
				}
				// CascadingRenderer??
				else if let v = value as? Object {
					if v.objectSchema[node.name] == nil {
						// TODO: error handling
						recursionCounter = 0
						throw "No variable with name \(node.name)"
					} else {
						value = v[node.name] // How to handle errors?
					}
				}
			}
			// .addresses[primary = true] || [0]
			else if let node = node as? ExprLookupNode {
				// TODO: This is implemented very slowly first. Let's think about an optimization

				let interpret = ExprInterpreter(node, lookupValueOfVariables, executeFunction)
				let list = dataItemListToArray(value as Any)
				let args = try ViewArguments.clone(viewArguments, managed: false)
				let expr = node.sequence[0]

				for item in list {
					args.set(".", item)
					if let hasFound = try interpret.execSingle(expr, args),
						ExprInterpreter.evaluateBoolean(hasFound) {
						value = item
						break
					}
				}
			}
		}

		// Format a date
		if let date = value as? Date {
			value = Views.formatDate(date)
		}

		recursionCounter -= 1

		return value
	}

	func executeFunction(lookup: ExprLookupNode,
						 args: [Any?],
						 viewArguments: ViewArguments?) throws -> Any? {
		let f = try lookupValueOfVariables(lookup: lookup,
										   viewArguments: viewArguments,
										   isFunction: true)

		if let f = f {
			if let f = f as? ([Any?]?) -> Any? {
				return f(args) as Any?
			} else {
				throw "Could not find function to execute: \(lookup.description)"
			}
		}

		let x: String? = nil
		return x as Any?
	}

	public func fetchDefinitions(selector: String? = nil,
								 name: String? = nil,
								 type: String? = nil,
								 query: String? = nil,
								 domain: String? = nil) -> [CVUStoredDefinition] {
		var filter: [String] = []

		if let selector = selector { filter.append("selector = '\(selector)'") }
		else {
			if let type = type { filter.append("type = '\(type)'") }
			if let name = name { filter.append("name = '\(name)'") }
			if let query = query { filter.append("query = '\(query)'") }
		}

		if let domain = domain { filter.append("domain = '\(domain)'") }

		return realm.objects(CVUStoredDefinition.self)
			.filter(filter.joined(separator: " AND "))
			.map { (def) -> CVUStoredDefinition in def }
	}

	// TODO: REfactor return list of definitions
	func parseDefinition(_ viewDef: CVUStoredDefinition?) throws -> CVUParsedDefinition? {
		guard let viewDef = viewDef, let strDef = viewDef.definition else {
			throw "Exception: Missing CVU definition"
		}

		guard let context = context else {
			throw "Exception: Missing Context"
		}

		let cached = InMemoryObjectCache.get(strDef)
		if let cached = cached as? CVU {
			return try cached.parse().first
		} else if let definition = viewDef.definition {
			let viewDefParser = CVU(definition, context,
									lookup: lookupValueOfVariables,
									execFunc: executeFunction)
			try InMemoryObjectCache.set(strDef, viewDefParser)

			if let firstDefinition = try viewDefParser.parse().first {
				// TODO: potentially turn this off to optimize
				let validator = CVUValidator()
				if !validator.validate([firstDefinition]) {
					validator.debug()
					if validator.warnings.count > 0 {
						for message in validator.warnings { debugHistory.warn(message) }
					}
					if validator.errors.count > 0 {
						for message in validator.errors { debugHistory.error(message) }
						throw "Exception: Errors in default view set:    \n\(validator.errors.joined(separator: "\n    "))"
					}
				}

				return firstDefinition
			}
		} else {
			throw "Exception: Missing view definition"
		}

		return nil
	}

	public func createCascadingView(_ sessionView: SessionView? = nil) throws -> CascadingView {
		guard let context = self.context else {
			throw "Exception: MemriContext is not defined in views"
		}

		var cascadingView: CascadingView
		if let viewFromSession = sessionView ?? context.sessions?.currentSession?.currentView {
			cascadingView = try CascadingView.fromSessionView(viewFromSession, in: context)
		} else {
			throw "Unable to find currentView"
		}

		// TODO: REFACTOR: move these to a better place (context??)

		// turn off editMode when navigating
		if context.sessions?.currentSession?.isEditMode == true {
			realmWriteIfAvailable(realm) {
				context.sessions?.currentSession?.isEditMode = false
			}
		}

		// hide filterpanel if view doesnt have a button to open it
		if context.sessions?.currentSession?.showFilterPanel ?? false {
			if cascadingView.filterButtons.filter({ $0.name == .toggleFilterPanel }).count == 0 {
				realmWriteIfAvailable(realm) {
					context.sessions?.currentSession?.showFilterPanel = false
				}
			}
		}

		return cascadingView
	}

	// TODO: Refactor: Consider caching cascadingView based on the type of the item
	public func renderItemCell(with dataItem: Item?,
							   search rendererNames: [String] = [],
							   inView viewOverride: String? = nil,
							   use viewArguments: ViewArguments? = nil) -> UIElementView {
		do {
			guard let context = self.context else {
				throw "Exception: MemriContext is not defined in views"
			}

			guard let dataItem = dataItem else {
				throw "Exception: No item is passed to render cell"
			}

			func searchForRenderer(in viewDefinition: CVUStoredDefinition) throws -> Bool {
				let parsed = try context.views.parseDefinition(viewDefinition)
				for def in parsed?["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [] {
					for name in rendererNames {
						// TODO: Should this first search for the first renderer everywhere
						//       before trying the second renderer?
						if def.name == name {
							if def["children"] != nil {
								cascadeStack.append(def)
								return true
							}
						}
					}
				}
				return false
			}

			var cascadeStack: [CVUParsedRendererDefinition] = []

			// If there is a view override, find it, otherwise
			if let viewOverride = viewOverride {
				if let viewDefinition = context.views.fetchDefinitions(selector: viewOverride).first {
					if viewDefinition.type == "renderer" {
						if let parsed = try context.views
							.parseDefinition(viewDefinition) as? CVUParsedRendererDefinition {
							if parsed["children"] != nil { cascadeStack.append(parsed) }
							else {
								throw "Exception: Specified view does not contain any UI elements: \(viewOverride)"
							}
						} else {
							throw "Exception: View definition is missing: \(viewOverride)"
						}
					} else if viewDefinition.type == "view" {
						_ = try searchForRenderer(in: viewDefinition)
					} else {
						throw "Exception: incompatible view type of \(viewDefinition.type ?? ""), expected renderer or view"
					}
				} else {
					throw "Exception: Could not find view to override: \(viewOverride)"
				}
			} else {
				// Find views based on datatype
				outerLoop: for needle in ["\(dataItem.genericType)[]", "*[]"] {
					for key in ["user", "defaults"] {
						if let viewDefinition = context.views
							.fetchDefinitions(selector: needle, domain: key).first {
							if try searchForRenderer(in: viewDefinition) { break outerLoop }
						}
					}
				}
			}

			// If we cant find a way to render using one of the views,
			// then find a renderer for one of the renderers
			if cascadeStack.count == 0 {
				for name in rendererNames {
					for key in ["user", "defaults"] {
						if let viewDefinition = context.views
							.fetchDefinitions(name: name, type: "renderer", domain: key).first {
							if let parsed = try context.views
								.parseDefinition(viewDefinition) as? CVUParsedRendererDefinition {
								if parsed["children"] != nil { cascadeStack.append(parsed) }
							}
						}
					}
				}
			}

			if cascadeStack.count == 0 {
				throw "Exception: Unable to find a way to render this element: \(dataItem.genericType)"
			}

			// Create a new view
			let cascadingRenderConfig = CascadingRenderConfig(cascadeStack, viewArguments)

			// Return the rendered UIElements in a UIElementView
			return cascadingRenderConfig.render(item: dataItem)
		} catch {
			debugHistory.error("Unable to render ItemCell: \(error)")

			// TODO: Refactor: Log error to the user
			return UIElementView(UIElement(.Text,
										   properties: ["text": "Could not render this view"]),
								 dataItem ?? Item())
		}
	}
}

func getDefaultViewContents() -> String {
	let urls = Bundle.main.urls(forResourcesWithExtension: "cvu", subdirectory: ".")
	return (urls ?? []).compactMap { try? String(contentsOf: $0) }.joined(separator: "\n")
}
