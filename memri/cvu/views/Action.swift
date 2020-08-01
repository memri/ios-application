//
// Action.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

extension MemriContext {
    private func getItem(_ dict: [String: Any?]?) throws -> Item {
        let realm = try DatabaseController.getRealmSync()
        
        guard let dict = dict else {
            throw "Missing properties"
        }
        
        guard
            let stringType = dict["_type"] as? String,
            let schema = realm.schema[stringType]
        else {
            throw "Missing type attribute to indicate the type of the data item"
        }

        guard let family = ItemFamily(rawValue: stringType) else {
            throw "Cannot find find family \(stringType)"
        }

        guard let ItemType = ItemFamily.getType(family)() as? Item.Type else {
            throw "Cannot find family \(stringType)"
        }

        var values = [String:Any?]()
        var edges = [String:Any?]()
        for (key, value) in dict {
            if key == "_type" || key == "uid" { continue }
            if schema[key] != nil { values[key] = value }
            else if value is Item { edges[key] = value }
            else if value is [Item] { edges[key] = value }
            else {
                throw "Passed invalid value as \(key)"
            }
        }
        
        let item = try Cache.createItem(ItemType, values: values)
        
        for (edgeType, value) in edges {
            if let list = value as? [Item] {
                for target in list {
                    _ = try item.link(target, type: edgeType)
                }
            }
            else if let target = value as? Item {
                _ = try item.link(target, type: edgeType, distinct: true)
            }
        }
        
        return item
    }

    func buildArguments(
        _ action: Action,
        _ item: Item?,
        _ viewArguments: ViewArguments? = nil
    ) throws -> [String: Any?] {
        let viewArgs = try ViewArguments(currentView?.viewArguments, item)
            .merge(viewArguments)
            .resolve(item)

        var args = [String: Any?]()
        for (argName, inputValue) in action.values {
            if action.argumentTypes[argName] == nil { continue }

            var argValue: Any?

            if let expr = inputValue as? Expression {
                argValue = try expr.execute(viewArgs)
            }
            else {
                argValue = inputValue
            }

            var finalValue: Any? = ""

            if let dataItem = argValue as? Item {
                finalValue = dataItem
            }
            else if let dict = argValue as? [String: Any?] {
                if action.argumentTypes[argName] == ViewArguments.self {
                    finalValue = try ViewArguments(dict).resolve(item, viewArgs)
                }
                else if action.argumentTypes[argName] == ItemFamily.self {
                    finalValue = try getItem(Expression.resolve(dict, viewArgs))
                }
                else if action.argumentTypes[argName] == CVUStateDefinition.self {
                    let viewDef = CVUParsedViewDefinition("[\(argName)]")
                    viewDef.parsed = dict
                    finalValue = try CVUStateDefinition.fromCVUParsedDefinition(viewDef)
                }
                else {
                    throw "Exception: Unknown argument type specified in action definition \(argName)"
                }
            }
            else if action.argumentTypes[argName] == ViewArguments.self {
                if let viewArgs = argValue as? ViewArguments {
                    // We explicitly don't copy here. The caller is responsible for uniqueness
                    finalValue = try viewArgs.resolve(item)
                }
                else if let parsedDef = argValue as? CVUParsedDefinition {
                    #warning("This seems to not set the head properly")
                    finalValue = try ViewArguments(parsedDef).resolve(item, viewArgs)
                }
                else {
                    throw "Exception: Could not parse \(argName)"
                }
            }
            else if action.argumentTypes[argName] == Bool.self {
                finalValue = ExprInterpreter.evaluateBoolean(argValue)
            }
            else if action.argumentTypes[argName] == String.self {
                finalValue = ExprInterpreter.evaluateString(argValue)
            }
            else if action.argumentTypes[argName] == Int.self {
                finalValue = ExprInterpreter.evaluateNumber(argValue)
            }
            else if action.argumentTypes[argName] == Double.self {
                finalValue = ExprInterpreter.evaluateNumber(argValue)
            }
            else if action.argumentTypes[argName] == [Action].self {
                finalValue = argValue ?? []
            }
            else if action.argumentTypes[argName] == AnyObject.self {
                finalValue = argValue ?? nil
            }
            else if argValue == nil {
                finalValue = nil
            }
            else {
                throw "Exception: Unknown argument type specified in action definition \(argName):\(action.argumentTypes[argName] ?? Void.self)"
            }

            args[argName] = finalValue
        }

        // Last element of arguments array is the context data item
        args["item"] = item ?? currentView?.resultSet.singletonItem

        return args
    }

