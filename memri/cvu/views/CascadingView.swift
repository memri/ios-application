//
//  ComputedView.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class CascadableContextPane: Cascadable {
    var buttons: [Action] {
        get { cascadeList("buttons") }
        set (value) { setState("buttons", value) }
    }
    
    var actions: [Action] {
        get { cascadeList("actions") }
        set (value) { setState("actions", value) }
    }
    
    var navigate: [Action] {
        get { cascadeList("navigate") }
        set (value) { setState("navigate", value) }
    }
}

public class CascadableDict: Cascadable {
    func get(_ name:String) -> Any? {
        cascadeProperty(name)
    }
    
    func set(_ name:String, _ value:Any?) {
        setState(name, value)
    }
    
    convenience init(_ parsed: [String:Any?]? = nil, host:Cascadable? = nil) {
        self.init(CVUParsedObjectDefinition(parsed), [], host)
    }
    
    convenience init(_ cascadableDict: CascadableDict) {
        #warning("Implement")
        throw "Not implemented"
//        self.init(CVUParsedObjectDefinition(parsed), [], host)
    }
}
typealias UserState = CascadableDict
typealias ViewArguments = CascadableDict

public class CascadingView: Cascadable, ObservableObject {
    var context: MemriContext?
    
    /// The uid of the CVUStateDefinition
    var uid: Int
    
	/// The name of the cascading view
	var name: String { cascadeProperty("name") ?? "" } // by copy??

	var activeRenderer: String {
		get {
			if let s: String = cascadeProperty("defaultRenderer") { return s }
			debugHistory.error("Exception: Unable to determine the active renderer. Missing defaultRenderer in view?")
			return ""
		}
		set(value) {
//			localCache.removeValue(forKey: value) // Remove renderConfig reference
            #warning("TODO: Store value in userstate for other context based on .")
            setState("defaultRenderer", value)
		}
	}

	var backTitle: String? {
        get { cascadeProperty("backTitle") }
        set (value) { setState("backTitle", value) }
    }
	var searchHint: String {
        get {cascadeProperty("searchHint") ?? "" }
        set (value) { setState("searchHint", value) }
    }
//	var actionButton: Action? {
//        get {cascadeProperty("actionButton") }
//        set (value) { setState("actionButton", value) }
//    }
	var editActionButton: Action? {
        get { cascadeProperty("editActionButton") }
        set (value) { setState("editActionButton", value) }
    }
	var sortFields: [String] {
        get { cascadeList("sortFields") }
        set (value) { setState("sortFields", value) }
    }
	var editButtons: [Action] {
        get { cascadeList("editButtons") }
        set (value) { setState("editButtons", value) }
    }
	var filterButtons: [Action] {
        get { cascadeList("filterButtons") }
        set (value) { setState("filterButtons", value) }
    }
    var showLabels: Bool {
        get { cascadeProperty("showLabels") ?? true }
        set (value) { setState("showLabels", value) }
    }
	var actionItems: [Action] {
        get { cascadeList("actionItems") }
        set (value) { setState("actionItems", value) }
    }
	var navigateItems: [Action] {
        get { cascadeList("navigateItems") }
        set (value) { setState("navigateItems", value) }
    }
	var contextButtons: [Action] {
        get { cascadeList("contextButtons") }
        set (value) { setState("contextButtons", value) }
    }

    #warning("Move to Cascadable")
    func cascadeContext<T:Cascadable, P:CVUParsedDefinition>(
        _ propName:String,
        _ lookupName:String,
        _ parsedType:P.Type,
        _ type:T.Type = T.self
    ) -> T {
        if let x = localCache[propName] as? T { return x }
        
        let h = self.head[lookupName] as? P
        if h == nil { self.head[lookupName] = P.init() }
        guard let head = h else { return }
        
        let tail = self.tail.compactMap { $0[lookupName] as? P }

        let cascadable = T.init(head, tail, self)
        localCache[propName] = cascadable
        return cascadable
    }
    
