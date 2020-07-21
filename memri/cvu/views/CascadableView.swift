//
//  ComputedView.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

public class CascadableView: Cascadable, ObservableObject, Subscriptable {
    var context: MemriContext?
    var session: Session? = nil
    
    /// The uid of the CVUStateDefinition
    var uid: Int
    
    var state: CVUStateDefinition? {
		DatabaseController.read { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        }
    }
    
	/// The name of the cascading view
	var name: String? {
        get { cascadeProperty("name") }
        set (value) { setState("name", value) }
    }

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
    
    var fullscreen: Bool {
        get { viewArguments?.get("fullscreen") ?? cascadeProperty("fullscreen") ?? false }
        set (value) { setState("fullscreen", value) }
    }
    var showToolbar: Bool {
        get { viewArguments?.get("showToolbar") ?? cascadeProperty("showToolbar") ?? true }
        set (value) { setState("showToolbar", value) }
    }
    var showSearchbar: Bool {
        get { viewArguments?.get("showSearchbar") ?? cascadeProperty("showSearchbar") ?? true }
        set (value) { setState("showSearchbar", value) }
    }
    #warning("Implement this in all renderers")
    var readOnly: Bool {
        get { viewArguments?.get("readOnly") ?? cascadeProperty("readOnly") ?? true }
        set (value) { setState("readOnly", value) }
    }

	var backTitle: String? {
        get { cascadeProperty("backTitle") }
        set (value) { setState("backTitle", value) }
    }
	var searchHint: String {
        get { cascadeProperty("searchHint") ?? "" }
        set (value) { setState("searchHint", value) }
    }
	var actionButton: Action? {
        get { cascadeProperty("actionButton") }
        set (value) { setState("actionButton", value) }
    }
	var editActionButton: Action? {
        get { cascadeProperty("editActionButton") }
        set (value) { setState("editActionButton", value) }
    }
	var sortFields: [String] {
        get { cascadeList("sortFields") }
        set (value) { setState("sortFields", value) }
    }
//	var editButtons: [Action] {
//        get { cascadeList("editButtons") }
//        set (value) { setState("editButtons", value) }
//    }
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

    var userState: CascadableDict {
        get {
            cascadeContext("userState", "userState", CVUParsedObjectDefinition.self)
        }
        set (value) {
            setState("userState", value.head)
        }
    }

    override var viewArguments: CascadableDict? {
        get {
            cascadeContext("viewArguments", "viewArguments", CVUParsedObjectDefinition.self)
        }
        set (value) {
            setState("viewArguments", value?.head)
        }
    }

    var resultSet: ResultSet {
        if let x = localCache["resultSet"] as? ResultSet { return x }

        // Update search result to match the query
        // NOTE: allowed force unwrap
        let resultSet = context!.cache.getResultSet(datasource.flattened())
        localCache["resultSet"] = resultSet

        // Filter the results
        let ft = userState.get("filterText") ?? ""
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
            let definitions = (a["rendererDefinitions"] as? [CVUParsedRendererDefinition] ?? [])
            // Prefer a perfectly matched definition
            return definitions.first(where: { $0.name == activeRenderer })
                // Else get the one from the parent renderer
                ?? definitions.first(where: { $0.name == activeRenderer.components(separatedBy: ".")
                    .dropLast().joined(separator: ".") })
        }
        
        let head = getConfig(self.head) ?? {
            let head = CVUParsedRendererDefinition("[renderer = \(activeRenderer)]")
            self.head["rendererDefinitions"] = [head]
            return head
        }()
        
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

