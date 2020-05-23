//
//  Action.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class Action : HashableClass, CVUToString {
    var name:ActionName = .noop
    var arguments: [String: Any] = [:]
    var renderAs: RenderType = .button
    
    var icon: String = "exclamationmark.bubble"
    var title: String? = nil
    var showTitle: Bool = false
    var binding:Expression? = nil
    var hasState = false
    var opensView = false
    var color: Color = Color(hex: "#999999")
    var backgroundColor: Color = .white
    var activeColor: Color? = nil
    var inactiveColor: Color? = Color(hex: "#999999")
    var activeBackgroundColor: Color? = .white
    var inactiveBackgroundColor: Color? = .white
    
    var argumentTypes:[String: AnyObject.Type] = [:]
    
    private var defaults:[String:Any] { return [:] }
    
    public var description: String {
        toString(0, "    ")
    }
    
    func toString(_ depth:Int, _ tab:String) -> String {
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsPlus = Array(0..<depth + 1).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        var strBuilder:[String] = []
        
        if arguments.count > 0 {
            strBuilder.append("arguments: \(CVUSerializer.dictToString(arguments, depth + 1, tab))")
        }
        if renderAs != .button { strBuilder.append("renderAs: \(renderAs)") }
        if icon != "exclamationmark.bubble" && icon != self.defaults["icon"] as? String && icon != "" {
            strBuilder.append("icon: \(icon)")
        }
        if title != nil && title != self.defaults["title"] as? String && title != "" {
            strBuilder.append("title: \(title ?? "nil")")
        }
        if showTitle != false { strBuilder.append("showTitle: \(showTitle)") }
        if binding != nil { strBuilder.append("binding: \(binding?.description ?? "nil")") }
        if hasState != false { strBuilder.append("hasState: \(hasState)") }
        if opensView != false { strBuilder.append("opensView: \(opensView)") }
        if color != Color(hex: "#999999") { strBuilder.append("color: \(color)") }
        if backgroundColor != .white { strBuilder.append("backgroundColor: \(backgroundColor)") }
        if activeColor != nil { strBuilder.append("activeColor: \(activeColor?.description ?? "nil")") }
        if inactiveColor != Color(hex: "#999999") {
            strBuilder.append("inactiveColor: \(inactiveColor?.description ?? "nil")")
        }
        if activeBackgroundColor != .white {
            strBuilder.append("activeBackgroundColor: \(activeBackgroundColor?.description ?? "nil")")
        }
        if inactiveBackgroundColor != .white {
            strBuilder.append("inactiveBackgroundColor: \(inactiveBackgroundColor?.description ?? "nil")")
        }
        
        return strBuilder.count > 0
            ? "\(name) {\n\(tabs)\(strBuilder.joined(separator: "\n\(tabsPlus)"))\n\(tabsEnd)}"
            : "\(name)"
    }
    
    init(_ name:String,
         _ arguments:[String: Any]? = nil,
         icon:String? = nil,
         title:String? = nil,
         showTitle:Bool? = nil,
         binding:Expression? = nil,
         renderAs:RenderType? = nil,
         hasState:Bool? = nil,
         color:Color? = nil,
         backgroundColor:Color? = nil,
         activeColor:Color? = nil,
         inactiveColor:Color? = nil,
         activeBackgroundColor:Color? = nil,
         inactiveBackgroundColor:Color? = nil
    ) {
        super.init()
        
        if let actionName = ActionName(rawValue: name) {
            self.name = actionName
        }
        else {
            // TODO REfactor: Report error to user
            self.name = .noop
        }
        
        let defForName = self.defaults
        
        self.arguments = arguments ?? self.arguments
        self.icon = icon ?? defForName["icon"] as? String ?? self.icon
        self.renderAs = renderAs ?? defForName["renderAs"] as? RenderType ?? self.renderAs
        self.title = title ?? defForName["icon"] as? String ?? self.title
        self.showTitle = showTitle ?? defForName["icon"] as? Bool ?? self.showTitle
        self.binding = binding ?? defForName["icon"] as? Expression ?? self.binding
        self.hasState = hasState ?? defForName["icon"] as? Bool ?? self.hasState
        self.opensView = defForName["icon"] as? Bool ?? self.opensView
        self.color = color ?? defForName["icon"] as? Color ?? self.color
        self.backgroundColor = backgroundColor ?? defForName["icon"] as? Color ?? self.backgroundColor
        self.activeColor = activeColor ?? defForName["icon"] as? Color ?? self.activeColor
        self.inactiveColor = inactiveColor ?? defForName["icon"] as? Color ?? self.inactiveColor
        self.activeBackgroundColor = activeBackgroundColor ?? defForName["icon"] as? Color ?? self.activeBackgroundColor
        self.inactiveBackgroundColor = inactiveBackgroundColor ?? defForName["icon"] as? Color ?? self.inactiveBackgroundColor
    }
    