    private func executeActionThrows(
        _ action: Action,
        with dataItem: Item? = nil,
        using viewArguments: ViewArguments? = nil
    ) throws {
        // Build arguments dict
        let args = try buildArguments(action, dataItem, viewArguments)

        // TODO: security implications down the line. How can we prevent leakage? Caching needs to be
        //      per context
        action.context = self

        if action.getBool("opensView") {
            if let action = action as? ActionExec {
                try action.exec(args)
            }
            else {
                print("Missing exec for action \(action.name), NOT EXECUTING")
            }
        }
        else {
            // Track state of the action and toggle the state variable
            if let binding = action.binding {
                try binding.toggleBool()

                // TODO: this should be removed and fixed more generally
                scheduleUIUpdate(updateWithAnimation: true)
            }

            if let action = action as? ActionExec {
                try action.exec(args)
            }
            else {
                print("Missing exec for action \(action.name), NOT EXECUTING")
            }
        }
    }

    /// Executes the action as described in the action description
    public func executeAction(
        _ action: Action,
        with dataItem: Item? = nil,
        using viewArguments: ViewArguments? = nil
    ) {
        do {
            if action.getBool("withAnimation") {
                try withAnimation {
                    try executeActionThrows(action, with: dataItem, using: viewArguments)
                }
            }
            else {
                try withAnimation(nil) {
                    try executeActionThrows(action, with: dataItem, using: viewArguments)
                }
            }
        }
        catch {
            // TODO: Log error to the user
            debugHistory.error("\(error)")
        }
    }

    public func executeAction(
        _ actions: [Action],
        with dataItem: Item? = nil,
        using viewArguments: ViewArguments? = nil
    ) {
        for action in actions {
            executeAction(action, with: dataItem, using: viewArguments)
        }
    }
}

public class Action: HashableClass, CVUToString {
    var name: ActionFamily = .noop

    var binding: Expression? {
        if let expr = (values["binding"] ?? defaultValues["binding"]) as? Expression {
            expr.lookup = context.views.lookupValueOfVariables
            expr.execFunc = context.views.executeFunction
            expr.context = context
            return expr
        }
        return nil
    }

    var argumentTypes: [String: Any.Type] {
        defaultValues["argumentTypes"] as? [String: Any.Type] ?? [:]
    }

    var defaultValues: [String: Any?] { [:] }
    let baseValues: [String: Any?] = [
        "icon": "",
        "renderAs": RenderType.button,
        "showTitle": false,
        "opensView": false,
        "color": Color(hex: "#999999"),
        "backgroundColor": Color.white,
        "activeColor": Color(hex: "#ffdb00"),
        "inactiveColor": Color(hex: "#999999"),
        "activeBackgroundColor": Color.white,
        "inactiveBackgroundColor": Color.white,
        "withAnimation": true,
    ]
    var values: [String: Any?] = [:]

    var context: MemriContext

    func isActive() -> Bool? {
        if let binding = binding {
            do { return try binding.isTrue() }
            catch {
                // TODO: error handling
                debugHistory.warn("Could not read boolean value from binding \(binding)")
            }
        }
        return nil
    }

    var color: Color {
        if let active = isActive() {
            if active { return get("activeColor") ?? getColor("color") }
            else { return get("inactiveColor") ?? getColor("color") }
        }
        else {
            return getColor("color")
        }
    }

    var backgroundColor: Color {
        if let active = isActive() {
            if active { return get("activeBackgroundColor") ?? getColor("backgroundolor") }
            else { return get("inactiveBackgroundColor") ?? getColor("backgroundolor") }
        }
        else { return getColor("backgroundColor") }
    }

    public var description: String {
        toCVUString(0, "    ")
    }

    init(_ context: MemriContext, _ name: String, values: [String: Any?] = [:]) {
        self.context = context

        super.init()

        if let actionName = ActionFamily(rawValue: name) { self.name = actionName }
        else { self.name = .noop } // TODO: REfactor: Report error to user

        self.values = values

        if let x = self.values["renderAs"] as? String {
            self.values["renderAs"] = RenderType(rawValue: x)
        }
    }

    required init(_ context: MemriContext, values _: [String: Any?] = [:]) {
        self.context = context
    }

    func get<T>(_ key: String, _ viewArguments: ViewArguments? = nil) -> T? {
        let x: Any? = values[key] ?? defaultValues[key] ?? baseValues[key].flatMap { $0 }
        if let expr = x as? Expression {
            do {
                expr.lookup = context.views.lookupValueOfVariables
                expr.execFunc = context.views.executeFunction
                expr.context = context

                let value = try expr.execForReturnType(T.self, args: viewArguments)
                return value
            }
            catch {
                debugHistory.error("Could not execute Action expression: \(error)")
                // TODO: Refactor: Error reporting
                return nil
            }
        }
        return x as? T
    }

