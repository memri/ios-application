//
//  Action.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

extension MemriContext {
    
    private func getDataItem(_ dict:[String:Any], _ dataItem:DataItem?,
                             _ viewArguments:ViewArguments? = nil) throws -> DataItem {
        
        // TODO refactor: move to function
        guard let stringType = dict["type"] as? String else {
            throw "Missing type attribute to indicate the type of the data item"
        }
        
        guard let family = DataItemFamily(rawValue: stringType) else {
            throw "Cannot find find family \(stringType)"
        }
        
        guard let ItemType = DataItemFamily.getType(family)() as? Object.Type else {
            throw "Cannot find family \(stringType)"
        }
        
        var initArgs = dict
        initArgs.removeValue(forKey: "type")

        guard let item = ItemType.init() as? DataItem else {
            throw "Cannot cast type \(ItemType) to DataItem"
        }
        
        // TODO: fill item
        for prop in item.objectSchema.properties {
            if prop.name != ItemType.primaryKey(),
                let inputValue = initArgs[prop.name] {
                let propValue: Any

                if let expr = inputValue as? Expression {
                    if let v = viewArguments {
                        propValue = try expr.execute(v) as Any
                    }
                    else {
                        let viewArgs = ViewArguments(cascadingView.viewArguments.asDict())
                        viewArgs.set(".", dataItem)
                        propValue = try expr.execute(viewArgs) as Any
                    }
                }
                else {
                    propValue = inputValue
                }
                
                item.set(prop.name, propValue)
            }
        }
        
        return item
    }
    