//    // TODO call without exec
//    class func execWithoutThrow(_ main:Main, ) {
//        
//    }
    
    public func computeColor(state:Bool) -> Color {
        if self.hasState == true {
            if state { return self.activeColor ?? globalColors.byName("activeColor") }
            else { return self.inactiveColor ?? globalColors.byName("inactiveColor") }
        }
        else { return self.color }
    }
    
    public func computeBackgroundColor(state:Bool) -> Color{
        if self.hasState == true {
            if state { return self.activeBackgroundColor ?? globalColors.byName("activeBackgroundColor") }
            else { return self.inactiveBackgroundColor ?? globalColors.byName("inactiveBackgroundColor") }
        }
        else { return self.backgroundColor }
    }
}

public enum RenderType: String{
    case popup, button, emptytype
}

public enum ActionName: String, CaseIterable {
    case back, addDataItem, openView, openDynamicView, openViewByName, toggleEditMode, toggleFilterPanel,
        star, showStarred, showContextPane, showOverlay, share, showNavigation, addToPanel, duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        delete, setRenderer, select, selectAll, unselectAll, showAddLabel, openLabelView,
        showSessionSwitcher, forward, forwardToFront, backAsSession, openSession, openSessionByName,
        addSelectionToList, closePopup, noop

    func getType() -> Action.Type {
        switch self {
        case .back:
            return ActionBack.self
        case .addDataItem:
            return ActionAddDataItem.self
        case .openView:
            return ActionOpenView.self
        case .openViewByName:
            return ActionOpenViewByName.self
        case .toggleEditMode:
            return ActionToggleEditMode.self
        case .toggleFilterPanel:
            return ActionToggleFilterPanel.self
        case .star:
            return ActionStar.self
        case .showStarred:
            return ActionShowStarred.self
        case .showContextPane:
            return ActionShowContextPane.self
//        case .showOverlay:
//            return ActionShowOverlay.self
//        case .share:
//            return ActionShare.self
        case .showNavigation:
            return ActionShowNavigation.self
//        case .addToPanel:
//            return ActionAddToPanel.self
        case .duplicate:
            return ActionDuplicate.self
        case .schedule:
            return ActionSchedule.self
//        case .addToList:
//            return ActionAddToList.self
        case .delete:
            return ActionDelete.self
//        case .select:
//            return ActionSelect.self
//        case .selectAll:
//            return ActionSelectAll.self
//        case .unselectAll:
//            return ActionUnselectAll.self
//        case .showAddLabel:
//            return ActionShowAddLabel.self
//        case .openLabelView:
//            return ActionOpenLabelView.self
        case .showSessionSwitcher:
            return ActionShowSessionSwitcher.self
        case .forward:
            return ActionForward.self
        case .forwardToFront:
            return ActionForwardToFront.self
        case .backAsSession:
            return ActionBackAsSession.self
        case .openSession:
            return ActionOpenSession.self
        case .openSessionByName:
            return ActionOpenSessionByName.self
        case .closePopup:
            return ActionClosePopup.self
        case .noop:
            fallthrough
        default:
            return ActionNoop.self
        }
    }
}

protocol ActionExec {
    func exec(_ main:Main, _ arguments:[String: Any]) throws
}

