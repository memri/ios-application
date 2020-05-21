//
//  Action.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class Colors {
    func byName(_ name:String) -> Color {
        return Color(hex: "#fff")
    }
}
var globalColors = Colors()

class Action : CustomStringConvertible{
    var name:ActionName = .noop
    var arguments: [Any] = []
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
    
    var argumentTypes:[AnyObject.Type] = []
    
    private var defaults:[String:Any] { return [:] }
    
    public var description: String {
        return "\(name))"
    }
    
    init(_ name:String,
         icon:String? = nil,
         title:String? = nil,
         showTitle:Bool? = nil,
         binding:Expression? = nil,
         hasState:Bool? = nil,
         opensView:Bool? = nil,
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
        
        self.icon = icon ?? defForName["icon"] as? String ?? self.icon
        self.title = title ?? defForName["icon"] as? String ?? self.title
        self.showTitle = showTitle ?? defForName["icon"] as? Bool ?? self.showTitle
        self.binding = binding ?? defForName["icon"] as? Expression ?? self.binding
        self.hasState = hasState ?? defForName["icon"] as? Bool ?? self.hasState
        self.opensView = opensView ?? defForName["icon"] as? Bool ?? self.opensView
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
        case .showOverlay:
            return ActionShowOverlay.self
        case .share:
            return ActionShare.self
        case .showNavigation:
            return ActionShowNavigation.self
        case .addToPanel:
            return ActionAddToPanel.self
        case .duplicate:
            return ActionDuplicate.self
        case .schedule:
            return ActionSchedule.self
        case .addToList:
            return ActionAddToList.self
        case .duplicateNote:
            return ActionDuplicateNote.self
        case .noteTimeline:
            return ActionNoteTimeline.self
        case .starredNotes:
            return ActionStarredNotes.self
        case .allNotes:
            return ActionAllNotes.self
        case .exampleUnpack:
            return ActionExampleUnpack.self
        case .delete:
            return ActionDelete.self
        case .setRenderer:
            return ActionSetRenderer.self
        case .select:
            return ActionSelect.self
        case .selectAll:
            return ActionSelectAll.self
        case .unselectAll:
            return ActionUnselectAll.self
        case .showAddLabel:
            return ActionShowAddLabel.self
        case .openLabelView:
            return ActionOpenLabelView.self
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
        case .addSelectionToList:
            return ActionAddSelectionToList.self
        case .closePopup:
            return ActionClosePopup.self
        case .noop:
            return ActionNoop.self
        }
    }
}

protocol ActionExec {
    func exec(_ main:Main, arguments:[Any])
}

private class ActionBack : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "chevron.left",
        "opensView": true,
        "color": Color(hex: "#434343"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionBack.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            try! realm.write {
                session.currentViewIndex -= 1
            }
            
            scheduleComputeView()
        }
    }
}
private class ActionAddDataItem : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "plus",
        "argumentTypes": [DataItemFamily.self],
        "opensView": true,
        "color": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionAddDataItem.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        addFromTemplate(params[0].value as! DataItem)
        
        // Copy template
        let copy = main.cache.duplicate(template)
        
        // Add the new item to the cache
        _ = try! main.cache.addToCache(copy)
        
        // Open view with the now managed copy
        ActionOpenView.exec(main, [copy])
    }
}

///// Adds a view to the history of the currentSession and displays it.
///// If the view was already part of the currentSession.views it reorders it on top
//func openView(_ view:SessionView, _ variables:[String:Any]? = nil) {
//    let session = self.currentSession
//
//    // Toggle the state to true
//    if let stateName = variables?["stateName"] as? String { view.toggleState(stateName) }
//
//    // Add view to session
//    session.setCurrentView(view)
//
//    // Register variables
//    try! realm.write {
//        view.variables = variables
//    }
//
//    // Set accessed date to now
//    view.access()
//
//    // Recompute view
//    scheduleComputeView()
//}
//
//func openView(_ item:DataItem, _ variables:[String:Any]? = nil){
//    // Create a new view
//    let view = SessionView()
//
//    // Set the query options to load the item
//    let primKey = DataItemFamily(rawValue: item.genericType)!.getPrimaryKey()
//    view.queryOptions!.query = "\(item.genericType) AND \(primKey) = '\(item.getString(primKey))'"
//
//    // Open the view
//    openView(view, variables)
//}
//
//public func openView(_ viewName: String, _ variables:[String:Any]? = nil) {
//
//    // Fetch a dynamic view based on its name
//    if let view:SessionView = views.getSessionView(viewName, variables) {
//
//        // Open the view
//        openView(view, variables)
//    }
//    else {
//        print("Warn: Could not find view: '\(viewName)")
//    }
//}
//public func openView(_ items: [DataItem], _ variables:[String:Any]? = nil) {}
//

private class ActionOpenView : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": [SessionView.self, [String:Any]?.self],
        "opensView": true
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionOpenView.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        if (params.count > 0) {
            let view = params[0].value as! SessionView
            let variables = params[safe: 1]?.value as? [String:Any]
            
            openView(view, variables)
        }
        else if selection.count > 0 { openView(selection) } // TODO does this mean anything?
        else if let item = item as? SessionView { openView(item) }
        else if let item = item { openView(item) }
    }
}
private class ActionOpenDynamicView : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionOpenDynamicView.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let name = params[0].value as! String
        let variables = params[safe: 1]?.value as? [String:Any]
        
        openView(name, variables)
    }
}
private class ActionOpenViewByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": [String.self, [String:Any]?.self],
        "opensView": true
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionOpenViewByName.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        
    }
}
private class ActionToggleEditMode : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "rhombus.fill",
        "hasState": true,
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionToggleEditMode.exec(main, arguments:arguments)
    }
    
    func exec(_ main:Main, arguments:[Any]) {
        // Do Nothing
    }
}
private class ActionToggleFilterPanel : Action, ActionExec {
    private var defaults:[String:Any] {[
        "hasState": true,
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionToggleFilterPanel.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        // Do Nothing
    }
}
private class ActionStar : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "{dataItem.starred}"
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionStar.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        if selection.count > 0, let item = item { star(selection, item.starred) }
        