    func getBool(_ key: String, _ viewArguments: ViewArguments? = nil) -> Bool {
        let x: Bool = get(key, viewArguments) ?? false
        return x
    }

    func getString(_ key: String, _ viewArguments: ViewArguments? = nil) -> String {
        let x: String = get(key, viewArguments) ?? ""
        return x
    }

    func getColor(_ key: String, _ viewArguments: ViewArguments? = nil) -> Color {
        let x: Color = get(key, viewArguments) ?? Color.black
        return x
    }

    func getRenderAs(_ viewArguments: ViewArguments? = nil) -> RenderType {
        let x: RenderType = get("renderAs", viewArguments) ?? .button
        return x
    }

    func getArguments(_ item: Item? = nil) -> [String: Any?] {
        do { return try context.buildArguments(self, item) }
        catch {
            debugHistory.warn("Could not parse arguments for popup: \(error)")
            return [:]
        }
    }

    func toCVUString(_ depth: Int, _ tab: String) -> String {
        let tabs = Array(0 ..< depth + 1).map { _ in tab }.joined()
        let tabsEnd = depth > 0 ? Array(0 ..< depth).map { _ in tab }.joined() : ""
        var strBuilder: [String] = []

        if let value = values["binding"] as? Expression {
            strBuilder.append("binding: \(value.description)")
        }

        let keys = values.keys.sorted(by: { $0 < $1 })
        for key in keys {
            if let value = values[key] as? Expression {
                strBuilder.append("\(key): \(value.description)")
            }
            else if let value = values[key] {
                strBuilder.append("\(key): \(CVUSerializer.valueToString(value, depth + 1, tab))")
            }
            else {
                strBuilder.append("\(key): null")
            }
        }

        return strBuilder.count > 0
            ? "\(name) {\n\(tabs)\(strBuilder.joined(separator: "\n\(tabs)"))\n\(tabsEnd)}"
            : "\(name)"
    }

    class func execWithoutThrow(exec: () throws -> Void) {
        do { try exec() }
        catch {
            debugHistory.error("Could not execute action: \(error)")
        }
    }
}

public enum RenderType: String {
    case popup, button, emptytype
}

public enum ActionFamily: String, CaseIterable {
    case back, addItem, openView, openDynamicView, openViewByName, openGroup, toggleEditMode,
        toggleFilterPanel,
        star, showStarred, showContextPane, showOverlay, share, showNavigation, addToPanel,
        duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        delete, setRenderer, select, selectAll, unselectAll, showAddLabel, openLabelView,
        showSessionSwitcher, forward, forwardToFront, backAsSession, openSession, openSessionByName,
        link, closePopup, unlink, multiAction, noop, runIndexer, runImporter,
        setProperty, setSetting

    func getType() -> Action.Type {
        switch self {
        case .back: return ActionBack.self
        case .addItem: return ActionAddItem.self
        case .openView: return ActionOpenView.self
        case .openGroup: return ActionOpenViewWithUIDs.self
        case .openViewByName: return ActionOpenViewByName.self
        case .toggleEditMode: return ActionToggleEditMode.self
        case .toggleFilterPanel: return ActionToggleFilterPanel.self
        case .star: return ActionStar.self
        case .showStarred: return ActionShowStarred.self
        case .showContextPane: return ActionShowContextPane.self
        case .showNavigation: return ActionShowNavigation.self
        case .duplicate: return ActionDuplicate.self
        case .schedule: return ActionSchedule.self
        case .delete: return ActionDelete.self
        case .showSessionSwitcher: return ActionShowSessionSwitcher.self
        case .forward: return ActionForward.self
        case .forwardToFront: return ActionForwardToFront.self
        case .backAsSession: return ActionBackAsSession.self
        case .openSession: return ActionOpenSession.self
        case .openSessionByName: return ActionOpenSessionByName.self
        case .closePopup: return ActionClosePopup.self
        case .link: return ActionLink.self
        case .unlink: return ActionUnlink.self
        case .multiAction: return ActionMultiAction.self
        case .runIndexer: return ActionRunIndexer.self
        case .runImporter: return ActionRunImporter.self
        case .setProperty: return ActionSetProperty.self
        case .setSetting: return ActionSetSetting.self
        case .noop: fallthrough
        default: return ActionNoop.self
        }
    }
}

#warning(
    "Check that the CVU validator is called. somehow with viewName missing defaults still passed"
)
public enum ActionProperties: String, CaseIterable {
    case name, arguments, binding, icon, renderAs, showTitle, opensView, color,
        backgroundColor, inactiveColor, activeBackgroundColor, inactiveBackgroundColor, title
    // These are arguments
    case viewName, sessionName, view, viewArguments, session, importer, indexer, subject, property,
        value, path, edgeType, distinct, all, actions, item

