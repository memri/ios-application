//
//  Action.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class Action : HashableClass, CVUToString {
    var name:ActionFamily = .noop
    var arguments: [String: Any?] = [:]
    
    var binding:Expression? {
        if let expr = (values["binding"] ?? defaultValues["binding"]) as? Expression {
            expr.lookup = main.views.lookupValueOfVariables
            expr.execFunc = main.views.executeFunction
            expr.main = main
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
        "inactiveColor": Color(hex: "#999999"),
        "activeBackgroundColor": Color.white,
        "inactiveBackgroundColor": Color.white
    ]
    var values:[String:Any?] = [:]
    
    let main:Main
    
    func isActive() -> Bool? {
        if let binding = binding {
            do { return try binding.isTrue() }
            catch {
                // TODO error handling
                errorHistory.warn("Could not read boolean value from binding \(binding)")
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
    
    init(_ main:Main, _ name:String, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]) {
        self.main = main
        
        super.init()
        
        if let actionName = ActionFamily(rawValue: name) { self.name = actionName }
        else { self.name = .noop } // TODO REfactor: Report error to user
        
        self.arguments = arguments ?? self.arguments
        self.values = values
        
        if let x = self.values["renderAs"] as? String {
            self.values["renderAs"] = RenderType(rawValue: x)
        }
    }
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]) {
        self.main = main
    }
    
    func get<T>(_ key:String, _ viewArguments:ViewArguments? = nil) -> T? {
        let x:Any? = values[key] ?? defaultValues[key] ?? baseValues[key]
        if let expr = x as? Expression {
            do {
                expr.lookup = main.views.lookupValueOfVariables
                expr.execFunc = main.views.executeFunction
                expr.main = main
                
                let value:T? = try expr.execForReturnType(viewArguments)
                return value
            }
            catch {
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
            errorHistory.error("Could not execute action: \(error)")
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
        addSelectionToList, closePopup, noop

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
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "back", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = main.currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            realmWriteIfAvailable(main.realm, { session.currentViewIndex -= 1 })
            main.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ main:Main, arguments:[String: Any]) throws {
        execWithoutThrow { try ActionBack(main).exec(arguments) }
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
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "addDataItem", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let dataItem = arguments["template"] as? DataItem {
            // Copy template
            let copy = main.cache.duplicate(dataItem)
            
            // Add the new item to the cache
            _ = try main.cache.addToCache(copy)
            
            // Open view with the now managed copy
            try ActionOpenView.exec(main, ["dataItem": copy])
        }
        else {
            // TODO Error handling
            // TODO User handling
            throw "Cannot open view, no dataItem passed in arguments"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionAddDataItem(main).exec(arguments) }
    }
}


    class ActionOpenView : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["view": SessionView.self, "viewArguments": ViewArguments.self],
        "opensView": true
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "openView", arguments:arguments, values:values)
    }
    
    func openView(_ main: Main, view: SessionView, with arguments: ViewArguments? = nil){
        let session = main.currentSession
        
        // Toggle a state value, for instance the starred button in the view (via dataItem.starred)
        if let binding = self.binding {
            do { try binding.toggleBool() }
            catch {
                // TODO: User error handling
                // TODO Error handling
                errorHistory.error("\(error)")
            }
        }
        
        // Merge arguments into view
        if let dict = arguments?.asDict() {
            if let viewArguments = view.viewArguments {
                view.viewArguments = ViewArguments(viewArguments.asDict()
                    .merging(dict, uniquingKeysWith: { current, new in new }))
            }
        }
        
        // Add view to session
        session.setCurrentView(view)
    
        // Set accessed date to now
        view.access()
    
        // Recompute view
        main.scheduleCascadingViewUpdate()
    }
    
    private func openView(_ main: Main, _ item: DataItem, with arguments: ViewArguments? = nil){
        // Create a new view
        let view = SessionView(value: ["datasource": Datasource(value: [
            // Set the query options to load the item
            "query": "\(item.genericType) AND memriID = '\(item.memriID)'"
        ])])
    
        // Open the view
        self.openView(main, view:view, with: arguments)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        let selection = main.cascadingView.userState.get("selection") as? [DataItem]
        let dataItem = arguments["dataItem"] as? DataItem
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        
        // if let selection = selection, selection.count > 0 { self.openView(main, selection) }
        if let sessionView = arguments["view"] as? SessionView {
            self.openView(main, view: sessionView, with: viewArguments)
        }
        else if let item = dataItem as? SessionView {
            self.openView(main, view: item, with: viewArguments)
        }
        else if let item = dataItem {
            self.openView(main, item, with: viewArguments)
        }
        else {
            // TODO Error handling
            throw "Cannot execute ActionOpenView, arguments require a SessionView. passed arguments:\n \(arguments), "
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenView(main).exec(arguments) }
    }
}
class ActionOpenViewByName : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": ViewArguments.self],
        "opensView": true
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "openViewByName", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        if let name = arguments["name"] as? String {
            // Fetch a dynamic view based on its name
            let fetchedDef = main.views.fetchDefinitions(name:name, type:"view").first
            let def = try main.views.parseDefinition(fetchedDef)
            
            guard let viewDef = def else { throw "Exception: Missing view" }
            
            let view = SessionView(value: [
                "viewDefinition": fetchedDef,
                "viewArguments": viewArguments,
                "datasource": viewDef["datasource"] // TODO Refactor
            ])
            
            ActionOpenView(main).openView(main, view:view)
        }
        else {
            // TODO Error Handling
            throw "Cannot execute ActionOpenViewByName, no name found in arguments."
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenViewByName(main).exec(arguments) }
    }
}
class ActionToggleEditMode : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "pencil",
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "toggleEditMode", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionToggleEditMode(main).exec(arguments) }
    }
}
class ActionToggleFilterPanel : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "rhombus.fill",
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "toggleFilterPanel", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionToggleFilterPanel(main).exec(arguments) }
    }
}
class ActionStar : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "star.fill",
        "binding": Expression("dataItem.starred")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "toggleStar", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let item = arguments["dataItem"] as? DataItem {
            var selection:[DataItem] = main.cascadingView.userState.get("selection") ?? []
            let toValue = !item.starred
            
            if !selection.contains(item) {
                selection.append(item)
            }
            
            realmWriteIfAvailable(main.cache.realm, {
                for item in selection { item.starred = toValue }
            })

            // TODO if starring is ever allowed in a list resultset view,
            // it won't be updated as of now
        }
        else {
            // TODO Error handling
            throw "Cannot execute ActionStar, missing dataItem in arguments."
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionStar.exec(main, arguments) }
    }
}
class ActionShowStarred : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "star.fill",
        "binding": Expression("view.userState.showStarred"),
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "showStarred", arguments:arguments, values:values)
    }

    func exec(_ arguments:[String: Any]) throws {
        do {
            if let binding = self.binding, try !binding.isTrue() {
                try ActionOpenViewByName.exec(main, ["name": "filter-starred"])
                // Open named view 'showStarred'
                // openView("filter-starred", ["stateName": starButton.actionStateName as Any])
            }
            else {
                // Go back to the previous view
                try ActionBack.exec(main, arguments: [:])
            }
        }
        catch {
            // TODO Error Handling
            throw "Cannot execute ActionShowStarred: \(error)"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowStarred(main).exec(arguments) }
    }
}
class ActionShowContextPane : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "ellipsis",
        "binding": Expression("currentSession.showContextPane")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "showContextPane", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowContextPane(main).exec(arguments) }
    }
}
class ActionShowNavigation : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "line.horizontal.3",
        "binding": Expression("main.showNavigation"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "showNavigation", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionShowNavigation.exec(main, arguments) }
    }
}
class ActionSchedule : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "alarm"
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "schedule", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        ActionSchedule.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        
    }
}