    private func buildArguments(_ action:Action, _ dataItem:DataItem?,
                                _ viewArguments:ViewArguments? = nil) throws -> [String: Any] {
        
        var args = [String: Any]()
        for (argName, inputValue) in action.arguments {
            var argValue: Any?
            
            // preprocess arg
            if let expr = inputValue as? Expression {
                argValue = try expr.execute(viewArguments ?? cascadingView.viewArguments) as Any
            }
            else {
                argValue = inputValue
            }
            
            var finalValue:Any? = ""
            
            // TODO add cases for argValue = DataItem, ViewArgument
            if let dataItem = argValue as? DataItem {
                finalValue = dataItem
            }
            else if let dict = argValue as? [String: Any] {
                if action.argumentTypes[argName] == ViewArguments.self {
                    finalValue = ViewArguments(dict)
                }
                else if action.argumentTypes[argName] == DataItemFamily.self {
                    finalValue = try getDataItem(dict, dataItem, viewArguments)
                }
                else if action.argumentTypes[argName] == SessionView.self {
                    let viewDef = CVUParsedViewDefinition(DataItem.generateUUID())
                    viewDef.parsed = dict
                    
                    finalValue = SessionView(value: ["viewDefinition": viewDef])
                }
                else {
                    throw "Does not recognize argumentType \(argName)"
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
            // TODO are nil values allowed?
            else if argValue == nil {
                finalValue = nil
            }
            else {
                throw "Does not recognize argumentType \(argName):\(action.argumentTypes[argName] ?? Void.self)"
            }
            
            args[argName] = finalValue
        }
        
        // Last element of arguments array is the context data item
        args["dataItem"] = dataItem ?? cascadingView.resultSet.singletonItem as Any
        
        return args
    }
    
    private func executeActionThrows(_ action:Action, with dataItem:DataItem? = nil,
                                     using viewArguments:ViewArguments? = nil) throws {
        // Build arguments dict
        let args = try buildArguments(action, dataItem, viewArguments)
        
        // TODO security implications down the line. How can we prevent leakage? Caching needs to be
        //      per context
        action.context = self
        
        if action.getBool("opensView") {
            let binding = action.binding
            
            if let action = action as? ActionExec {
                try action.exec(args)
                
                // Toggle a state value, for instance the starred button in the view (via dataItem.starred)
                if let binding = binding {
                    try binding.toggleBool()
                }
            }
            else {
                print("Missing exec for action \(action.name), NOT EXECUTING")
            }
        }
        else {
            
            // Track state of the action and toggle the state variable
            if let binding = action.binding {
                try binding.toggleBool()
                
                // TODO this should be removed and fixed more generally
                self.scheduleUIUpdate(immediate: true)
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
    public func executeAction(_ action:Action, with dataItem:DataItem? = nil,
                              using viewArguments:ViewArguments? = nil) {
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
        catch let error {
            // TODO Log error to the user
            debugHistory.error("\(error)")
        }
    }
    public func executeAction(_ actions:[Action], with dataItem:DataItem? = nil,
                              using viewArguments:ViewArguments? = nil) {
        
        for action in actions {
            self.executeAction(action, with: dataItem, using: viewArguments)
        }
    }
}

public class Action : HashableClass, CVUToString {
    var name:ActionFamily = .noop
    var arguments: [String: Any?] = [:]
    
    var binding:Expression? {
        if let expr = (values["binding"] ?? defaultValues["binding"]) as? Expression {
            expr.lookup = context.views.lookupValueOfVariables
            expr.execFunc = context.views.executeFunction
            expr.context = context
            return expr
        }
        return nil
    }
    
    var argumentTypes:[String: Any.Type] {
        defaultValues["argumentTypes"] as? [String: Any.Type] ?? [:]
    }
    
    var defaultValues:[String:Any] { [:] }
    let baseValues:[String:Any] = [
        "icon": "exclamationmark.triangle",
        "renderAs": RenderType.button,
        "showTitle": false,
        "opensView": false,
        "color": Color(hex: "#999999"),
        "backgroundColor": Color.white,
        "activeColor": Color(hex: "#ffdb00"),
        "inactiveColor": Color(hex: "#999999"),
        "activeBackgroundColor": Color.white,
        "inactiveBackgroundColor": Color.white,
        "withAnimation": true
    ]
    var values:[String:Any?] = [:]
    
    var context:MemriContext
    
    func isActive() -> Bool? {
        if let binding = binding {
            do { return try binding.isTrue() }
            catch {
                // TODO error handling
                debugHistory.warn("Could not read boolean value from binding \(binding)")
            }
        }
        return nil
    }
    
    var color: Color {
        if let active = isActive() {
            if active { return self.get("activeColor") ?? self.getColor("color")}
            else { return self.get("inactiveColor") ?? self.getColor("color")}
        }
        else {
            return self.getColor("color")
        }
    }
    
    var backgroundColor: Color {
        if let active = isActive() {
            if active { return self.get("activeBackgroundColor") ?? self.getColor("backgroundolor")}
            else { return self.get("inactiveBackgroundColor") ?? self.getColor("backgroundolor")}
        }
        else { return self.getColor("backgroundColor") }
    }
    
    public var description: String {
        toCVUString(0, "    ")
    }
    
    init(_ context:MemriContext, _ name:String, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]) {
        self.context = context
        
        super.init()
        
        if let actionName = ActionFamily(rawValue: name) { self.name = actionName }
        else { self.name = .noop } // TODO REfactor: Report error to user
        
        self.arguments = arguments ?? self.arguments
        self.values = values
        
        if let x = self.values["renderAs"] as? String {
            self.values["renderAs"] = RenderType(rawValue: x)
        }
    }
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]) {
        self.context = context
    }
    
    func get<T>(_ key:String, _ viewArguments:ViewArguments? = nil) -> T? {
        let x:Any? = values[key] ?? defaultValues[key] ?? baseValues[key]
        if let expr = x as? Expression {
            do {
                expr.lookup = context.views.lookupValueOfVariables
                expr.execFunc = context.views.executeFunction
                expr.context = context
                
                let value:T? = try expr.execForReturnType(viewArguments)
                return value
            }
            catch {
                print("ACTION ERROR: \(error)")
                // TODO Refactor: Error reporting
                return nil
            }
        }
        return x as? T
    }
    
    func getBool(_ key:String, _ viewArguments:ViewArguments? = nil) -> Bool {
        let x:Bool = get(key, viewArguments) ?? false
        return x
    }
    
    func getString(_ key:String, _ viewArguments:ViewArguments? = nil) -> String {
        let x:String = get(key, viewArguments) ?? ""
        return x
    }
    
    func getColor(_ key:String, _ viewArguments:ViewArguments? = nil) -> Color {
        let x:Color = get(key, viewArguments) ?? Color.black
        return x
    }
    
    func getRenderAs(_ viewArguments:ViewArguments? = nil) -> RenderType {
        let x:RenderType = get("renderAs", viewArguments) ?? .button
        return x
    }
    
    func toCVUString(_ depth:Int, _ tab:String) -> String {
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        var strBuilder:[String] = []
        
        if arguments.count > 0 {
            strBuilder.append("arguments: \(CVUSerializer.dictToString(arguments, depth + 1, tab))")
        }
        
        if let value = values["binding"] as? Expression {
            strBuilder.append("binding: \(value.description)")
        }
        
        let keys = values.keys.sorted(by: { $0 < $1 })
        for key in keys {
            if let value = values[key] as? Expression {
                strBuilder.append("\(key): \(value.description)")
            }
            else if let value = values[key] {
                strBuilder.append("\(key): \(CVUSerializer.valueToString(value, depth, tab))")
            }
            else {
                strBuilder.append("\(key): null")
            }
        }
        
        return strBuilder.count > 0
            ? "\(name) {\n\(tabs)\(strBuilder.joined(separator: "\n\(tabs)"))\n\(tabsEnd)}"
            : "\(name)"
    }
    
    class func execWithoutThrow(exec:() throws -> Void) {
        do { try exec() }
        catch let error {
            debugHistory.error("Could not execute action: \(error)")
        }
    }
}

public enum RenderType: String{
    case popup, button, emptytype
}

public enum ActionFamily: String, CaseIterable {
    case back, addDataItem, openView, openDynamicView, openViewByName, toggleEditMode, toggleFilterPanel,
        star, showStarred, showContextPane, showOverlay, share, showNavigation, addToPanel, duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        delete, setRenderer, select, selectAll, unselectAll, showAddLabel, openLabelView,
        showSessionSwitcher, forward, forwardToFront, backAsSession, openSession, openSessionByName,
        link, closePopup, unlink, multiAction, noop

    func getType() -> Action.Type {
        switch self {
        case .back: return ActionBack.self
        case .addDataItem: return ActionAddDataItem.self
        case .openView: return ActionOpenView.self
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
        case .noop: fallthrough
        default: return ActionNoop.self
        }
    }
}

public enum ActionProperties : String, CaseIterable {
    case name, arguments, binding, icon, renderAs, showTitle, opensView, color,
         backgroundColor, inactiveColor, activeBackgroundColor, inactiveBackgroundColor, title
    
    func validate(_ key:String, _ value:Any?) -> Bool {
        if value is Expression { return true }
        
        let prop = ActionProperties(rawValue: key)
        switch prop {
        case .name: return value is String
        case .arguments: return value is [Any?] // TODO do better by implementing something similar to executeAction
        case .renderAs: return value is RenderType
        case .title, .showTitle, .icon: return value is String
        case .opensView: return value is Bool
        case .color, .backgroundColor, .inactiveColor, .activeBackgroundColor, .inactiveBackgroundColor:
            return value is Color
        default: return false
        }
    }
}

protocol ActionExec {
    func exec(_ arguments:[String: Any]) throws
}

class ActionBack : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "chevron.left",
        "opensView": true,
        "color": Color(hex: "#434343"),
        "inactiveColor": Color(hex: "#434343"),
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "back", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = context.currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            realmWriteIfAvailable(context.realm, { session.currentViewIndex -= 1 })
            context.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ context:MemriContext, arguments:[String: Any]) throws {
        execWithoutThrow { try ActionBack(context).exec(arguments) }
    }
}
class ActionAddDataItem : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "plus",
        "argumentTypes": ["template": DataItemFamily.self],
        "opensView": true,
        "color": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "addDataItem", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let dataItem = arguments["template"] as? DataItem {
            // Copy template
            let copy = try context.cache.duplicate(dataItem)
            
            // Add the new item to the cache
            _ = try context.cache.addToCache(copy)
            
            // Open view with the now managed copy
            try ActionOpenView.exec(context, ["dataItem": copy])
        }
        else {
            // TODO Error handling
            // TODO User handling
            throw "Cannot open view, no dataItem passed in arguments"
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionAddDataItem(context).exec(arguments) }
    }
}


