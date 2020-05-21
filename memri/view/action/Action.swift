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
    case back, add, openView, openDynamicView, openViewByName, toggleEditMode, toggleFilterPanel,
        star, showStarred, showContextPane, showOverlay, share, showNavigation, addToPanel, duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        delete, setRenderer, select, selectAll, unselectAll, showAddLabel, openLabelView,
        showSessionSwitcher, forward, forwardToFront, backAsSession, openSession, openSessionByName,
        addSelectionToList, closePopup, noop

    func getType() -> Action.Type {
        switch self {
        case .back:
            return ActionBack.self
        case .add:
            return ActionAdd.self
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

class ActionBack : Action {
    private var defaults:[String:Any] {[
        "icon": "chevron.left",
        "opensView": true,
        "color": Color(hex: "#434343"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionAdd : Action {
    private var defaults:[String:Any] {[
        "icon": "plus",
        "argumentTypes": [DataItemFamily.self],
        "opensView": true,
        "color": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionOpenView : Action {
    private var defaults:[String:Any] {[
        "argumentTypes": [SessionView.self, [String:Any]?.self],
        "opensView": true
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionOpenDynamicView : Action {
    private var defaults:[String:Any] {[
        "opensView": true
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionOpenViewByName : Action {
    private var defaults:[String:Any] {[
        "argumentTypes": [String.self, [String:Any]?.self],
        "opensView": true
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionToggleEditMode : Action {
    private var defaults:[String:Any] {[
        "icon": "rhombus.fill",
        "hasState": true,
        "binding": Expression("currentSession.editMode"),
        "activeColor": Color(hex: "#6aa84f"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionToggleFilterPanel : Action {
    private var defaults:[String:Any] {[
        "hasState": true,
        "binding": Expression("currentSession.showFilterPanel"),
        "activeColor": Color(hex: "#6aa84f")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionStar : Action {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "{dataItem.starred}"
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionShowStarred : Action {
    private var defaults:[String:Any] {[
        "icon": "star.fill",
        "hasState": true,
        "binding": "showStarred",
        "opensView": true,
        "activeColor": Color(hex: "#ffdb00")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionShowContextPane : Action {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("currentSession.showContextPane")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionShowNavigation : Action {
    private var defaults:[String:Any] {[
        "icon": "line.horizontal.3",
        "hasState": true,
        "binding": Expression("main.showNavigation"),
        "inactiveColor": Color(hex: "#434343")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionSchedule : Action {
    private var defaults:[String:Any] {[
        "icon": "alarm"
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionSetRenderer : Action {
    private var defaults:[String:Any] {[
        "activeColor": Color(hex: "#6aa84f"),
        "activeBackgroundColor": Color(hex: "#eee")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionShowSessionSwitcher : Action {
    private var defaults:[String:Any] {[
        "icon": "ellipsis",
        "hasState": true,
        "binding": Expression("main.showSessionSwitcher"),
        "color": Color(hex: "#CCC")
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionForward : Action {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionForwardToFront : Action {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionBackAsSession : Action {
    private var defaults:[String:Any] {[
        "opensView": true,
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionOpenSession : Action {
    private var defaults:[String:Any] {[
        "argumentTypes": [Session.self, [String:Any]?.self],
        "opensView": true,
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionOpenSessionByName : Action {
    private var defaults:[String:Any] {[
        "argumentTypes": [String.self, [String:Any]?.self],
        "opensView": true,
    ]}
    
    func exec() -> Any {
        
    }
}
class ActionAddSelectionToList : Action {
    private var defaults:[String:Any] {[
        "argumentTypes": [DataItemFamily.self, String.self]
        ]}
    
    func exec() -> Any {
        
    }
}
