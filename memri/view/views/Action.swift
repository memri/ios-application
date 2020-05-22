//
//  Action.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class Action : HashableClass, CustomStringConvertible {
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
        return "\(name))"
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
        
    public func computeColor(state:Bool) -> Color {
        if self.hasState == true {
            if state { return self.activeColor ?? globalColors.byName("activeColor") }
            else { return self.inactiveColor ?? globalColors.byName("inactiveColor") }
        }
        else {return self.color}
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
        case .openDynamicView:
            return ActionOpenDynamicView.self
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
        case .setRenderer:
            return ActionSetRenderer.self
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
    func exec(_ main:Main, _ arguments:[String: Any])
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
//        ActionBack.exec(main, arguments:arguments)
        let session = main.currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            realmWriteIfAvailable(main.realm, {session.currentViewIndex -= 1})
            main.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ main:Main, arguments:[String: Any]) {
        ActionBack().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // Copy template
        let copy = main.cache.duplicate(arguments["dataItem"] as! DataItem)
        
        // Add the new item to the cache
        _ = try! main.cache.addToCache(copy)
        
        // Open view with the now managed copy
        ActionOpenView.exec(main, ["dataItem": copy])
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionAddDataItem().exec(main, arguments)
    }
}


class ActionOpenView : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["view": SessionView.self, "viewArguments": [String:Any]?.self],
        "opensView": true
    ]}
    
    convenience init(){
        self.init("openView")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        else if selection?.count ?? 0 > 0 { self.openView(main, selection!) } // TODO does this mean anything?
        else if let item = item as? SessionView { self.openView(main, view: item) }
        else if let item = item { self.openView(main, item) }
    }
    
    private func openView(_ main: Main, view: SessionView, _ arguments: ViewArguments? = nil){
        let session = main.currentSession
        
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
    
    /// Adds a view to the history of the currentSession and displays it.
    /// If the view was already part of the currentSession.views it reorders it on top
    func openView(_ main: Main, _ view: SessionView, variables: [String: Any]? = nil) throws{
            // Fetch a dynamic view based on its name
        var def = try! main.views.parseDefinition(main.views.fetchDefinitions(".\(viewName)").first)
        
        guard let viewDef = def else { throw "Exception: Missing view" }

        let view = SessionView(value: [
            "viewDefinition": viewDef,
            "viewArguments": variables,
            "queryOptions": viewDef["queryOptions"] // TODO Refactor
        ])
        self.openView(main, view, variables)
    }
    
    func openView(_ main: Main, _ item: DataItem, _ variables: [String: Any]? = nil){
        // Create a new view
        let view = SessionView()
    
        // Set the query options to load the item
        let primKey = DataItemFamily(rawValue: item.genericType)!.getPrimaryKey()
        view.queryOptions!.query = "\(item.genericType) AND \(primKey) = '\(item.getString(primKey))'"
    
        // Open the view
        self.openView(main, view, variables)
    }
    
    func openView(_ main: Main, _ items: [DataItem], _ variables: [String: Any]? = nil){
        print("NOT IMPLEMENTED")
    }
    
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionOpenView().exec(main, arguments)
    }
}
class ActionOpenDynamicView : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true
    ]}
    
    convenience init(){
        self.init("openDynamicView")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionOpenView.exec(main, arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionOpenDynamicView().exec(main, arguments)
    }
}
class ActionOpenViewByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": [String:Any]?.self],
        "opensView": true
    ]}
    
    convenience init(){
        self.init("openViewByName")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let item = arguments["view"] as? SessionView
        let selection = main.cascadingView.userState["selection"] as [DataItem]?
        if (arguments.count > 0) {
            let view = arguments["view"] as! SessionView
            var args = arguments
            args.removeValue(forKey: "view")
            ActionOpenView().openView((main, args, view)
        }   
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionOpenViewByName().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionToggleEditMode().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionToggleFilterPanel().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let item = arguments["dataItem"] as? DataItem
        var selection = main.cascadingView.userState["selection"] as? [DataItem] ?? []
        let toValue = !(item?.starred ?? false)
        if let _item = item, selection.count > 0{
            if !selection.contains(_item){selection.append(_item)}
            realmWriteIfAvailable(main.cache.realm, {for item in selection {item.starred = toValue}})

        // TODO if starring is ever allowed in a list resultset view,
        // it won't be updated as of now
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionStar.exec(main, arguments)
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

    func exec(_ main:Main, _ arguments:[Any]) {
        do {
            if let binding = self.binding, try binding.isTrue() {
                ActionOpenView.exec(main, ["viewArguments": "filter-starred"])
                // Open named view 'showStarred'
                // openView("filter-starred", ["stateName": starButton.actionStateName as Any])
            }
            else {
                // Go back to the previous view
                ActionBack.exec(main, arguments: [])
            }
        }
        catch {
            // TODO Error Handling
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionShowStarred().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionShowContextPane().exec(main, arguments)
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // Do Nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionShowNavigation.exec(main, arguments)
    }
}
class ActionSchedule : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "alarm"
    ]}
    
    convenience init(){
        self.init("schedule")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
//        ActionSchedule.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
//        ActionShowSessionSwitcher.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
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
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let session = main.currentSession
        
        if session.currentViewIndex == session.views.count - 1 {
            print("Warn: Can't go forward. Already at last view in session")
        }
        else {
            realmWriteIfAvailable(main.cache.realm, {session.currentViewIndex += 1})
            main.scheduleCascadingViewUpdate()
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionForward().exec(main, arguments)
    }
}
class ActionForwardToFront : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("forwardToFront")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let session = main.currentSession
        realmWriteIfAvailable(main.cache.realm, {session.currentViewIndex = session.views.count - 1})
        main.scheduleCascadingViewUpdate()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionForwardToFront.exec(main, arguments)
    }
}
class ActionBackAsSession : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("backAsSession")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let session = main.currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            let duplicateSession = main.cache.duplicate(session as DataItem) as! Session // This will work when merged with multiple-data-types branch
            
            realmWriteIfAvailable(main.cache.realm, {duplicateSession.currentViewIndex -= 1})
            
            ActionOpenSession.exec(main, ["session": duplicateSession])
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionBackAsSession.exec(main, arguments)
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
    
    ///// Adds a view to the history of the currentSession and displays it. If the view was already part of the currentSession.views it
    /////  reorders it on top
    func exec(_ main:Main, _ arguments:[String: Any]) {
        if let item = arguments["session"] as? Session { self.openSession(main, item) }
        
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionOpenSession.exec(main, arguments)
    }
    
    func openSession(_ main: Main, _ session:Session) {
        let sessions = main.sessions // TODO generalize
    
        // Add view to session and set it as current
        sessions.setCurrentSession(session)
    
        // Recompute view
        main.scheduleCascadingViewUpdate()
    }
    
    func openSession(_ main: Main, _ name:String, _ variables:[String:Any]? = nil) throws {
    
        // TODO: This should not fetch the session from named sessions
        //       but instead load a sessionview that loads the named sessions by
        //       computing them (implement viewFromSession that is used in dynamic
        //       view to sessionview
    
        // Fetch a dynamic view based on its name
    }
}
class ActionOpenSessionByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": ["name": String.self, "viewArguments": [String:Any]?.self],
        "opensView": true,
    ]}
    
    convenience init(){
        self.init("openSessionByName")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
//        ActionOpenSessionByName.exec(main, arguments:arguments)
        if (arguments.count > 0) {
            if let name = arguments["name"] as? String {
                var args = arguments
                args.removeValue(forKey: "name")
                
                do {
                    var def = try! main.views.parseDefinition(main.views.fetchDefinitions(".\(name)").first)

                    if def is ViewSessionDefinition {
                        if let list = def?["views"] as? [ViewDefinition] { def = list.first }
                    }
                    
                    let session = Optional(Session())
                    
            //        let (session, _) = views.getSessionOrView(name, wrapView:true, variables)
                    if let session = session {
                
                        // Open the view
                        try  ActionOpenSession().openSession(main, name, args)
                    }
                    else {
                        print("Warn: Could not find session: '\(name)")
                    }
                    
                } catch {
                    // TODO: Log error, Error handling
                    print("COULD NOT OPEN SESSION")
                }
            }
            else {
                // TODO: "No name given"
            }
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
//        let name = arguments[0] as! String
//        let arguments_ = arguments[safe: 1]
        ActionOpenSession().exec(main, arguments)
        
    }
}