    func validate(_ key: String, _ value: Any?) -> Bool {
        if value is Expression { return true }

        // TODO: test the actions of each specific Action instead of a check for all of them

        let prop = ActionProperties(rawValue: key)
        switch prop {
        case .name, .path, .property, .edgeType, .viewName, .sessionName, .title,
             .showTitle, .icon: return value is String
        case .renderAs: return value is RenderType
        case .opensView, .distinct, .all: return value is Bool
        case .color, .backgroundColor, .inactiveColor, .activeBackgroundColor,
             .inactiveBackgroundColor:
            return value is Color
        case .value: return true // AnyObject is always true
        case .subject, .importer, .indexer, .item: return value is Item
        case .viewArguments: return value is CVUParsedObjectDefinition || value is [String: Any?]
        case .view: return value is CVUParsedViewDefinition || value is [String: Any?]
        case .session: return value is CVUParsedSessionDefinition || value is [String: Any?]
        case .actions: return value is [Action]
        default: return false
        }
    }
}

protocol ActionExec {
    func exec(_ arguments: [String: Any?]) throws
}

#warning("Make this Subscriptable and add to expression docs on the wiki")
class ActionBack: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "chevron.left",
        "opensView": true,
        "color": Color(hex: "#434343"),
        "inactiveColor": Color(hex: "#434343"),
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "back", values: values)
    }

    func exec(_: [String: Any?]) throws {
        if let session = context.currentSession {
            if session.currentViewIndex == 0 {
                print("Warn: Can't go back. Already at earliest view in session")
            }
            else {
                session.currentViewIndex -= 1
                context.scheduleCascadableViewUpdate()
            }
        }
        else {
            // TODO: Error Handling?
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionBack(context).exec(arguments) }
    }
}

class ActionAddItem: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "plus",
        "argumentTypes": ["template": ItemFamily.self],
        "opensView": true,
        "color": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343"),
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "addItem", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        if let dataItem = arguments["template"] as? Item {
            //			// Copy template
            //			let copy = try context.cache.duplicate(dataItem)
            #warning("Test that this creates a unique node")
            // Open view with the now managed copy
            try ActionOpenView.exec(context, ["item": dataItem])
        }
        else {
            // TODO: Error handling
            // TODO: User handling
            throw "Cannot open view, no dataItem passed in arguments"
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionAddItem(context).exec(arguments) }
    }
}

class ActionOpenView: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["view": CVUStateDefinition.self, "viewArguments": ViewArguments.self],
        "withAnimation": false,
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "openView", values: values)
    }

    func openView(
        _ context: MemriContext,
        view: CVUStateDefinition,
        with arguments: ViewArguments? = nil
    ) throws {
        if let session = context.currentSession {
            // Add view to session
            try session.setCurrentView(view, arguments)
        }
        else {
            // TODO: Error Handling
            debugHistory.error("No session is active on context")
        }
    }

    private func openView(
        _ context: MemriContext,
        _ item: Item,
        with arguments: ViewArguments? = nil
    ) throws {
        guard let uid = item.uid.value else { throw "Uninitialized item" }

        // Create a new view
        let view = try Cache.createItem(CVUStateDefinition.self, values: [
            "type": "view",
            "selector": "[view]",
            "definition": """
                [view] {
                    [datasource = pod] {
                        query: "\(item.genericType) AND uid = \(uid)"
                    }
                }
            """,
        ])

        // Open the view
        try openView(context, view: view, with: arguments)
    }

    func exec(_ arguments: [String: Any?]) throws {
        //        let selection = context.cascadableView.userState.get("selection") as? [Item]
        let item = arguments["item"] as? Item
        let viewArguments = arguments["viewArguments"] as? ViewArguments

        // if let selection = selection, selection.count > 0 { self.openView(context, selection) }
        if let sessionView = arguments["view"] as? CVUStateDefinition {
            try openView(context, view: sessionView, with: viewArguments)
        }
        else if let item = item as? CVUStateDefinition {
            try openView(context, view: item, with: viewArguments)
        }
        else if let item = item {
            try openView(context, item, with: viewArguments)
        }
        else {
            // TODO: Error handling
            throw "Cannot execute ActionOpenView, arguments require a SessionView. passed arguments:\n \(arguments), "
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionOpenView(context).exec(arguments) }
    }
}