    var datasource: CascadingDatasource {
        cascadeContext("datasource", "datasourceDefinition", CVUParsedDatasourceDefinition.self)
    }
    
//    var datasource: CascadingDatasource {
//        if let x = localCache["datasource"] as? CascadingDatasource { return x }
//
//        let head = self.head["datasourceDefinition"] as? CVUParsedDatasourceDefinition
//            ?? CVUParsedDatasourceDefinition()
//
//        let tail = self.tail.compactMap {
//            $0["datasourceDefinition"] as? CVUParsedDatasourceDefinition
//        }
//
//        let datasource = CascadingDatasource(head, tail, self)
//        localCache["datasource"] = datasource
//        return datasource
//    }
    
    var contextPane: CascadableContextPane {
        cascadeContext("contextPane", "contextPane", CVUParsedObjectDefinition.self)
    }

    // Use cascadeDict here??
    var userState: CascadableDict {
        get {
            cascadeContext("userState", "userState", CVUParsedObjectDefinition.self)
        }
        set (value) {
            setState("userState", value)
        }
    }

    // TODO: let this cascade when the use case for it arrises
    // Use cascadeDict here??
    override var viewArguments: CascadableDict? {
        get {
            cascadeContext("viewArguments", "viewArguments", CVUParsedObjectDefinition.self)
        }
        set (value) {
            setState("viewArguments", value)
        }
    }

    var resultSet: ResultSet {
        if let x = localCache["resultSet"] as? ResultSet { return x }

        // Update search result to match the query
        // NOTE: allowed force unwrap
        let resultSet = context!.cache.getResultSet(datasource.flattened())
        localCache["resultSet"] = resultSet

        // Filter the results
        let ft = userState?.get("filterText") ?? ""
        if resultSet.filterText != ft {
            filterText = ft
        }

        return resultSet
    } // TODO: Refactor set when datasource changes ??

    private func insertRenderDefs(_ tail: inout [CVUParsedRendererDefinition]) {
        var renderDef: [CVUStoredDefinition] = context?.views
            .fetchDefinitions(name: activeRenderer, type: "renderer") ?? []

        if activeRenderer.contains("."), let name = activeRenderer.split(separator: ".").first {
            renderDef.append(contentsOf: context?.views
                .fetchDefinitions(name: String(name), type: "renderer") ?? [])
        }
        
        do {
            for def in renderDef {
                if let parsedRenderDef = try context?.views.parseDefinition(def) as? CVUParsedRendererDefinition {
                    if parsedRenderDef.domain == "user" {
                        let insertPoint: Int = {
                            for i in 0 ..< tail.count { if tail[i].domain == "view" { return i } }
                            return tail.count
                        }()

                        tail.insert(parsedRenderDef, at: insertPoint)
                    } else {
                        tail.append(parsedRenderDef)
                    }
                } else {
                    // TODO: Error logging
                    debugHistory.warn("Exception: Unable to cascade render config")
                }
            }
        } catch {
            // TODO: Error logging
            debugHistory.error("\(error)")
        }
    }
    