class ActionOpenView : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["view": SessionView.self, "viewArguments": ViewArguments.self],
        "withAnimation": false,
        "opensView": true
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "openView", arguments:arguments, values:values)
    }
    
    func openView(_ context: MemriContext, view: SessionView, with arguments: ViewArguments? = nil) throws {
        let session = context.currentSession
        
        // Merge arguments into view
        if let dict = arguments?.asDict() {
            if let viewArguments = view.viewArguments {
                view.viewArguments = ViewArguments(viewArguments.asDict()
                    .merging(dict, uniquingKeysWith: { current, new in new }) as [String : Any])
            }
        }
        
        // Add view to session
        session.setCurrentView(view)
    
        // Set accessed date to now
        view.access()
    
        // Recompute view
        try context.updateCascadingView() // scheduleCascadingViewUpdate()
    }
    
    private func openView(_ context: MemriContext, _ item: DataItem, with arguments: ViewArguments? = nil) throws {
        // Create a new view
        let view = SessionView(value: ["datasource": Datasource(value: [
            // Set the query options to load the item
            "query": "\(item.genericType) AND memriID = '\(item.memriID)'"
        ])])
    
        // Open the view
        try self.openView(context, view:view, with: arguments)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        let selection = context.cascadingView.userState.get("selection") as? [DataItem]
        let dataItem = arguments["dataItem"] as? DataItem
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        
        // if let selection = selection, selection.count > 0 { self.openView(context, selection) }
        if let sessionView = arguments["view"] as? SessionView {
            try self.openView(context, view: sessionView, with: viewArguments)
        }
        else if let item = dataItem as? SessionView {
            try self.openView(context, view: item, with: viewArguments)
        }
        else if let item = dataItem {
            try self.openView(context, item, with: viewArguments)
        }
        else {
            // TODO Error handling
            throw "Cannot execute ActionOpenView, arguments require a SessionView. passed arguments:\n \(arguments), "
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenView(context).exec(arguments) }
    }
}
class ActionOpenViewByName : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": ViewArguments.self],
        "withAnimation": false,
        "opensView": true
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "openViewByName", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        if let name = arguments["name"] as? String {
            // Fetch a dynamic view based on its name
            let stored = context.views.fetchDefinitions(name:name, type:"view").first
            let parsed = try context.views.parseDefinition(stored)
            
            let view = try SessionView.fromCVUDefinition(
                parsed: parsed as? CVUParsedViewDefinition,
                stored: stored,
                viewArguments: viewArguments
            )
            
            try ActionOpenView(context).openView(context, view:view)
        }
        else {
            // TODO Error Handling
            throw "Cannot execute ActionOpenViewByName, no name found in arguments."
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenViewByName(context).exec(arguments) }
    }
}
class ActionToggleEditMode : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "pencil",
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343"),
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "toggleEditMode", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionToggleEditMode(context).exec(arguments) }
    }
}
class ActionToggleFilterPanel : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "rhombus.fill",
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "toggleFilterPanel", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionToggleFilterPanel(context).exec(arguments) }
    }
}
class ActionStar : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "star.fill",
        "binding": Expression("dataItem.starred")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "star", arguments:arguments, values:values)
    }
    
    // TODO selection handling for binding
    func exec(_ arguments:[String: Any]) throws {
//        if let item = arguments["dataItem"] as? DataItem {
//            var selection:[DataItem] = context.cascadingView.userState.get("selection") ?? []
//            let toValue = !item.starred
//
//            if !selection.contains(item) {
//                selection.append(item)
//            }
//
//            realmWriteIfAvailable(context.cache.realm, {
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
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionStar.exec(context, arguments) }
    }
}
class ActionShowStarred : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "star.fill",
        "binding": Expression("view.userState.showStarred"),
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00"),
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "showStarred", arguments:arguments, values:values)
    }

    func exec(_ arguments:[String: Any]) throws {
        do {
            if let binding = self.binding, try !binding.isTrue() {
                try ActionOpenViewByName.exec(context, ["name": "filter-starred"])
                // Open named view 'showStarred'
                // openView("filter-starred", ["stateName": starButton.actionStateName as Any])
            }
            else {
                // Go back to the previous view
                try ActionBack.exec(context, arguments: [:])
            }
        }
        catch {
            // TODO Error Handling
            throw "Cannot execute ActionShowStarred: \(error)"
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowStarred(context).exec(arguments) }
    }
}
class ActionShowContextPane : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "ellipsis",
        "binding": Expression("currentSession.showContextPane")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "showContextPane", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowContextPane(context).exec(arguments) }
    }
}
class ActionShowNavigation : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "line.horizontal.3",
        "binding": Expression("context.showNavigation"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "showNavigation", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Hide Keyboard
        dismissCurrentResponder()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowNavigation.exec(context, arguments) }
    }
}
class ActionSchedule : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "alarm"
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "schedule", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        ActionSchedule.exec(context, arguments:arguments)
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        
    }
}