class ActionOpenViewByName: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["viewName": String.self, "viewArguments": ViewArguments.self],
        "withAnimation": false,
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "openViewByName", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments

        if let name = arguments["viewName"] as? String {
            // Fetch a dynamic view based on its name
            guard let stored = context.views.fetchDefinitions(name: name, type: "view").first else {
                throw "No view found with the name \(name)"
            }

            do {
                let view = try context.views.getViewStateDefinition(from: stored)
                try ActionOpenView(context).openView(context, view: view, with: viewArguments)
            }
            catch {
                throw "\(error) for \(name)"
            }
        }
        else {
            // TODO: Error Handling
            throw "Cannot execute ActionOpenViewByName, no name found in arguments."
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionOpenViewByName(context).exec(arguments) }
    }
}

class ActionOpenViewWithUIDs: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["view": CVUStateDefinition.self, "viewArguments": ViewArguments.self],
        "withAnimation": false,
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "openView", values: values)
    }

    func openView(
        _ context: MemriContext,
        view: CVUStateDefinition,
        with arguments: ViewArguments? = nil
    ) throws {
        if let session = context.currentSession {
            // Add view to session
            try session.setCurrentView(view, arguments)
        }
        else {
            // TODO: Error Handling
            debugHistory.error("No session is active on context")
        }
    }

    private func openView(
        _ context: MemriContext,
        itemType: String,
        _ uids: [Int],
        with arguments: ViewArguments? = nil
    ) throws {
		
		#warning("@Ruben - this action isn't working since recent changes. The only relevant code for when you merge into the `OpenView` action is constructing the UID query (IN vs =)")
		guard let firstUID = uids.first else { throw "No UIDs specified" }
		// note that the `IN` selector requires >1 item or it will throw an exception (use `=` if one item)
		let uidQueryString = uids.count > 1 ? "uid IN {\(uids.map { String($0) }.joined(separator: ","))}" : "uid = \(firstUID)"
		

        // Create a new view
        let view = try Cache.createItem(CVUStateDefinition.self, values: [
            "type": "view",
            "selector": "[view]",
            "definition": """
                [view] {
                    [datasource = pod] {
                        query: "\(itemType) AND \(uidQueryString)"
                    }
                }
            """,
        ])

        // Open the view
        try openView(context, view: view, with: arguments)
    }

    func exec(_ arguments: [String: Any?]) throws {
        //        let selection = context.cascadingView.userState.get("selection") as? [Item]
        guard
            let uids = arguments["uids"] as? [Int],
            let itemType = arguments["itemType"] as? String
        else { return }

        let viewArguments = arguments["viewArguments"] as? ViewArguments

        try? openView(context, itemType: itemType, uids, with: viewArguments)
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionOpenView(context).exec(arguments) }
    }
}

class ActionToggleEditMode: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "pencil",
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343"),
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "toggleEditMode", values: values)
    }

    func exec(_: [String: Any?]) throws {
        // Do Nothing
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionToggleEditMode(context).exec(arguments) }
    }
}

class ActionToggleFilterPanel: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "rhombus.fill",
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f"),
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "toggleFilterPanel", values: values)
    }

    func exec(_: [String: Any?]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionToggleFilterPanel(context).exec(arguments) }
    }
}

class ActionStar: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "star.fill",
        "binding": Expression("dataItem.starred"),
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "star", values: values)
    }

    // TODO: selection handling for binding
    func exec(_: [String: Any?]) throws {
        //        if let item = arguments["item"] as? Item {
        //            var selection:[Item] = context.cascadableView.userState.get("selection") ?? []
        //            let toValue = !item.starred
//
        //            if !selection.contains(item) {
        //                selection.append(item)
        //            }
//
        //            realmWrite(context.cache.realm, {
        //                for item in selection { item.starred = toValue }
        //            })
//
        //            // TODO if starring is ever allowed in a list resultset view,
        //            // it won't be updated as of now
        //        }
        //        else {
        //            // TODO Error handling
        //            throw "Cannot execute ActionStar, missing dataItem in arguments."
        //        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionStar(context).exec(arguments) }
    }
}

class ActionShowStarred: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "star.fill",
        "binding": Expression("view.userState.showStarred"),
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00"),
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "showStarred", values: values)
    }

    func exec(_: [String: Any?]) throws {
        do {
            if let binding = self.binding, try !binding.isTrue() {
                try ActionOpenViewByName.exec(context, ["viewName": "filter-starred"])
                try binding.toggleBool()
            }
            else {
                // Go back to the previous view
                try ActionBack.exec(context, [:])
            }
        }
        catch {
            // TODO: Error Handling
            throw "Cannot execute ActionShowStarred: \(error)"
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionShowStarred(context).exec(arguments) }
    }
}