class ActionBack : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "chevron.left",
        "opensView": true,
        "color": Color(hex: "#434343"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    convenience init(){
        self.init("back")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
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
        try ActionBack().exec(main, arguments)
    }
}
class ActionAddDataItem : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "plus",
        "argumentTypes": ["dataItem": DataItemFamily.self],
        "opensView": true,
        "color": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    convenience init(){
        self.init("addDataItem")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        if let dataItem = arguments["dataItem"] as? DataItem {
            // Copy template
            let copy = main.cache.duplicate(dataItem)
            
            // Add the new item to the cache
            _ = try main.cache.addToCache(copy)
            
            // Open view with the now managed copy
            try ActionOpenView.exec(main, ["dataItem": copy])
        }
        else {
            // TODO Error handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionAddDataItem().exec(main, arguments)
    }
}


class ActionOpenView : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["view": SessionView.self, "viewArguments": ViewArguments.self],
        "opensView": true
    ]}
    
    convenience init(){
        self.init("openView")
    }
    
    func openView(_ main: Main, view: SessionView, with arguments: ViewArguments? = nil){
        let session = main.currentSession
        
        // Toggle a state value, for instance the starred button in the view (via dataItem.starred)
        if let binding = self.binding {
            do { try binding.toggleBool() }
            catch {
                // TODO ERror handling
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
        let view = SessionView(value: ["queryOptions": QueryOptions(value: [
            // Set the query options to load the item
            "query": "\(item.genericType) AND uid = '\(item.uid)'"
        ])])
    
        // Open the view
        self.openView(main, view:view, with: arguments)
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
//        let selection = main.cascadingView.userState["selection"] as? [DataItem]
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
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionOpenView().exec(main, arguments)
    }
}
class ActionOpenViewByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": ViewArguments.self],
        "opensView": true
    ]}
    
    convenience init(){
        self.init("openViewByName")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        if let name = arguments["name"] as? String {
            // Fetch a dynamic view based on its name
            let def = try main.views.parseDefinition(main.views.fetchDefinitions(".\(name)").first)
            
            guard let viewDef = def else { throw "Exception: Missing view" }

            let view = SessionView(value: [
                "viewDefinition": viewDef,
                "viewArguments": viewArguments,
                "queryOptions": viewDef["queryOptions"] // TODO Refactor
            ])
            
            ActionOpenView().openView(main, view:view)
        }
        else {
            // TODO Error Handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionOpenViewByName().exec(main, arguments)
    }
}
class ActionToggleEditMode : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "rhombus.fill",
        "hasState": true,
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    convenience init(){
        self.init("toggleEditMode")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionToggleEditMode().exec(main, arguments)
    }
}
class ActionToggleFilterPanel : Action, ActionExec {
    private var defaults:[String:Any] {[
        "hasState": true,
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f")
    ]}
    
    convenience init(){
        self.init("toggleFilterPanel")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionToggleFilterPanel().exec(main, arguments)
    }
}
class ActionStar : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "{dataItem.starred}"
    ]}
    
    convenience init(){
        self.init("toggleStar")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        if let item = arguments["dataItem"] as? DataItem {
            var selection = main.cascadingView.userState["selection"] as? [DataItem] ?? []
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
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionStar.exec(main, arguments)
    }
}
class ActionShowStarred : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "showStarred",
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00")
    ]}
    
    convenience init(){
        self.init("showStarred")
    }

    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        do {
            if let binding = self.binding, try binding.isTrue() {
                try ActionOpenView.exec(main, ["viewArguments": "filter-starred"])
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
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionShowStarred().exec(main, arguments)
    }
}
class ActionShowContextPane : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("currentSession.showContextPane")
    ]}
    
    convenience init(){
        self.init("showContextPane")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionShowContextPane().exec(main, arguments)
    }
}
class ActionShowNavigation : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "line.horizontal.3",
        "hasState": true,
        "binding": Expression("main.showNavigation"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    convenience init(){
        self.init("showNavigation")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionShowNavigation.exec(main, arguments)
    }
}
class ActionSchedule : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "alarm"
    ]}
    
    convenience init(){
        self.init("schedule")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
//        ActionSchedule.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        
    }
}