class ActionShowSessionSwitcher : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "ellipsis",
        "binding": Expression("context.showSessionSwitcher"),
        "color": Color(hex: "#CCC")
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "showSessionSwitcher", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        ActionShowSessionSwitcher.exec(context, arguments:arguments)
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
}
class ActionForward : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "forward", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = context.currentSession
        
        if session.currentViewIndex == session.views.count - 1 {
            print("Warn: Can't go forward. Already at last view in session")
        }
        else {
            realmWriteIfAvailable(context.cache.realm, { session.currentViewIndex += 1 })
            context.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionForward(context).exec(arguments) }
    }
}
class ActionForwardToFront : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "forwardToFront", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = context.currentSession
        realmWriteIfAvailable(context.cache.realm, {
            session.currentViewIndex = session.views.count - 1
        })
        context.scheduleCascadingViewUpdate()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionForwardToFront.exec(context, arguments) }
    }
}
class ActionBackAsSession : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "backAsSession", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = context.currentSession
        
        if session.currentViewIndex == 0 {
            throw "Warn: Can't go back. Already at earliest view in session"
        }
        else {
            if let duplicateSession = try context.cache.duplicate(session as DataItem) as? Session {
                realmWriteIfAvailable(context.cache.realm, {
                    duplicateSession.currentViewIndex -= 1
                })
                
                try ActionOpenSession.exec(context, ["session": duplicateSession])
            }
            else {
                // TODO Error handling
                throw ActionError.Warning(message: "Cannot execute ActionBackAsSession, duplicating currentSession resulted in a different type")
            }
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionBackAsSession.exec(context, arguments) }
    }
}