class ActionShowContextPane: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "ellipsis",
        "binding": Expression("currentSession.showContextPane"),
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "showContextPane", values: values)
    }

    func exec(_: [String: Any?]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionShowContextPane(context).exec(arguments) }
    }
}

class ActionShowNavigation: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "line.horizontal.3",
        "binding": Expression("context.showNavigation"),
        "inactiveColor": Color(hex: "#434343"),
        "withAnimation": true
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "showNavigation", values: values)
    }

    func exec(_: [String: Any?]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionShowNavigation(context).exec(arguments) }
    }
}

class ActionSchedule: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "alarm",
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "schedule", values: values)
    }

    func exec(_: [String: Any?]) throws {
        //        ActionSchedule.exec(context, arguments:arguments)
    }

    class func exec(_: MemriContext, _: [String: Any?]) throws {}
}

class ActionShowSessionSwitcher: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "icon": "ellipsis",
        "binding": Expression("context.showSessionSwitcher"),
        "color": Color(hex: "#CCC"),
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "showSessionSwitcher", values: values)
    }

    func exec(_: [String: Any?]) throws {
        //        ActionShowSessionSwitcher.exec(context, arguments:arguments)
    }

    class func exec(_: MemriContext, _: [String: Any?]) throws {
        // Do Nothing
    }
}

class ActionForward: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "forward", values: values)
    }

    func exec(_: [String: Any?]) throws {
        if let session = context.currentSession {
            if session.currentViewIndex == session.views.count - 1 {
                print("Warn: Can't go forward. Already at last view in session")
            }
            else {
                session.currentViewIndex += 1
                context.scheduleCascadableViewUpdate()
            }
        }
        else {
            // TODO: Error handling?
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionForward(context).exec(arguments) }
    }
}

class ActionForwardToFront: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "forwardToFront", values: values)
    }

    func exec(_: [String: Any?]) throws {
        if let session = context.currentSession {
            session.currentViewIndex = session.views.count - 1
            context.scheduleCascadableViewUpdate()
        }
        else {
            // TODO: Error handling
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionForwardToFront(context).exec(arguments) }
    }
}

class ActionBackAsSession: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "opensView": true,
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "backAsSession", values: values)
    }

    func exec(_: [String: Any?]) throws {
        if let session = context.currentSession {
            if session.currentViewIndex == 0 {
                throw "Warn: Can't go back. Already at earliest view in session"
            }
            else {
                if
                    let state = session.state,
                    let copy = try context.cache.duplicate(state as Item) as? CVUStateDefinition {
                    for view in session.views {
                        if
                            let state = view.state,
                            let viewCopy = try context.cache
                            .duplicate(state as Item) as? CVUStateDefinition {
                            _ = try copy.link(viewCopy, type: "view", sequence: .last)
                        }
                    }

                    try ActionOpenSession.exec(context, ["session": copy])
                    try ActionBack.exec(context, [:])
                }
                else {
                    // TODO: Error handling
                    throw ActionError
                        .Warning(
                            message: "Cannot execute ActionBackAsSession, duplicating currentSession resulted in a different type"
                        )
                }
            }
        }
        else {
            // TODO: Error handling
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionBackAsSession(context).exec(arguments) }
    }
}

class ActionOpenSession: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["session": CVUStateDefinition.self, "viewArguments": ViewArguments.self],
        "opensView": true,
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "openSession", values: values)
    }

    func openSession(_ session: CVUStateDefinition, _ args: ViewArguments? = nil) throws {
        let sessions = context.sessions

        try sessions.setCurrentSession(session)
        try sessions.currentSession?.setCurrentView(nil, args)
    }
    
    func openSession(_ session: Session, _ args: ViewArguments? = nil) throws {
        let sessions = context.sessions

        try sessions.setCurrentSession(session)
        try sessions.currentSession?.setCurrentView(nil, args)
    }

    //    func openSession(_ context: MemriContext, _ name:String, _ variables:[String:Any]? = nil) throws {
//
    //        // TODO: This should not fetch the session from named sessions
    //        //       but instead load a sessionview that loads the named sessions by
    //        //       computing them (implement viewFromSession that is used in dynamic
    //        //       view to sessionview
//
    //        // Fetch a dynamic view based on its name
    //    }

    /// Adds a view to the history of the currentSession and displays it. If the view was already part of the currentSession.views it
    /// reorders it on top
    func exec(_ arguments: [String: Any?]) throws {
        let args = arguments["viewArguments"] as? ViewArguments

        if let item = arguments["session"] {
            if let session = item as? CVUStateDefinition {
                try openSession(session, args)
            }
            else if let session = item as? Session {
                try openSession(session, args)
            }
            else {
                // TODO: Error handling
                throw "Cannot execute openSession 'session' argmument cannot be cast to Session"
            }
        }
        else {
            if let session = arguments["item"] as? CVUStateDefinition {
                try openSession(session, args)
            }

            // TODO: Error handling
            throw "Cannot execute openSession, no session passed"
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionOpenSession(context).exec(arguments) }
    }
}