class ActionShowSessionSwitcher : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "icon": "ellipsis",
        "binding": Expression("main.showSessionSwitcher"),
        "color": Color(hex: "#CCC")
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "showSessionSwitcher", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//        ActionShowSessionSwitcher.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
}
class ActionForward : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "forward", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = main.currentSession
        
        if session.currentViewIndex == session.views.count - 1 {
            print("Warn: Can't go forward. Already at last view in session")
        }
        else {
            realmWriteIfAvailable(main.cache.realm, { session.currentViewIndex += 1 })
            main.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionForward(main).exec(arguments) }
    }
}
class ActionForwardToFront : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "forwardToFront", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = main.currentSession
        realmWriteIfAvailable(main.cache.realm, {
            session.currentViewIndex = session.views.count - 1
        })
        main.scheduleCascadingViewUpdate()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionForwardToFront.exec(main, arguments) }
    }
}
class ActionBackAsSession : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "opensView": true,
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "backAsSession", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let session = main.currentSession
        
        if session.currentViewIndex == 0 {
            throw "Warn: Can't go back. Already at earliest view in session"
        }
        else {
            if let duplicateSession = main.cache.duplicate(session as DataItem) as? Session {
                realmWriteIfAvailable(main.cache.realm, {
                    duplicateSession.currentViewIndex -= 1
                })
                
                try ActionOpenSession.exec(main, ["session": duplicateSession])
            }
            else {
                // TODO Error handling
                throw ActionError.Warning(message: "Cannot execute ActionBackAsSession, duplicating currentSession resulted in a different type")
            }
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionBackAsSession.exec(main, arguments) }
    }
}

class ActionOpenSession : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["session": Session.self, "viewArguments": [String:Any]?.self],
        "opensView": true,
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "openSession", arguments:arguments, values:values)
    }
    
    func openSession(_ main: Main, _ session:Session) {
        let sessions = main.sessions // TODO generalize
    
        // Add view to session and set it as current
        sessions.setCurrentSession(session)
    
        // Recompute view
        main.scheduleCascadingViewUpdate()
    }
    