class ActionOpenSession : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["session": Session.self, "viewArguments": ViewArguments.self],
        "opensView": true,
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "openSession", arguments:arguments, values:values)
    }
    
    func openSession(_ context: MemriContext, _ session:Session) {
        let sessions = context.sessions // TODO generalize
    
        // Add view to session and set it as current
        sessions.setCurrentSession(session)
    
        // Recompute view
        context.scheduleCascadingViewUpdate()
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
    func exec(_ arguments:[String: Any]) throws {
        if let item = arguments["session"]{
            if let session = item as? Session {
                self.openSession(context, session)
            }
            else{
                // TODO Error handling
                throw "Cannot execute openSession 'session' argmument cannot be casted to Session"
            }
        }
        else {
            if let session = arguments["dataItem"] as? Session {
                self.openSession(context, session)
            }
            
            // TODO Error handling
            throw "Cannot execute openSession, no session passed"
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenSession.exec(context, arguments) }
    }
}
// TODO How to deal with viewArguments in sessions
class ActionOpenSessionByName : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": ViewArguments.self],
        "opensView": true,
        "withAnimation": false
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "openSessionByName", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        guard let name = arguments["name"] as? String else {
            // TODO: Error handling "No name given"
            throw "Cannot execute ActionOpenSessionByName, no name defined in viewArguments"
        }
        
        do {
            // Fetch and parse view from the database
            let fromDB = try context.views
                .parseDefinition(context.views.fetchDefinitions(name:name, type:"session").first)
            
            // See if this is a session, if so take the last view
            guard let def = fromDB as? CVUParsedSessionDefinition else {
                // TODO Error handling
                throw "Exception: Cannot open session with name \(name) " +
                      "cannot be casted as CVUParsedSessionDefinition"
            }
            
            let session = Session()
            guard let viewDefs = def["viewDefinitions"] as? [CVUParsedViewDefinition] else {
                throw "Exception: Session \(name) has no views."
            }
            
            var list:[SessionView] = []
            for viewDef in viewDefs {
                list.append(SessionView(value: [
                    "viewDefinition": CVUStoredDefinition(
                        value: ["definition": viewDef.toCVUString(0, "    ")]
                    ),
                    "viewArguments": viewArguments as Any?
                ]))
            }
            
            if list.count == 0 {
                throw "Exception: Session \(name) has no views."
            }
            
            session["views"] = list
            
            // Open the view
            ActionOpenSession(context).openSession(context, session)
        }
        catch let error {
            // TODO: Log error, Error handling
            throw "Exception: Cannot open session by name \(name): \(error)"

        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenSessionByName(context).exec(arguments) }
    }
}