// TODO: How to deal with viewArguments in sessions
class ActionOpenSessionByName: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["sessionName": String.self, "viewArguments": ViewArguments.self],
        "opensView": true,
        "withAnimation": false,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "openSessionByName", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments

        guard let name = arguments["sessionName"] as? String else {
            // TODO: Error handling "No name given"
            throw "Cannot execute ActionOpenSessionByName, no name defined in viewArguments"
        }

        do {
            guard let stored = context.views.fetchDefinitions(name: name, type: "session").first
            else {
                throw "Exception: Cannot open session with name \(name). Unable to find view."
            }

            let session = try CVUStateDefinition.fromCVUStoredDefinition(stored)

            // Open the view
            try ActionOpenSession(context).openSession(session, viewArguments)
        }
        catch {
            // TODO: Log error, Error handling
            throw "Exception: Cannot open session by name \(name): \(error)"
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionOpenSessionByName(context).exec(arguments) }
    }
}

class ActionDelete: Action, ActionExec {
    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "delete", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
//
        //        // TODO this should happen automatically in ResultSet
        //        //        self.context.items.remove(atOffsets: indexSet)
        //        let indexSet = arguments["indices"] as? IndexSet
        //        if let indexSet = indexSet{
        //            var items:[Item] = []
        //            for i in indexSet {
        //                let item = context.items[i]
        //                items.append(item)
        //            }
        //        }

        if
            let selection = context.currentView?.userState.get("selection", type: [Item].self),
            !selection.isEmpty {
            try context.cache.delete(selection)
            context.scheduleCascadableViewUpdate(immediate: true)
        }
        else if let dataItem = arguments["item"] as? Item {
            try context.cache.delete(dataItem)
            context.scheduleCascadableViewUpdate(immediate: true)
        }
        else {
            // TODO: Erorr handling
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionDelete(context).exec(arguments) }
    }
}

class ActionSelectAll: Action, ActionExec {
    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "selectAll", values: values)
    }

    func exec(_: [String: Any?]) throws {
        context.setSelection(context.items)
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionSelectAll(context).exec(arguments) }
    }
}

class ActionDuplicate: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["item": ItemFamily.self],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "duplicate", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        if
            let selection = context.currentView?.userState.get("selection", type: [Item].self),
            selection.count > 0 {
            try selection.forEach { item in try ActionAddItem.exec(context, ["item": item]) }
        }
        else if let item = arguments["item"] as? Item {
            try ActionAddItem.exec(context, ["template": item])
        }
        else {
            // TODO: Error handling
            throw "Cannot execute ActionDupliate. The user either needs to make a selection, or a dataItem needs to be passed to this call."
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionDuplicate(context).exec(arguments) }
    }
}

class ActionRunImporter: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["importer": ItemFamily.self],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "runImporter", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        // TODO: parse options

        if let run = arguments["importer"] as? ImporterRun {
            guard let uid = run.uid.value else { throw "Uninitialized import run" }

            context.podAPI.runImporter(uid) { error, _ in
                if let error = error {
                    print("Cannot execute actionImport: \(error)")
                }
            }
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionRunImporter(context).exec(arguments) }
    }
}

class ActionRunIndexer: Action, ActionExec {
    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "runIndexer", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        // TODO: parse options
        guard let run = arguments["indexerRun"] as? memri.IndexerRun else {
            throw "Exception: no indexer run passed"
        }

        if run.indexer?.runDestination == "ios" {
            try runLocal(run)
        }
        else {
            run.set("progress", 0)
            context.scheduleUIUpdate()
            // TODO: indexerInstance items should have been automatically created already by now

            context.cache.isOnRemote(run) { error in
                if error != nil {
                    // How to handle??
                    #warning("Look at this when implementing syncing")
                    debugHistory.error("Polling timeout. All polling services disabled")
                    return
                }

                guard let uid = run.uid.value else {
                    debugHistory.error("Item does not have a uid")
                    return
                }

                // Start indexer process
                self.context.podAPI.runIndexer(uid) { error, _ in
                    if error == nil {
                        var watcher: AnyCancellable?
                        watcher = self.context.cache.subscribe(to: run).sink { item in
                            if let progress: Int = item.get("progress") {
                                self.context.scheduleUIUpdate()

                                print("progress \(progress)")

                                if progress >= 100 {
                                    watcher?.cancel()
                                    watcher = nil
                                }
                            }
                            else {
                                debugHistory
                                    .error(
                                        "ERROR, could not get progress: \(String(describing: error))"
                                    )
                                watcher?.cancel()
                                watcher = nil
                            }
                        }
                    }
                    else {
                        // TODO: User Error handling
                        debugHistory.error("Could not start indexer: \(error ?? "")")
                    }
                }
            }
        }
    }

    func runLocal(_ indexerInstance: IndexerRun) throws {
        guard let query: String = indexerInstance.indexer?.get("query") else {
            throw "Cannot execute IndexerRun \(indexerInstance), no query specified"
        }
        let ds = Datasource(query: query)

        try context.cache.query(ds) { (_, result) -> Void in
            if let items = result {
                try self.context.indexerAPI.execute(indexerInstance, items)
            }
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionRunIndexer(context).exec(arguments) }
    }
}

