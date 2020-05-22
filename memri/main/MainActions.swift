//
//  MainActions.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

extension Main {
    
    /*
       TODO: pass options to openView and eventually to where computeView is called
             add options to cascadingView before it is assigned to main
             add variable support to compiledView parser and variable lookup
    
             also include openSession below, this requires variables to be on session
             and sessionview as well for persistence.
    
             In fact by setting the variables on session and allowing action
             descriptions and renderers to set those variables, a whole set of views
             can keep state across the session allowing for a slew of new
             functionalities. For instance the added value or values from a list can
             be stored in the session, thereby giving the previous session the ability
             to highlight the additions.
    
             In order for session choose-item-by-query to be able to add the selection
             and then go back, Action needs to support a set of actions. e.g.
    
                   Action(
                       actionName: [.addSelectionToList, .back],
                       .actionArgs: [[{dataItem}, {propertyName}], []]
                   )
    
             That is still acceptable and in line with SwiftUIs APIs.
    
             We also need to add editMode to SessionView. It means that when the view
             is shown, it starts in editMode when it is loaded, including from back.
             Usually, I suspect this functionality is only used for ephemeral views.
    
             Ephemeral views are removed from session when one navigates away from them.
    */
    
    private func executeActionThrows(_ action:Action, with dataItem:DataItem? = nil) throws {
        // Build arguments dict
        var args = [String: Any]()
        for (argName, inputValue) in action.arguments {
            var argValue: Any
            
            // preprocess arg
            if let expr = inputValue as? Expression {
                argValue = try expr.execute(cascadingView.viewArguments) as Any
            }
            else {
                argValue = inputValue
            }
            
            var finalValue:Any = ""
            if let dict = argValue as? [String: Any] {
                if action.argumentTypes[argName] == ViewArguments.self {
                    finalValue = ViewArguments(dict)
                }
                else if action.argumentTypes[argName] == DataItemFamily.self {
                    if let stringType = dict["type"] as? String,
                       let family = DataItemFamily(rawValue: stringType) {
                        
                        let ItemType = DataItemFamily.getType(family)() as! Object.Type
                        finalValue = ItemType.init() as! DataItem
//                         (value: dict)
                    }
                }
                else if action.argumentTypes[argName] == SessionView.self {
                    let viewDef = ViewDefinition(DataItem.generateUUID())
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
            else {
                throw "Does not recognize argumentType \(argName)"
            }
            
            args[argName] = finalValue
        }
        
        // Last element of arguments array is the context data item
        args["dataItem"] = dataItem ?? cascadingView.resultSet.singletonItem as Any
        
        if action.opensView {
            if let action = action as? ActionExec {
                try action.exec(self, args)
            }
            else {
                print("Missing exec for action \(action.name), NOT EXECUTING")
            }
        }
        else {
            
            // Track state of the action and toggle the state variable based on actionStateName
            // TODO Refactor: it should be the new way of doing selection
            if (cascadingView.userState["selection"] as? [DataItem])?.count == 0
                && action.hasState, let binding = action.binding {
                
                try binding.toggleBool()
            }
            
            if let action = action as? ActionExec {
                try action.exec(self, args)
            }
            else {
                print("Missing exec for action \(action.name), NOT EXECUTING")
            }
        }
    }
    
    /// Executes the action as described in the action description
    public func executeAction(_ action:Action, with dataItem:DataItem? = nil) {
        do {
            try executeActionThrows(action, with: dataItem)
        }
        catch {
            // TODO Log error to the user
        }
    }
    
    public func executeAction(_ actions:[Action], with dataItem:DataItem? = nil) {
        for action in actions {
            do {
                try executeActionThrows(action, with: dataItem)
            }
            catch {
                // TODO Log error to the user
                
                break
            }
        }
    }
}


// TODO Refactor: move to Expression
//func toggleState(_ statePattern:String, _ itm:DataItem? = nil) {
//    // Make sure we have an item update
//    let item = itm ?? cascadingView.resultSet.singletonItem
//
//    // Parse the state pattern
//    let (objectToUpdate, propToUpdate) = CompiledView.parseExpression(statePattern, "view")
//
//    // TODO error handling
//
//    // Persist these changes
//    try! realm.write {
//
//        // Toggle the right property on the right object
//        switch objectToUpdate {
//        case "main":
//            self[propToUpdate] = !(self[propToUpdate] as! Bool)
//        case "sessions":
//            self.sessions[propToUpdate] = !(self.sessions[propToUpdate] as! Bool)
//        case "currentSession":
//            fallthrough
//        case "session":
//            self.currentSession[propToUpdate] = !(self.currentSession[propToUpdate] as! Bool)
//        case "cascadingView":
//            self.cascadingView.toggleState(propToUpdate)
//        case "sessionView":
//            self.currentSession.currentView.toggleState(propToUpdate)
//            updateCascadingView()
//        case "view":
//            self.cascadingView.toggleState(propToUpdate)
//            self.currentSession.currentView.toggleState(propToUpdate)
//        case "dataItem":
//            if let item = item {
//                item[propToUpdate] = !(item[propToUpdate] as! Bool)
//
//                // TODO currently there are no listeners on data??
//                scheduleUIUpdate{_ in true}
//            }
//            else {
//                print("Warning: No item found to update")
//            }
//        default:
//            print("Warning: Unknown object to update: \(statePattern)")
//        }
//    }
//}
//
//func hasState(_ statePattern:String, _ itm:DataItem? = nil) -> Bool {
//    // Make sure we have an item update
//    let item = itm ?? cascadingView.resultSet.singletonItem
//
//    // Parse the state pattern
//    let (objectToQuery, propToQuery) = CompiledView.parseExpression(statePattern, "view")
//
//    // Toggle the right property on the right object
//    switch objectToQuery {
//    case "main":
//        return self[propToQuery] as? Bool ?? false // TODO REfactor: Error handling
//    case "sessions":
//        return self.sessions[propToQuery] as? Bool ?? false // TODO REfactor: Error handling
//    case "currentSession":
//        fallthrough
//    case "session":
//        return self.currentSession[propToQuery] as? Bool ?? false // TODO REfactor: Error handling
//    case "cascadingView":
//        return self.cascadingView.hasState(propToQuery)
//    case "sessionView":
//        return self.currentSession.currentView.hasState(propToQuery)
//    case "view":
//        return self.cascadingView.hasState(propToQuery)
//    case "dataItem":
//        if let item = item {
//            return item[propToQuery] as? Bool ?? false  // TODO REfactor: Error handling
//        }
//        else {
//            print("Warning: No item found to query")
//        }
//    default:
//        print("Warning: Unknown object to query: \(statePattern) \(objectToQuery) \(propToQuery)")
//    }
//
//    return false
//}