class ActionDelete : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "delete", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//
//        // TODO this should happen automatically in ResultSet
//        //        self.context.items.remove(atOffsets: indexSet)
//        let indexSet = arguments["indices"] as? IndexSet
//        if let indexSet = indexSet{
//            var items:[DataItem] = []
//            for i in indexSet {
//                let item = context.items[i]
//                items.append(item)
//            }
//        }
        
        if let selection:[DataItem] = context.cascadingView.userState.get("selection"), selection.count > 0 {
            context.cache.delete(selection)
            context.scheduleCascadingViewUpdate()
        }
        else if let dataItem = arguments["dataItem"] as? DataItem {
            context.cache.delete(dataItem)
            context.scheduleCascadingViewUpdate(immediate: true)
        }
        else {
            // TODO Erorr handling
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionDelete(context).exec(arguments) }
    }
}
class ActionDuplicate : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "duplicate", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let selection:[DataItem] = context.cascadingView.userState.get("selection"), selection.count > 0 {
            try selection.forEach{ item in try ActionAddDataItem.exec(context, ["dataItem": item]) }
        }
        else if let item = arguments["dataItem"] as? DataItem {
            try ActionAddDataItem.exec(context, ["dataItem": item])
        }
        else {
            // TODO Error handling
            throw "Cannot execute ActionDupliate. The user either needs to make a selection, or a dataItem needs to be passed to this call."
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionDuplicate.exec(context, arguments) }
    }
}