class ActionClosePopup: Action, ActionExec {
    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "closePopup", values: values)
    }

    func exec(_: [String: Any?]) throws {
        context.closeLastInStack()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionClosePopup(context).exec(arguments) }
    }
}

class ActionSetProperty: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": [
            "subject": ItemFamily.self,
            "property": String.self,
            "value": AnyObject.self,
        ],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "setProperty", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        guard let subject = arguments["subject"] as? Item else {
            throw "Exception: subject is not set"
        }

        guard let propertyName = arguments["property"] as? String else {
            throw "Exception: property is not set to a string"
        }

        subject
            .set(propertyName,
                 arguments["value"].flatMap { $0 }) // Flatmap removes the double optional

        // TODO: refactor
        ((context as? SubContext)?.parent ?? context).scheduleUIUpdate()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionSetProperty(context).exec(arguments) }
    }
}

class ActionSetSetting: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["path": String.self, "value": Any.self],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "setSetting", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        guard let path = arguments["path"] as? String else {
            throw "Exception: missing path to set setting"
        }

        let value = arguments["value"]

        Settings.shared.set(path, value as Any)

        // TODO: refactor
        ((context as? SubContext)?.parent ?? context).scheduleUIUpdate()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionSetSetting(context).exec(arguments) }
    }
}

class ActionLink: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": [
            "subject": ItemFamily.self,
            "edgeType": String.self,
            "distinct": Bool.self,
        ],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "link", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        guard let subject = arguments["subject"] as? Item else {
            throw "Exception: subject is not set"
        }

        guard let edgeType = arguments["edgeType"] as? String else {
            throw "Exception: edgeType is not set to a string"
        }

        guard let selected = arguments["item"] as? Item else {
            throw "Exception: selected data item is not passed"
        }

        let distinct = arguments["distinct"] as? Bool ?? false

        _ = try subject.link(selected, type: edgeType, distinct: distinct)

        // TODO: refactor
        ((context as? SubContext)?.parent ?? context).scheduleUIUpdate()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionLink(context).exec(arguments) }
    }
}

class ActionUnlink: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["subject": ItemFamily.self, "edgeType": String.self, "all": Bool.self],
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "unlink", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        guard let subject = arguments["subject"] as? Item else {
            throw "Exception: subject is not set"
        }
        guard let edgeType = arguments["edgeType"] as? String else {
            throw "Exception: edgeType is not set to a string"
        }

        guard let selected = arguments["item"] as? Item else {
            throw "Exception: selected data item is not passed"
        }

        let all = arguments["all"] as? Bool ?? false

        _ = try subject.unlink(selected, type: edgeType, all: all)

        // TODO: refactor
        ((context as? SubContext)?.parent ?? context).scheduleUIUpdate()
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionUnlink(context).exec(arguments) }
    }
}

class ActionMultiAction: Action, ActionExec {
    override var defaultValues: [String: Any?] { [
        "argumentTypes": ["actions": [Action].self],
        "opensView": true,
    ] }

    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "multiAction", values: values)
    }

    func exec(_ arguments: [String: Any?]) throws {
        guard let actions = arguments["actions"] as? [Action] else {
            throw "Cannot execute ActionMultiAction: no actions passed in arguments"
        }

        for action in actions {
            context.executeAction(action, with: arguments["item"] as? Item)
        }
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionMultiAction(context).exec(arguments) }
    }
}

class ActionNoop: Action, ActionExec {
    required init(_ context: MemriContext, values: [String: Any?] = [:]) {
        super.init(context, "noop", values: values)
    }

    func exec(_: [String: Any?]) throws {
        // do nothing
    }

    class func exec(_ context: MemriContext, _ arguments: [String: Any?]) throws {
        execWithoutThrow { try ActionClosePopup(context).exec(arguments) }
    }
}
