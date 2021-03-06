//
// Views.swift
// Copyright © 2020 memri. All rights reserved.

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
    private var cvuWatcher: AnyCancellable?
    private var settingWatcher: AnyCancellable?

    init() {}

    public func load(_ context: MemriContext) throws {
        self.context = context

        try setCurrentLanguage(context.settings.get("user/language") ?? "English")

        settingWatcher = context.settings.subscribe("device/debug/autoReloadCVU", type: Bool.self)
            .sink {
                if let value = $0 as? Bool {
                    if value && self.cvuWatcher == nil {
                        self.listenForChanges()
                    }
                    else if !value, let c = self.cvuWatcher {
                        c.cancel()
                        self.cvuWatcher = nil
                    }
                }
            }
    }

    public func listenForChanges() {
        guard context?.podAPI.isConfigured ?? false else { return }
        guard !DatabaseController.isRunningXcodeTests else { return }

        // Subscribe to changes in CVUStoredDefinition
        cvuWatcher = context?.cache.subscribe(query: "CVUStoredDefinition")
            .sink { items in // CVUStoredDefinition AND domain='user'
                self.reloadViews(items)
            }
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
    public func install(
        overrideCodeForTesting: String? = nil,
        _ callback: @escaping (Error?) -> Void
    ) {
        guard let context = context else {
            callback("Context is not set")
            return
        }

        let code = overrideCodeForTesting ?? getDefaultViewContents()

        var parsedDefinitions: [CVUParsedDefinition]
        do {
            let cvu = CVU(code, context, lookup: lookupValueOfVariables, execFunc: executeFunction)
            parsedDefinitions = try cvu.parse() // TODO: this could be optimized
        }
        catch {
            if let error = error as? CVUParseErrors {
                // TODO: Fatal error handling
                callback("Parse Error: \(error.toString(code))")
            }
            else {
                callback(error)
            }
            return
        }

        let validator = CVUValidator()
        if !validator.validate(parsedDefinitions) {
            validator.debug()
            if validator.warnings.count > 0 {
                for message in validator.warnings { debugHistory.warn(message) }
            }
            if validator.errors.count > 0 {
                for message in validator.errors { debugHistory.error(message) }
                callback(
                    "Exception: Errors in default view set:    \n\(validator.errors.joined(separator: "\n    "))"
                )
                return
            }
        }

        // Start write transaction outside loop for performance reasons
        DatabaseController.asyncOnBackgroundThread(write: true, error: callback) { _ in
            // Loop over lookup table with named views
            for def in parsedDefinitions {
                var values: [String: Any?] = [
                    "domain": "defaults",
                    "definition": def.description,
                ]

                if def.selector != nil { values["selector"] = def.selector }
                if def.name != nil { values["name"] = def.name }

                guard let selector = def.selector else {
                    throw "Exception: selector on parsed CVU is not defined"
                }

                if def is CVUParsedViewDefinition {
                    values["itemType"] = "view"
                    //                    values["query"] = (def as! CVUParsedViewDefinition)?.query ?? ""
                }
                else if def is CVUParsedRendererDefinition { values["itemType"] = "renderer" }
                else if def is CVUParsedDatasourceDefinition {
                    values["itemType"] = "datasource"
                }
                else if def is CVUParsedStyleDefinition { values["itemType"] = "style" }
                else if def is CVUParsedColorDefinition { values["itemType"] = "color" }
                else if def is CVUParsedLanguageDefinition { values["itemType"] = "language" }
                else if def is CVUParsedSessionsDefinition { values["itemType"] = "sessions" }
                else if def is CVUParsedSessionDefinition { values["itemType"] = "session" }
                else { throw "Exception: unknown definition" }

                // Store definition
                _ = try Cache.createItem(CVUStoredDefinition.self, values: values,
                                         unique: "selector = '\(selector)' and domain = 'defaults'")
            }

            callback(nil)
        }
    }

    // TODO: This should be moved elsewhere
    public class func formatDate(_ date: Date?, dateFormat: String? = nil) -> String {
        let showAgoDate: Bool? = Settings.shared.get("user/general/gui/showDateAgo")

        if let date = date {
            // Compare against 36 hours ago
            if dateFormat != nil || showAgoDate == false || date
                .timeIntervalSince(Date(timeIntervalSinceNow: -129_600)) < 0
            {
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = dateFormat == "time"
                    ? Settings.shared.get("user/formatting/time")
                    : dateFormat
                    ?? Settings.shared.get("user/formatting/date")
                    ?? "yyyy/MM/dd HH:mm"

                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                return dateFormatter.string(from: date)
            }
            else {
                return date.timestampString ?? ""
            }
        }
        else {
            return "never"
        }
    }

    public class func formatDateSinceCreated(_ date: Date?) -> String {
        if let date = date {
            return date.timeDelta ?? ""
        }
        else {
            return "never"
        }
    }

    func reloadViews(_: [Item]) {
//        guard let defs = items as? [CVUStoredDefinition] else {
//            return
//        }

        // This may not be needed
//        // Determine whether the current view needs reloading
//        for def in defs {
//            var selectors = [String]()
//            if let stack = context?.cascadableView?.cascadeStack {
//                for parsed in stack { selectors.append(parsed.selectors) }
//                ...
//            }
//        }

        context?.scheduleCascadableViewUpdate()
    }

    func getGlobalReference(_ name: String, viewArguments: ViewArguments?) throws -> Any? {
        let realm = try DatabaseController.getRealmSync()
        // Fetch the value of the right property on the right object
        switch name {
        case "setting":
            let f = { (args: [Any?]?) -> Any? in // (value:String) -> Any? in
                if let value = args?[safe: 0] as? String {
                    if let x = Settings.shared.get(value, type: Double.self) { return x }
                    else if let x = Settings.shared.get(value, type: Int.self) { return x }
                    else if let x = Settings.shared.get(value, type: String.self) { return x }
                    else if let x = Settings.shared.get(value, type: Bool.self) { return x }
                }
                return ""
            }
            return f
        case "item":
            let f = { (args: [Any?]?) -> Any? in // (value:String) -> Any? in
                guard let typeName = args?[safe: 0] as? String,
                      let uid = args?[safe: 1] as? Double
                else {
                    if args?.count == 0 {
                        return self.context?.currentView?.resultSet.singletonItem
                    }
                    return nil
                }
                return getItem(typeName, Int(uid))
            }
            return f
        case "debug":
            let f = { (args: [Any?]?) -> Any? in
                guard args?.count ?? 0 > 0 else {
                    debugHistory.info("nil")
                    return nil
                }
                debugHistory.info(args?.map { "\($0 ?? "")" }.joined(separator: " ") ?? "")
                return nil
            }
            return f
        case "min":
            let f = { (args: [Any?]?) -> Any? in
                let first = args?[0] as? Double ?? Double.nan
                let second = args?[1] as? Double ?? Double.nan
                return min(first, second)
            }
            return f
        case "max":
            let f = { (args: [Any?]?) -> Any? in
                let first = args?[0] as? Double ?? Double.nan
                let second = args?[1] as? Double ?? Double.nan
                return max(first, second)
            }
            return f
        case "floor":
            let f = { (args: [Any?]?) -> Any? in
                let value = args?[0] as? Double ?? Double.nan
                return floor(value)
            }
            return f
        case "ceil":
            let f = { (args: [Any?]?) -> Any? in
                let value = args?[0] as? Double ?? Double.nan
                return ceil(value)
            }
            return f
        case "me": return realm.objects(Person.self).filter("ANY allEdges.type = 'me'").first
        case "context": return context
        case "sessions": return context?.sessions
        case "currentSession": fallthrough
        case "session":
            return context?.currentSession
        case "currentView": fallthrough
        case "view": return context?.currentView
        case "singletonItem":
            if let itemRef: Item = viewArguments?.get(".") {
                return itemRef
            }
            else if let item = context?.currentView?.resultSet.singletonItem {
                return item
            }
            else {
                throw "Exception: Missing object for property getter"
            }
        default:
            if let value: Any = viewArguments?.get(name) { return value }

            debugHistory.warn("Undefined variable \(name)")
            return nil
            //			throw "Exception: Unknown object for property getter: \(name)"
        }
    }

    func lookupValueOfVariables(
        lookup: ExprLookupNode,
        viewArguments: ViewArguments?
    ) throws -> Any? {
        let x = try lookupValueOfVariables(
            lookup: lookup,
            viewArguments: viewArguments,
            isFunction: false
        )
        return x
    }

    func lookupValueOfVariables(
        lookup: ExprLookupNode,
        viewArguments: ViewArguments?,
        isFunction: Bool = false
    ) throws -> Any? {
        var value: Any?
        var first = true

        // TODO: support language lookup: {$name}
        // TODO: support .label.~label to get all items that share at least one label with dataItem

        recursionCounter += 1

        if recursionCounter > 4 {
            recursionCounter = 0
            throw "Exception: Recursion detected while expanding variable \(lookup.toExprString())"
        }

        var i = 0
        for node in lookup.sequence {
            i += 1

            if let node = node as? ExprVariableNode {
                if first {
                    // TODO: move to CVU validator??
                    if node.list == .list || node.type != .propertyOrItem {
                        recursionCounter = 0
                        throw "Unexpected edge lookup. No source specified"
                    }

                    let name = node.name == "@@DEFAULT@@" ? "singletonItem" : node.name
                    do {
                        value = try getGlobalReference(name, viewArguments: viewArguments)
                        first = false

                        if isFunction, i == lookup.sequence.count {
                            break
                        }
                    }
                    catch {
                        recursionCounter = 0
                        throw error
                    }
                }
                else if isFunction, i == lookup.sequence.count, let item = value as? Item {
                    value = item.functions[node.name]
                    if value == nil {
                        // TODO: parse [blah]
                        recursionCounter = 0
                        let message = "Exception: Invalid function call. Could not find"
                        throw "\(message) \(node.name)"
                    }
                    break
                }
                else if let dataItem = value as? Item {
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
                        }
                        else {
                            switch node.type {
                            case .reverseEdge: value = dataItem.reverseEdges(node.name)
                            case .reverseEdgeItem: value = dataItem.reverseEdges(node.name)?
                                .sources()
                            case .edge: value = dataItem.edges(node.name)
                            case .propertyOrItem: value = dataItem.edges(node.name)?.items()
                            }
                        }
                    }
                }
                else if let v = value as? Double {
                    switch node.name {
                    case "currency": value = {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        return formatter.string(from: NSNumber(value: v))
                    }()
                        default: break
                    }
                }
                else if let v = value as? String {
                    switch node.name {
                    case "uppercased": value = v.uppercased()
                    case "lowercased": value = v.lowercased()
                    case "camelCaseToWords": value = v.camelCaseToWords()
                    case "plural": value = v + "s" // TODO:
                    case "firstUppercased": value = v.capitalizingFirst()
                    case "plainString": value = v.strippingHTMLtags()
                    case "count": value = v.count
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on string")
                    }
                }
                else if let date = value as? Date {
                    switch node.name {
                    case "format":
                        guard isFunction else {
                            recursionCounter = 0
                            throw "You must call .format() as a function"
                        }

                        value = { (args: [Any?]?) -> Any? in
                            if args?.count == 0 { return Views.formatDate(date) }
                            else { return Views.formatDate(date, dateFormat: args?[0] as? String) }
                        }
                    case "timeSince1970": value = date.timeIntervalSince1970
                    case "timeSinceNow": value = date.timeIntervalSinceNow
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on string")
                    }
                }
                else if let v = value as? Edge {
                    switch node.name {
                    case "source": value = v.source()
                    case "target": value = v.target()
                    case "item": value = v.target()
                    case "label": value = v.edgeLabel
                    case "type": value = v.type
                    case "sequence": value = v.sequence
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on edge")
                    }
                }
                else if let v = value as? RealmSwift.Results<Edge> {
                    switch node.name {
                    case "count": value = v.count
                    case "first": value = v.first
                    case "last": value = v.last
                    //                        case "sum": value = v.sum
//                    case "min": value = v.min
//                    case "max": value = v.max
                    case "items": value = v.items()
                    // TODO: Add sort")
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on list of edges")
                    }
                }
                else if let v = value as? RealmSwift.Results<Item> {
                    switch node.name {
                    case "count": value = v.count
                    case "first": value = v.first
                    case "last": value = v.last
                    // TODO: Add sort")
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on list of items")
                    }
                }
                else if let v = value as? [Any?] {
                    switch node.name {
                    case "count": value = v.count
                    case "first": value = v.first as Any?
                    case "last": value = v.last as Any?
                    // TODO: Add sort")
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on list")
                    }
                }
                else if let v = value as? RealmSwift.ListBase {
                    switch node.name {
                    case "count": value = v.count
                    default:
                        // TODO: Warn
                        debugHistory.warn("Could not find property \(node.name) on list")
                    }
                }
                else if let v = value as? Subscriptable {
                    value = v[node.name]
                }
                // CascadingRenderer??
                else if let v = value as? Object {
                    if v.objectSchema[node.name] == nil {
                        // TODO: error handling
                        recursionCounter = 0
                        throw "No variable with name \(node.name)"
                    }
                    else {
                        value = v[node.name] // How to handle errors?
                    }
                }
                else if "\(value ?? "")" != "nil" { // TODO: Fix Any issue")
                    recursionCounter = 0
                    throw "Unexpected fetch \(node.name) on \(String(describing: value))"
                }
            }
            // .addresses[primary = true] || [0]
            else if let node = node as? ExprLookupNode {
                // TODO: This is implemented very slowly first. Let's think about an optimization

                let interpret = ExprInterpreter(node, lookupValueOfVariables, executeFunction)
                let list = dataItemListToArray(value as Any)
                let args = viewArguments?.copy() ?? ViewArguments(nil)
                let expr = node.sequence[0]

                for item in list {
                    args.set(".", item)
                    if let hasFound = try interpret.execSingle(expr, args),
                       ExprInterpreter.evaluateBoolean(hasFound) ?? false
                    {
                        value = item
                        break
                    }
                }
            }

            if value == nil {
                break
            }
        }

        recursionCounter -= 1

        return value
    }

    func executeFunction(
        lookup: ExprLookupNode,
        args: [Any?],
        viewArguments: ViewArguments?
    ) throws -> Any? {
        let f = try lookupValueOfVariables(lookup: lookup,
                                           viewArguments: viewArguments,
                                           isFunction: true)

        if let f = f {
            if let f = f as? ([Any?]?) -> Any? {
                return f(args) as Any?
            }
            else if "\(f)" != "nil" {
                // TODO: Temporary hack to detect nil that is not nil — .dateAccessed.format where .dateAccessed is nil")
                throw "Could not find function to execute: \(lookup.toExprString())"
            }
        }

        let x: String? = nil
        return x as Any?
    }

    public func fetchDefinitions(
        selector: String? = nil,
        name: String? = nil,
        type: String? = nil,
        query: String? = nil,
        domain: String? = nil
    ) -> [CVUStoredDefinition] {
        var filter: [String] = []

        if let selector = selector { filter.append("selector = '\(selector)'") }
        else {
            if let type = type { filter.append("itemType = '\(type)'") }
            if let name = name { filter.append("name = '\(name)'") }
            if let query = query { filter.append("query = '\(query)'") }
        }

        if let domain = domain { filter.append("domain = '\(domain)'") }

        return Array(
            DatabaseController.sync {
                $0.objects(CVUStoredDefinition.self)
                    .filter(filter.joined(separator: " AND "))
                    .map { (def) -> CVUStoredDefinition in def }
            } ?? []
        )
    }

    // TODO: REfactor return list of definitions
    func parseDefinition(_ viewDef: CVUStoredDefinition?) throws -> CVUParsedDefinition? {
        guard let viewDef = viewDef, let strDef = viewDef.definition else {
            throw "Exception: Missing CVU definition"
        }

        guard let context = context else {
            throw "Exception: Missing Context"
        }

        if let definition = viewDef.definition {
            let viewDefParser = CVU(definition, context,
                                    lookup: lookupValueOfVariables,
                                    execFunc: executeFunction)
            try InMemoryObjectCache.global.set(strDef, viewDefParser)

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
        }
        else {
            throw "Exception: Missing view definition"
        }

        return nil
    }

    /// Takes a stored definition and fetches the view definition or when its a session definition, the currentView of that session
    func getViewStateDefinition(from stored: CVUStoredDefinition) throws -> CVUStateDefinition {
        var view: CVUStateDefinition
        if stored.itemType == "view" {
            view = try CVUStateDefinition.fromCVUStoredDefinition(stored)
        }
        else if stored.itemType == "session" {
            guard let parsed = try parseDefinition(stored) else {
                throw "Unable to parse state definition"
            }

            if
                let list = parsed["views"] as? [CVUParsedViewDefinition],
                let p = list[safe: parsed["currentViewIndex"] as? Int ?? 0]
            {
                view = try CVUStateDefinition.fromCVUParsedDefinition(p)
            }
            else {
                throw "Invalid definition type"
            }
        }
        else {
            throw "Invalid definition type"
        }

        return view
    }

    // TODO: Refactor: Consider caching cascadableView based on the type of the item
    public func renderItemCell(
        with item: Item?,
        search rendererNames: [String] = [],
        inView viewOverride: String? = nil,
        use viewArguments: ViewArguments = ViewArguments()
    ) -> AnyView {
        do {
            guard let context = self.context else {
                throw "Exception: MemriContext is not defined in views"
            }

            guard let item = item else {
                throw "Exception: No item is passed to render cell"
            }

            func searchForRenderer(in viewDefinition: CVUStoredDefinition) throws -> Bool {
                let parsed = try context.views.parseDefinition(viewDefinition)
                for name in rendererNames {
                    for def in parsed?["rendererDefinitions"] as? [CVUParsedRendererDefinition] ?? [] {
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
                if let viewDefinition = context.views.fetchDefinitions(selector: viewOverride)
                    .first
                {
                    if viewDefinition.itemType == "renderer" {
                        if let parsed = try context.views
                            .parseDefinition(viewDefinition) as? CVUParsedRendererDefinition
                        {
                            if parsed["children"] != nil { cascadeStack.append(parsed) }
                            else {
                                throw "Exception: Specified view does not contain any UI elements: \(viewOverride)"
                            }
                        }
                        else {
                            throw "Exception: View definition is missing: \(viewOverride)"
                        }
                    }
                    else if viewDefinition.itemType == "view" {
                        _ = try searchForRenderer(in: viewDefinition)
                    }
                    else {
                        throw "Exception: incompatible view type of \(viewDefinition.itemType ?? ""), expected renderer or view"
                    }
                }
                else {
                    throw "Exception: Could not find view to override: \(viewOverride)"
                }
            }
            else {
                // Find views based on datatype
                outerLoop: for needle in ["\(item.genericType)[]", "*[]"] {
                    for key in ["user", "defaults"] {
                        if let viewDefinition = context.views
                            .fetchDefinitions(selector: needle, domain: key).first
                        {
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
                            .fetchDefinitions(name: name, type: "renderer", domain: key).first
                        {
                            if let parsed = try context.views
                                .parseDefinition(viewDefinition) as? CVUParsedRendererDefinition
                            {
                                if parsed["children"] != nil { cascadeStack.append(parsed) }
                            }
                        }
                    }
                }
            }

            if cascadeStack.count == 0 {
                throw "Exception: Unable to find a way to render this element: \(item.genericType)"
            }

            // Create a new view
            // TODO: viewArguments are not passed to cascading config, is that bad?")
            let cascadingRendererConfig = CascadingRendererConfig(
                nil,
                cascadeStack,
                context.currentView
            )

            // Return the rendered UIElements in a UIElementView
            return cascadingRendererConfig.render(item: item, arguments: viewArguments)
                .eraseToAnyView()
        }
        catch {
            debugHistory.error("Unable to render ItemCell: \(error)")

            // TODO: Refactor: Log error to the user
            return Text("Could not render this view").eraseToAnyView()
        }
    }
}

func getDefaultViewContents() -> String {
    let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
    guard
        let directory = Bundle.main.resourceURL?.appendingPathComponent(
            "defaultCVU",
            isDirectory: true
        ),
        let enumerator = FileManager.default.enumerator(at: directory,
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (_, _) -> Bool in
                                                            true
                                                        })
    else { return "" }
    return enumerator.compactMap { $0 as? URL }.compactMap {
        guard $0.pathExtension == "cvu" else { return nil }
        return try? String(contentsOf: $0)
    }.joined(separator: "\n")
}