class ActionShowSessionSwitcher : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("main.showSessionSwitcher"),
        "color": Color(hex: "#CCC")
    ]}
    
    convenience init(){
        self.init("showSessionSwitcher")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
//        ActionShowSessionSwitcher.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // Do Nothing
    }
}
class ActionForward : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("forward")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
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
        try ActionForward().exec(main, arguments)
    }
}
class ActionForwardToFront : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("forwardToFront")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        let session = main.currentSession
        realmWriteIfAvailable(main.cache.realm, {
            session.currentViewIndex = session.views.count - 1
        })
        main.scheduleCascadingViewUpdate()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionForwardToFront.exec(main, arguments)
    }
}
class ActionBackAsSession : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("backAsSession")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
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
                // TODO ERror handling
            }
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionBackAsSession.exec(main, arguments)
    }
}

class ActionOpenSession : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["session": Session.self, "viewArguments": [String:Any]?.self],
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("openSession")
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
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        if let item = arguments["session"] as? Session {
            self.openSession(main, item)
        }
        else {
            // TODO ERror handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionOpenSession.exec(main, arguments)
    }
}
// TODO How to deal with viewArguments in sessions
class ActionOpenSessionByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": [String:Any]?.self],
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("openSessionByName")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        let viewArguments = arguments["viewArguments"] as? ViewArguments
        
        if let name = arguments["name"] as? String {
            do {
                // Fetch and parse view from the database
                let def = try main.views.parseDefinition(main.views.fetchDefinitions(".\(name)").first)
                
                // See if this is a session, if so take the last view
                if let def = def as? ParsedSessionDefinition {
                    let session = Session()
                    let list:[SessionView] = (def["views"] as? [[String:Any]])?.compactMap {
                        let viewDef = ParsedViewDefinition(DataItem.generateUUID())
                        viewDef.parsed = $0
                        
                        return SessionView(value:[
                            "viewDefinition": viewDef,
                            "viewArguments": viewArguments as Any
                        ])
                    } ?? []
                    session["views"] = list
                    
                    // Open the view
                    ActionOpenSession().openSession(main, session)
                }
                else {
                    // TODO Error handling
                }
            }
            catch {
                // TODO: Log error, Error handling
                print("COULD NOT OPEN SESSION")
            }
        }
        else {
            // TODO: Error handling "No name given"
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionOpenSession().exec(main, arguments)
    }
}

class ActionDelete : Action, ActionExec {
    convenience init(){
        self.init("delete")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
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
        
        if let selection = main.cascadingView.userState["selection"] as? [DataItem], selection.count > 0 {
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
        try ActionDelete().exec(main, arguments)
    }
}
class ActionDuplicate : Action, ActionExec {
    convenience init(){
        self.init("duplicate")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        if let selection = main.cascadingView.userState["selection"] as? [DataItem], selection.count > 0 {
            try selection.forEach{ item in try ActionAddDataItem.exec(main, ["dataItem": item]) }
        }
        else if let item = arguments["dataItem"] as? DataItem {
            try ActionAddDataItem.exec(main, ["dataItem": item])
        }
        else {
            // TODO ERror handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionDuplicate.exec(main, arguments)
    }
}
class ActionClosePopup : Action, ActionExec {
    convenience init(){
        self.init("closePopup")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        (main.closeStack.removeLast())()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionClosePopup().exec(main, arguments)
    }
}

class ActionSetProperty : Action, ActionExec {
    convenience init(){
        self.init("setProperty")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        if let sourceDataItem = arguments["sourceDataItem"] as? DataItem {
            if let propName = arguments["property"] as? String {
                if let dataItem = arguments["dataItem"] {
                    sourceDataItem.set(propName, dataItem) // TODO also add to a list
                    main.scheduleUIUpdate{_ in true}
                    return
                }
            }
        }
        
        // TODO error handling
        throw "Exception ...."
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionSetProperty().exec(main, arguments)
    }
}

class ActionNoop : Action, ActionExec {
    convenience init(){
        self.init("noop")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) throws {
        // do nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) throws {
        try ActionClosePopup.exec(main, arguments)
    }
}