	var renderConfig: CascadingRenderConfig? {
		if let x = localCache[activeRenderer] as? CascadingRenderConfig { return x }

        func getConfig(_ a:CVUParsedDefinition) -> CVUParsedRendererDefinition? {
            let definitions = (a["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [])
            // Prefer a perfectly matched definition
            return definitions.first(where: { $0.name == activeRenderer })
                // Else get the one from the parent renderer
                ?? definitions.first(where: { $0.name == activeRenderer.components(separatedBy: ".")
                    .dropLast().joined(separator: ".") })
        }
        
        let h = getConfig(self.head)
        if h == nil {
            h = CVUParsedRendererDefinition("[renderer = \(name)]", name: name)
            self.head["renderDefinitions"] = [h]
        }
        guard let head = h else { return }
        
        var tail = self.tail.compactMap { getConfig($0) }
        
        insertRenderDefs(&tail)

        if let all = allRenderers, let RenderConfigType = all.allConfigTypes[activeRenderer] {
            // swiftformat:disable:next redundantInit
            let renderConfig = RenderConfigType.init(head, tail, host)
            // Not actively preventing conflicts in namespace - assuming chance to be low
            localCache[activeRenderer] = renderConfig
            return renderConfig
        } else {
            // TODO: Error Logging
            debugHistory.error("Unable to cascade render config for \(activeRenderer)")
        }

		return CascadingRenderConfig([])
	}

	private var _emptyResultTextTemp: String?
	var emptyResultText: String {
		get { _emptyResultTextTemp ?? cascadeProperty("emptyResultText") ?? "No items found" }
		set(value) { setState("emptyResultText", value) }
	}

	private var _titleTemp: String?
	var title: String {
		get { _titleTemp ?? cascadeProperty("title", type: String.self) ?? "" }
		set(value) { setState("title", value) }
	}

	private var _subtitleTemp: String?
	var subtitle: String {
		get { _subtitleTemp ?? cascadeProperty("subtitle") ?? "" }
		set(newSubtitle) { setState("subtitle", value) }
	}

	var filterText: String {
		get {
			userState?.get("filterText") ?? ""
		}
		set(newFilter) {
			// Don't update the filter when it's already set
			if newFilter.count > 0, _titleTemp != nil,
				userState?.get("filterText") == newFilter {
				return
			}

			// Store the new value
			if (userState?.get("filterText") ?? "") != newFilter {
				userState?.set("filterText", newFilter)
			}

			// If this is a multi item result set
			if resultSet.isList {
				// TODO: we should probably ask the renderer if this is preferred
				// Some renderers such as the charts would probably rather highlight the
				// found results instead of filtering the other data points out

				// Filter the result set
				resultSet.filterText = newFilter
			} else {
				print("Warn: Filtering for single items not Implemented Yet!")
			}

			if userState?.get("filterText") == "" {
				_titleTemp = nil
				_subtitleTemp = nil
				_emptyResultTextTemp = nil
			} else {
				// Set the title to an appropriate message
				if resultSet.count == 0 { _titleTemp = "No results" }
				else if resultSet.count == 1 { _titleTemp = "1 item found" }
				else { _titleTemp = "\(resultSet.count) items found" }

				// Temporarily hide the subtitle
				// _subtitleTemp = " " // TODO how to clear the subtitle ??

				_emptyResultTextTemp = "No results found using '\(userState?.get("filterText") ?? "")'"
			}
		}
	}

	var searchMatchText: String {
		get { userState?.get("searchMatchText") ?? "" }
		set(newValue) { userState?.set("searchMatchText", newValue) }
	}

    init(_ state: CVUStateDefinition, context: MemriContext) throws {
        self.uid = state.uid.value
        
        var head = try context?.views.parseDefinition(state)
        head.domain = "state"
        
		super.init(head, [])
	}

	subscript(propName: String) -> Any? {
		get {
			switch propName {
			case "name": return name
			case "datasource": return datasource
            case "contextPane": return userState
			case "userState": return userState
			case "viewArguments": return viewArguments
			case "resultSet": return resultSet
			case "activeRenderer": return activeRenderer
			case "backTitle": return backTitle
			case "searchHint": return searchHint
			case "actionButton": return actionButton
			case "editActionButton": return editActionButton
			case "sortFields": return sortFields
			case "filterButtons": return filterButtons
			case "contextButtons": return contextButtons
			case "renderConfig": return renderConfig
			case "emptyResultText": return emptyResultText
			case "title": return title
			case "subtitle": return subtitle
			case "filterText": return filterText
            case "searchMatchText": return searchMatchText
			default: return nil
			}
		}
		set(value) {
            switch propName {
            case "name": name = value as? String ?? ""
//            case "datasource": datasource = value as? CascadingDatasource
//            case "contextPane": userState = value as? String ?? ""
//            case "userState": userState = value as? String ?? ""
//            case "viewArguments": viewArguments = value as? String ?? ""
            case "activeRenderer": activeRenderer = value as? String ?? ""
            case "backTitle": backTitle = value as? String ?? ""
            case "searchHint": searchHint = value as? String ?? ""
//            case "actionButton": actionButton = value as? Action
//            case "editActionButton": editActionButton = value as? Action
            case "sortFields": sortFields = value as? [String] ?? ""
//            case "filterButtons": filterButtons = value as? String ?? ""
            case "contextButtons": contextButtons = value as? [Action]
//            case "renderConfig": renderConfig = value as? String ?? ""
            case "emptyResultText": emptyResultText = value as? String ?? ""
            case "title": title = value as? String ?? ""
            case "subtitle": subtitle = value as? String ?? ""
            case "filterText": filterText = value as? String ?? ""
            case "searchMatchText": searchMatchText = value as? String ?? ""
            default: return nil
            }
        }
	}
    
    public func persist() throws {
        withRealm { realm in
            var stored = realm.object(ofType: CVUStateDefinition.self, withPrimaryKey: uid)
            if stored == nil {
                stored = try Cache.createItem(CVUStateDefinition.self, values: [])
            }
            
            stored?.set("definition", head.toCVUString(0, "    "))
        }
    }

	private func inherit(_ source: Any,
							   _ viewArguments: ViewArguments?,
							   _ context: MemriContext,
							   _ sessionView: SessionView) throws -> CVUStoredDefinition? {
		var result: Any? = source

		if let expr = source as? Expression {
			result = try expr.execute(viewArguments)
		}

		if let viewName = result as? String {
			return context.views.fetchDefinitions(name: viewName).first
		} else if let view = result as? SessionView {
			try sessionView.mergeState(view)
			return view.viewDefinition
		} else if let view = result as? CascadingView {
			try sessionView.mergeState(view.sessionView)
			return view.sessionView.viewDefinition
		}

		return nil
	}

	public func cascade() throws {
        // Reset properties
		tail = [CVUParsedDefinition]()
        localCache = [:]
        cascadeStack = []

		// Fetch query from the view from session
		guard let datasource = head["datasourceDefinition"] else {
			throw "Exception: Cannot compute a view without a query to fetch data"
		}

		// Look up the associated result set
		let resultSet = context.cache.getResultSet(datasource)

		// Determine whether this is a list or a single item resultset
		var isList = resultSet.isList

		// Fetch the type of the results
		guard let type = resultSet.determinedType else {
			throw "Exception: ResultSet does not know the type of its data"
		}

		var needles: [String]
		if type != "mixed" {
			// Determine query
			needles = [
				isList ? "\(type)[]" : "\(type)", // TODO: if this is not found it should get the default template
				isList ? "*[]" : "*",
			]
		} else {
			needles = [isList ? "*[]" : "*"]
		}

        func checkForIncludes(_ parsedDef: CVUParsedDefinition) throws {
            if !cascadeStack.contains(parsedDef) {
                cascadeStack.append(parsedDef)

                if let inheritedView = parsedDef["inherit"] {
                    if let view = try inherit(inheritedView, viewArguments, context, sessionView) {
                        parse(view, domain)
                    } else {
                        throw "Exception: Unable to inherit view from \(inheritedView)"
                    }
                    
                    parsedDef.removeValue(forKey: "inherit")
                }
            }
        }
        
		func parse(_ def: CVUStoredDefinition?, _ domain: String) {
			do {
				guard let def = def else {
					throw "Exception: missing view definition"
				}

				if let parsedDef = try context.views.parseDefinition(def) {
					parsedDef.domain = domain

					if activeRenderer == nil, let d = parsedDef["defaultRenderer"] {
						activeRenderer = d
					}

					try checkForIncludes(parsedDef)
				} else {
					debugHistory.error("Could not parse definition")
				}
			} catch {
				if let error = error as? CVUParseErrors {
					debugHistory.error("\(error.toString(def?.definition ?? ""))")
				} else {
					debugHistory.error("\(error)")
				}
			}
		}

        // Add head to the cascadeStack
        checkForIncludes(head)
        
        var activeRenderer: Any? = head["defaultRenderer"]

		// Find views based on datatype
		for domain in ["user", "defaults"] {
			for needle in needles {
				if let def = context.views.fetchDefinitions(selector: needle, domain: domain).first {
					parse(def, domain)
				} else if domain != "user" {
					debugHistory.warn("Could not find definition for '\(needle)' in domain '\(domain)'")
				}
			}
		}

		if activeRenderer == nil {
			throw "Exception: could not determine the active renderer for this view"
		}
	}
}