        try! realm.write {
            for item in items {
                item.starred = toValue
            }
        }
        
        // TODO if starring is ever allowed in a list resultset view,
        // it won't be updated as of now
    }
}
private class ActionShowStarred : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "showStarred",
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionShowStarred.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        showStarred(starButton: action)
        
        // If button is active lets create a filtered view
        if !self.computedView.hasState(starButton.actionStateName!) {
        
            // Open named view 'showStarred'
            openView("filter-starred", ["stateName": starButton.actionStateName as Any])
        }
        else {
            // Go back to the previous view
            back()
        }
    }
}
private class ActionShowContextPane : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("currentSession.showContextPane")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionShowContextPane.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        // Do Nothing
    }
}
private class ActionShowNavigation : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "line.horizontal.3",
        "hasState": true,
        "binding": Expression("main.showNavigation"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionShowNavigation.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        // Do Nothing
    }
}
private class ActionSchedule : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "alarm"
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionSchedule.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        
    }
}
private class ActionSetRenderer : Action, ActionExec {
    private var defaults:[String:Any] {[
        "activeColor": Color(hex: "#6aa84f"),
        "activeBackgroundColor": Color(hex: "#eee")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionSetRenderer.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        changeRenderer(rendererObject: action as! Renderer)
//
//        self.setInactive(objects: Array(self.renderObjects.values))
    
        //
//        setActive(object: rendererObject)
    
        //
        let session = currentSession
        try! realm.write {
            session.currentView.rendererName = rendererObject.name
        }
        
        //
        scheduleComputeView()
    }
}
private class ActionShowSessionSwitcher : Action, ActionExec {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("main.showSessionSwitcher"),
        "color": Color(hex: "#CCC")
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionShowSessionSwitcher.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        // Do Nothing
    }
}
private class ActionForward : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionForward.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let session = currentSession
        
        if session.currentViewIndex == session.views.count - 1 {
            print("Warn: Can't go forward. Already at last view in session")
        }
        else {
            try! realm.write {
                session.currentViewIndex += 1
            }
            
            scheduleComputeView()
        }
    }
}
private class ActionForwardToFront : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionForwardToFront.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let session = currentSession
        
        try! realm.write {
            session.currentViewIndex = session.views.count - 1
        }
        
        scheduleComputeView()
    }
}
private class ActionBackAsSession : Action, ActionExec {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionBackAsSession.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            let duplicateSession = cache.duplicate(session as DataItem) as! Session // This will work when merged with multiple-data-types branch
            
            try! realm.write {
                duplicateSession.currentViewIndex -= 1
            }
            
            openSession(duplicateSession)
        }
    }
}
///// Adds a view to the history of the currentSession and displays it. If the view was already part of the currentSession.views it
/////  reorders it on top
//func openSession(_ session:Session) {
//    let sessions = self.sessions // TODO generalize
//
//    // Add view to session and set it as current
//    sessions.setCurrentSession(session)
//
//    // Recompute view
//    scheduleComputeView()
//}
//
//public func openSession(_ name:String, _ variables:[String:Any]? = nil) {
//
//    // TODO: This should not fetch the session from named sessions
//    //       but instead load a sessionview that loads the named sessions by
//    //       computing them (implement viewFromSession that is used in dynamic
//    //       view to sessionview
//
//    // Fetch a dynamic view based on its name
//    let (session, _) = views.getSessionOrView(name, wrapView:true, variables)
//    if let session = session {
//
//        // Open the view
//        openSession(session)
//    }
//    else {
//        print("Warn: Could not find session: '\(name)")
//    }
//}
private class ActionOpenSession : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": [Session.self, [String:Any]?.self],
        "opensView": true,
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionOpenSession.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        if (params.count > 0) {
            let name = params[0].value as! String
            let variables = params[safe: 1]?.value as? [String:Any]
            
            openSession(name, variables)
        }
        else if let item = item as? Session { openSession(item) }
    }
}
private class ActionOpenSessionByName : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": [String.self, [String:Any]?.self],
        "opensView": true,
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionOpenSessionByName.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        let name = params[0].value as! String
        let variables = params[safe: 1]?.value as? [String:Any]
        
        openSession(name, variables)
    }
}
private class ActionAddSelectionToList : Action, ActionExec {
    private var defaults:[String:Any] {[
        "argumentTypes": [DataItemFamily.self, String.self]
    ]}
    
    func exec(_ main:Main, arguments:[Any]) {
        ActionAddSelectionToList.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        
    }
}
private class ActionDelete : Action, ActionExec {
    func exec(_ main:Main, arguments:[Any]) {
        ActionDelete.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        if selection.count > 0 { cache.delete(selection) }
        else if let item = item { cache.delete(item) }
        scheduleUIUpdate{_ in true}
    }
}
private class ActionDuplicate : Action, ActionExec {
    func exec(_ main:Main, arguments:[Any]) {
        ActionDuplicate.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        if selection.count > 0 {
            selection.forEach{ item in addFromTemplate(item) }
        }
        else if let item = item { addFromTemplate(item) }

    }
}
private class ActionClosePopup : Action, ActionExec {
    func exec(_ main:Main, arguments:[Any]) {
        ActionClosePopup.exec(main, arguments:arguments)
    }
    
    class func exec(_ main:Main, arguments:[Any]) {
        (self.closeStack.removeLast())()
    }
}