class ActionImport : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "import", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws -> Void {
        // TODO: parse options
        
        if let importerInstance = arguments["importerInstance"] as? ImporterInstance{
            let cachedImporterInstance = try context.cache.addToCache(importerInstance)
            
            context.podAPI.runImport(cachedImporterInstance.memriID){ error, succes in
                if let error = error{
                    print("Cannot execute actionImport: \(error)")
                }
            }
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionImport.exec(context, arguments) }
    }
}


class ActionIndex : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "index", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws -> Void {
        // TODO: parse options
        
        if let indexerInstance = arguments["indexerInstance"] as? IndexerInstance{
            let cachedIndexerInstance = try context.cache.addToCache(indexerInstance)
            
            context.podAPI.runIndex(cachedIndexerInstance.memriID){ error, succes in
                if let error = error{
                    print("Cannot execute actionIndex: \(error)")
                }
            }
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionImport.exec(context, arguments) }
    }
}

class ActionClosePopup : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "closePopup", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        (context.closeStack.removeLast())()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionClosePopup(context).exec(arguments) }
    }
}

class ActionLink : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["subject": DataItemFamily.self, "property": String.self]
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "link", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        guard let subject = arguments["subject"] as? DataItem else {
            throw "Exception: subject is not set"
        }
        
        guard let propertyName = arguments["property"] as? String else {
            throw "Exception: property is not set to a string"
        }
        
        guard let selected = arguments["dataItem"] as? DataItem else {
            throw "Exception: selected data item is not passed"
        }
        
        // Check that the property exists to avoid hard crash
        guard let schema = subject.objectSchema[propertyName] else {
            throw "Exception: Invalid property access of \(propertyName) for \(subject)"
        }
        
        if schema.isArray {
            // Get list and append
            var list = dataItemListToArray(subject[propertyName] as Any)
            
            list.append(selected)
        
            subject.set(propertyName, list as Any)
        }
        else {
            subject.set(propertyName, selected)
        }
        
        // TODO refactor
        ((self.context as? SubContext)?.parent ?? self.context).scheduleUIUpdate()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionLink(context).exec(arguments) }
    }
}

class ActionUnlink : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["subject": DataItemFamily.self, "property": String.self]
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "unlink", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        guard let subject = arguments["subject"] as? DataItem else {
            throw "Exception: subject is not set"
        }
        guard let propertyName = arguments["property"] as? String else {
            throw "Exception: property is not set to a string"
        }
        
        guard let selected = arguments["dataItem"] as? DataItem else {
            throw "Exception: selected data item is not passed"
        }
        
        // Check that the property exists to avoid hard crash
        guard let schema = subject.objectSchema[propertyName] else {
            throw "Exception: Invalid property access of \(propertyName) for \(subject)"
        }
        
        if schema.isArray {
            // Get list and append
            var list = dataItemListToArray(subject[propertyName] as Any)
            
            list.removeAll(where: { item in
                item == selected
            })
        
            subject.set(propertyName, list as Any)
        }
        else {
            subject.set(propertyName, nil)
        }
        
        // TODO refactor
        ((self.context as? SubContext)?.parent ?? self.context).scheduleUIUpdate()
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionUnlink(context).exec(arguments) }
    }
}

class ActionMultiAction : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["actions": [Action].self],
        "opensView": true
    ]}
    
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "multiAction", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        guard let actions = arguments["actions"] as? [Action] else {
            throw "Cannot execute ActionMultiAction: no actions passed in arguments"
        }
        
        for action in actions {
            self.context.executeAction(action, with: arguments["dataItem"] as? DataItem)
        }
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionMultiAction(context).exec(arguments) }
    }
}

class ActionNoop : Action, ActionExec {
    required init(_ context:MemriContext, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(context, "noop", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // do nothing
    }
    
    class func exec(_ context:MemriContext, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionClosePopup(context).exec(arguments) }
    }
}