//    func openSession(_ main: Main, _ name:String, _ variables:[String:Any]? = nil) throws {
//
//        // TODO: This should not fetch the session from named sessions
//        //       but instead load a sessionview that loads the named sessions by
//        //       computing them (implement viewFromSession that is used in dynamic
//        //       view to sessionview
//
//        // Fetch a dynamic view based on its name
//    }
    
    ///// Adds a view to the history of the currentSession and displays it. If the view was already part of the currentSession.views it
    /////  reorders it on top
    func exec(_ arguments:[String: Any]) throws {
        if let item = arguments["session"]{
            if let session = item as? Session {
                self.openSession(main, session)
            }
            else{
                // TODO Error handling
                throw "Cannot execute openSession 'session' argmument cannot be casted to Session"
            }
        }
        else {
            // TODO Error handling
            throw "Cannot execute openSession, no session passed"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenSession.exec(main, arguments) }
    }
}
// TODO How to deal with viewArguments in sessions
class ActionOpenSessionByName : Action, ActionExec {
    override var defaultValues:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": [String:Any]?.self],
        "opensView": true,
    ]}
    
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "openSessionByName", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        if let name = arguments["name"] as? String {
            do {
                // Fetch and parse view from the database
                let def = try main.views
                    .parseDefinition(main.views.fetchDefinitions(name:name, type:"session").first)
                
                // See if this is a session, if so take the last view
                if let def = def as? CVUParsedSessionDefinition {
                    let session = Session()
                    if let viewDefs = def["viewDefinitions"] as? [CVUParsedViewDefinition] {
                        var list:[SessionView] = []
                        
                        for viewDef in viewDefs {
                            list.append(SessionView(value: [
                                "viewDefinition": viewDef,
                                "viewArguments": viewArguments as Any?
                            ]))
                        }
                        
                        if list.count == 0 {
                            throw "Exception: Session \(name) has no views."
                        }
                        
                        session["views"] = list
                    }
                    else {
                        throw "Exception: Session \(name) has no views."
                    }
                    
                    // Open the view
                    ActionOpenSession(main).openSession(main, session)
                }
                else {
                    // TODO Error handling
                    throw "Exception: Cannot open session with name \(name) " +
                          "cannot be casted as CVUParsedSessionDefinition"
                }
            }
            catch let error {
                // TODO: Log error, Error handling
                throw "Exception: Cannot open session by name \(name): \(error)"

            }
        }
        else {
            // TODO: Error handling "No name given"
            throw "Cannot execute ActionOpenSessionByName, no name defined in viewArguments"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionOpenSessionByName(main).exec(arguments) }
    }
}

class ActionDelete : Action, ActionExec {
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "delete", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
//
//        // TODO this should happen automatically in ResultSet
//        //        self.main.items.remove(atOffsets: indexSet)
//        let indexSet = arguments["indices"] as? IndexSet
//        if let indexSet = indexSet{
//            var items:[DataItem] = []
//            for i in indexSet {
//                let item = main.items[i]
//                items.append(item)
//            }
//        }
        
        if let selection:[DataItem] = main.cascadingView.userState.get("selection"), selection.count > 0 {
            main.cache.delete(selection)
            main.scheduleUIUpdate{_ in true}
        }
        else if let dataItem = arguments["dataItem"] as? DataItem {
            main.cache.delete(dataItem)
            main.scheduleUIUpdate{_ in true}
        }
        else {
            // TODO Erorr handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionDelete(main).exec(arguments) }
    }
}
class ActionDuplicate : Action, ActionExec {
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "duplicate", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let selection:[DataItem] = main.cascadingView.userState.get("selection"), selection.count > 0 {
            try selection.forEach{ item in try ActionAddDataItem.exec(main, ["dataItem": item]) }
        }
        else if let item = arguments["dataItem"] as? DataItem {
            try ActionAddDataItem.exec(main, ["dataItem": item])
        }
        else {
            // TODO Error handling
            throw "Cannot execute ActionDupliate. The user either needs to make a selection, or a dataItem needs to be passed to this call."
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionDuplicate.exec(main, arguments) }
    }
}
class ActionClosePopup : Action, ActionExec {
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "closePopup", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        (main.closeStack.removeLast())()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionClosePopup(main).exec(arguments) }
    }
}

class ActionSetProperty : Action, ActionExec {
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "setProperty", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        if let sourceDataItem = arguments["sourceDataItem"] as? DataItem {
            if let propName = arguments["property"] as? String {
                if let dataItem = arguments["dataItem"] {
                    sourceDataItem.set(propName, dataItem) // TODO also add to a list
                    main.scheduleUIUpdate{_ in true}
                    return
                }
            }
        }
        else{
            // TODO error handling
            throw "Cannot execute ActionSetProperty: no sourceDataItem passed in arguments"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionSetProperty(main).exec(arguments) }
    }
}

class ActionNoop : Action, ActionExec {
    required init(_ main:Main, arguments:[String: Any?]? = nil, values:[String:Any?] = [:]){
        super.init(main, "noop", arguments:arguments, values:values)
    }
    
    func exec(_ arguments:[String: Any]) throws {
        // do nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        execWithoutThrow { try ActionClosePopup(main).exec(arguments) }
    }
}