class ActionDelete : Action, ActionExec {
    convenience init(){
        self.init("delete")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
                
        // TODO this should happen automatically in ResultSet
        //        self.main.items.remove(atOffsets: indexSet)
        let indexSet = arguments["indices"] as? IndexSet
        if let indexSet = indexSet{
            var items:[DataItem] = []
            for i in indexSet {
                let item = main.items[i]
                items.append(item)
            }
        }
        
        // I'm sure there is a better way of doing this...

        let selection = main.cascadingView.userState["selection"] as [DataItem]?

        if selection?.count ?? 0 > 0 { main.cache.delete(selection!) }
        else if let item = arguments["dataItem"] as? DataItem { main.cache.delete(item) }
        main.scheduleUIUpdate{_ in true}
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionDelete().exec(main, arguments)
    }
}
class ActionDuplicate : Action, ActionExec {
    convenience init(){
        self.init("duplicate")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        let selection = main.cascadingView.userState["selection"] as [DataItem]?

        if selection?.count ?? 0 > 0 {
            selection!.forEach{ item in ActionAddDataItem.exec(main, ["dataItem": item]) }
        }
        else if let item = arguments["dataItem"] as? DataItem {
            ActionAddDataItem.exec(main, ["dataItem": item])
            
        }
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionDuplicate.exec(main, arguments)
    }
}
class ActionClosePopup : Action, ActionExec {
    
    convenience init(){
        self.init("closePopup")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        (main.closeStack.removeLast())()
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionClosePopup().exec(main, arguments)
    }
}

class ActionSetProperty : Action, ActionExec {
    convenience init(){
        self.init("setProperty")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        // TODO Refactor: Allow for multiple actions to an action description
        //                Then add a .setProperty which takes a type, uid and
        //                propName to set the property with the value from selection
        //                in order to reimplement:
        //
        //                            try! self.main.realm.write {
        //                                self.item[self.propName] = dataItem
        //                            }
        //                            self.main.scheduleUIUpdate{_ in true}
        //
        ActionSetProperty().exec(main, arguments)
    }
}

class ActionNoop : Action, ActionExec {
    convenience init(){
        self.init("noop")
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
        // do nothing
    }
    
    class func exec(_ main:Main, _ arguments:[String: Any]) {
        ActionClosePopup.exec(main, arguments)
    }
}

