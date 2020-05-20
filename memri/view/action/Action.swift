//
//  Action.swift
//  memri
//
//  Created by Koen van der Veen on 20/05/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation


class Action{
    var actionArgs: [AnyCodable] = []
    var actionType: ActionType = .button
    
    @objc dynamic var icon: String = ""
    @objc dynamic var title: String? = nil
    @objc dynamic var showTitle: Bool = false // TODO Is there ever a place where the AD determines whether the title is shown?
    @objc dynamic var actionStateName:String? = nil
    
    let hasState = RealmOptional<Bool>()
    
    var color: UIColor = .systemGray
    var backgroundColor: UIColor = .white
    var activeColor: UIColor? = .systemGreen
    var inactiveColor: UIColor? = .systemGray
    var activeBackgroundColor: UIColor? = .white
    var inactiveBackgroundColor: UIColor? = .white
        
    public func computeColor(state:Bool) -> UIColor{
        if self.hasState.value == true {
            if state {return self.activeColor ?? .systemGray}
            else {return self.inactiveColor ?? .systemGray}
        }
        else {return self.color}
    }
    
    public func computeBackgroundColor(state:Bool) -> UIColor{
        if self.hasState.value == true {
            if state {return self.activeBackgroundColor!}
            else {return self.inactiveBackgroundColor!}
        }
        else {return self.backgroundColor}
    }
    
    // Helper properties
    let _actionArgs = List<String>() // Used to store actionArgs as JSON in realm
    @objc dynamic var _actionName: String = "noop" // Used to store actionName as string in realm
    @objc dynamic var _actionType: String = "button" // Used to store actionType as string in realm
    
    
    
    
    // DYNAMIC VARS
    var defaultIcon = "exclamationmark.bubble"
    var argumentTypes = []
    var defaultHasState: String? = nil
    var opensView = false
    var defaultColor = Color(hex: "#999999").uiColor()
    var defaultBackgroundColor: UIColor = .white
    var defaultActiveColor: UIColor? = nil
    var defaultInactiveColor: UIColor? = nil
    var defaultState = false
    var defaultActiveBackgroundColor: UIColor = .white
    var defaultInactiveBackgroundColor: UIColor = .white
}

public enum ActionType: String, Codable{
    case popup, button, emptytype
}



class Noop: Action{
}
class Back: Action{
    override var defaultIcon = "chevron.left"
    override var opensView = true
    override var defaultColor = Color(hex: "#434343").uiColor()
    override var defaultInactiveColor = Color(hex: "#434343").uiColor()
}

class Add: Action{
    override var defaultIcon = "plus"
    override var argumentTypes = [DataItemFamily.self]
    override var opensView = true
    override var defaultColor = Color(hex: "#6aa84f").uiColor()
    override var defaultInactiveColor = Color(hex: "#434343").uiColor()
}

class OpenView: Action{
    override var argumentTypes = [SessionView.self, [String:Any]?.self]
    override var opensView = true
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}

class OpenDynamicView: Action{
    override var opensView = true
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class OpenViewByName: Action{
    override var argumentTypes = [String.self, [String:Any]?.self]
    override var opensView = true
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ToggleEditMode: Action{
    override var defaultIcon = "rhombus.fill"
    override var defaultHasState = true
    override var defaultActionStateName = "{currentSession.editMode}"
    override var defaultActiveColor = Color(hex: "#6aa84f").uiColor()
    override var defaultInactiveColor = Color(hex: "#434343").uiColor()
}
class ToggleFilterPanel: Action{
    override var defaultHasState = true
    override var defaultActionStateName = "{currentSession.showFilterPanel}"
    override var defaultActiveColor = Color(hex: "#6aa84f").uiColor()
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()

}
class Star: Action{
    override var defaultIcon = "star.fill"
    override var defaultHasState = true
    override var defaultActionStateName = "{dataItem.starred}"
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ShowStarred: Action{
    override var defaultIcon = "star.fill"
    override var defaultHasState = true
    override var defaultActionStateName = "showStarred"
    override var opensView = true
    override var defaultActiveColor = .systemYellow
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ShowContextPane: Action{
    override var defaultIcon = "ellipsis"
    override var defaultHasState = true
    override var defaultActionStateName = "{currentSession.showContextPane}"
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ShowOverlay: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()

}
class Share: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ShowNavigation: Action{
    override var defaultIcon = "line.horizontal.3"
    override var defaultHasState = true
    override var defaultActionStateName = "{main.showNavigation}"
    override var defaultInactiveColor = Color(hex: "#434343").uiColor()
}
class AddToPanel: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class Duplicate: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()

    
}
class Schedule: Action{
    override var defaultIcon = "alarm"
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class AddToList: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class DuplicateNote: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class NoteTimeline: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class StarredNotes: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class AllNotes: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ExampleUnpack: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class Delete: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class SetRenderer: Action{
    override var defaultActiveColor = Color(hex: "#6aa84f").uiColor()
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
    override var defaultActiveBackgroundColor = Color(hex: "#eee").uiColor()
}
class Select: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class SelectAll: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class UnselectAll: Action{
    override var defaultInactiveColor = Color(hex: "#999999").uiColor()
}
class ShowAddLabel: Action{
    
}
class OpenLabelView: Action{
    
}
class ShowSessionSwitcher: Action{
    override var defaultIcon = "ellipsis"
    override var defaultHasState = true
    override var defaultActionStateName = "{main.showSessionSwitcher}"
    override var defaultColor = Color(hex: "#CCC").uiColor()
    
}
class Forward: Action{
    override var opensView = true
    
}
class ForwardToFront: Action{
    override var opensView = true
    
}
class BackAsSession: Action{
    override var opensView = true
    
}
class OpenSession: Action{
    override var argumentTypes = [Session.self, [String:Any]?.self]
    override var opensView = true
}
class OpenSessionByName: Action{
    override var argumentTypes = [String.self, [String:Any]?.self]
    override var opensView = true
}
class AddSelectionToList: Action{
    override var argumentTypes = [DataItemFamily.self, String.self]
    
}
class ClosePopup: Action{
    
}