		return CascadingRenderConfig()
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
		set(value) { setState("subtitle", value) }
	}

	var filterText: String {
		get {
            userState.get("filterText") ?? ""
		}
		set(newFilter) {
			// Don't update the filter when it's already set
			if newFilter.count > 0, _titleTemp != nil,
                userState.get("filterText") == newFilter {
				return
			}

			// Store the new value
            if (userState.get("filterText") ?? "") != newFilter {
                userState.set("filterText", newFilter)
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

            if userState.get("filterText") == "" {
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

                _emptyResultTextTemp = "No results found using '\(userState.get("filterText") ?? "")'"
			}
		}
	}

	var searchMatchText: String {
        get { userState.get("searchMatchText") ?? "" }
		set(newValue) { userState.set("searchMatchText", newValue) }
	}

    init (_ state: CVUStateDefinition, _ session: Session) throws {
        guard let uid = state.uid.value else {
            throw "CVU state object is unmanaged"
        }
        
        self.uid = uid
        self.session = session
        self.context = session.context
        
        guard let head = try context?.views.parseDefinition(state) else {
            throw "Could not parse state"
        }
        
        head.domain = "state"
        
        guard head.definitionType == "view" else {
            throw "Wrong type of definition passed: \(head.definitionType)"
        }
        
        super.init(head, [])
	}
    
    /// This init should only be called to create an empty CascadableView when needed inside a SwiftUI View
    required init(
        _ head: CVUParsedDefinition? = nil,
        _ tail: [CVUParsedDefinition]? = nil,
        _ host: Cascadable? = nil
    ) {
        self.uid = -1000000
        super.init(head, tail, host)
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
            case "sortFields": sortFields = value as? [String] ?? []
//            case "filterButtons": filterButtons = value as? String ?? ""
            case "contextButtons": contextButtons = value as? [Action] ?? []
//            case "renderConfig": renderConfig = value as? String ?? ""
            case "emptyResultText": emptyResultText = value as? String ?? ""
            case "title": title = value as? String ?? ""
            case "subtitle": subtitle = value as? String ?? ""
            case "filterText": filterText = value as? String ?? ""
            case "searchMatchText": searchMatchText = value as? String ?? ""
            default:
                // Do nothing
                debugHistory.warn("Unable to set property: \(propName)")
                return
            }
        }
	}
    
    override func setState(_ propName:String, _ value:Any?) {
        super.setState(propName, value)
        schedulePersist()
    }
    
    func schedulePersist() {
        session?.sessions?.schedulePersist()
    }
    
    public func persist() throws {
        try DatabaseController.tryWriteSync { realm in
            var state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if state == nil {
                debugHistory.warn("Could not find stored view CVU. Creating a new one.")
                
                state = try Cache.createItem(CVUStateDefinition.self)
                
                guard let stateUID = state?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                uid = stateUID
            }
            
            state?.set("definition", head.toCVUString(0, "    "))
        }
    }
    
    private func include(_ parsedDef: CVUParsedDefinition, _ domain: String) throws {
        if !cascadeStack.contains(parsedDef) {
            // Compile parsed definition to embed state that may change (e.g. currentView)
            try parsedDef.compile(viewArguments, scope: .needed)
            
            // Add to cascade stack
            cascadeStack.append(parsedDef)
            if parsedDef != head { tail.append(parsedDef) }
            
            if let inheritFrom = parsedDef["inherit"] {
                var result: Any? = inheritFrom

                if let expr = inheritFrom as? Expression {
                    result = try expr.execute(viewArguments)
                }

                if let viewName = result as? String {
                    if let view = context?.views.fetchDefinitions(name: viewName).first {
                        parse(view, domain)
                    }
                    else {
                        throw "Exception: could not parse view: \(viewName)"
                    }
                } else if let view = result as? CascadableView {
                    let parsed = CVUParsedViewDefinition(parsed: view.head.parsed)
                    try include(parsed, domain)
                } else {
                    throw "Exception: Unable to inherit view from \(inheritFrom)"
                }
                
                parsedDef.parsed?.removeValue(forKey: "inherit")
            }
        }
    }
    
    private func parse(_ def: CVUStoredDefinition?, _ domain: String) {
        do {
            guard let def = def else {
                throw "Exception: missing view definition"
            }

            if let parsedDef = try context?.views.parseDefinition(def) {
                parsedDef.domain = domain

                try include(parsedDef, domain)
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

    public func cascade(_ resultSet:ResultSet) throws {
		// Determine whether this is a list or a single item resultset
		let isList = resultSet.isList

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
        
		// Find views based on datatype
		for domain in ["user", "defaults"] {
			for needle in needles {
				if let def = context?.views.fetchDefinitions(selector: needle, domain: domain).first {
					parse(def, domain)
				} else if domain != "user" {
					debugHistory.warn("Could not find definition for '\(needle)' in domain '\(domain)'")
				}
			}
		}

		if activeRenderer == "" {
			throw "Exception: could not determine the active renderer for this view"
		}
        
        // TODO is this needed for anything or should the tail property be removed?
        tail = cascadeStack.suffix(cascadeStack.count - 1)
        localCache = [:] // Reset local cache again since it was filled when we fetched datasource
	}
    
    public func reload() throws {
        try self.resultSet.load { error in
            if let error = error {
                // TODO: Refactor: Log warning to user
                debugHistory.error("Exception: could not load result: \(error)")
            } else {
                // Update the UI
                context?.scheduleUIUpdate()
            }
        }
    }
    
    var loading:Bool = false
    
    public func load(_ callback:(Error?) -> Void) throws {
        guard !loading else { return }
        loading = true
        
        // Reset properties
        tail = [CVUParsedDefinition]()
        localCache = [:]
        cascadeStack = []
        
        // Load all includes in the stack so that we can make sure there is a datasource defined
        try include(head, "state")
        
        let datasource = self.datasource
        guard datasource.query != nil else { throw "Exception: Missing datasource in view" }
        localCache = [:] // Clear cache again to delete the entry for datasource

        // Look up the associated result set
        guard let resultSet = context?.cache.getResultSet(datasource.flattened()) else {
            throw "Exception: Unable to fetch result set from view"
        }
        
        if context is RootContext {
            debugHistory.info("Computing view " + (name ?? state?.selector ?? ""))
        }

        // If we can guess the type of the result based on the query, let's compute the view
        if resultSet.determinedType != nil {
            do {
                // Load the cascade list of views
                try cascade(resultSet)

                try self.resultSet.load { error in
                    if let error = error {
                        // TODO: Refactor: Log warning to user
                        debugHistory.error("Exception: could not load result: \(error)")
                    } else {
                        // Update the UI
                        context?.scheduleUIUpdate()
                    }
                    
                    loading = false
                    callback(error)
                }
            } catch {
                // TODO: Error handling
                // TODO: User Error handling
                debugHistory.error("\(error)")
            }
        }
        // Otherwise let's execute the query first to be able to read the type from the data
        else {
            try resultSet.load { error in
                if let error = error {
                    // TODO: Error handling
                    debugHistory.error("Exception: could not load result: \(error)")
                } else {
                    // Load the cascade list of views
                    try cascade(resultSet)
                }
                
                loading = false
                callback(error)
            }
        }
    }
}
