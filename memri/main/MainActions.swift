//
//  MainActions.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

extension MemriContext {
    
    private func buildArguments(_ action:Action, _ dataItem:DataItem?) throws -> [String: Any] {
        var args = [String: Any]()
        for (argName, inputValue) in action.arguments {
            var argValue: Any?
            
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
                    // TODO refactor: move to function
                    if let stringType = dict["type"] as? String {
                        if let family = DataItemFamily(rawValue: stringType) {
                            if let ItemType = DataItemFamily.getType(family)() as? Object.Type {
                                var initArgs = dict
                                initArgs.removeValue(forKey: "type")

                                if let item = ItemType.init() as? DataItem{
                                    // TODO: fill item
                                    for prop in item.objectSchema.properties {
                                        if prop.name != ItemType.primaryKey(),
                                            let inputValue = initArgs[prop.name] {
                                            let propValue: Any

                                            if let expr = inputValue as? Expression {
                                                // TODO: refactor
                                                let viewArgs = ViewArguments(cascadingView.viewArguments.asDict())
                                                viewArgs.set(".", dataItem)
                                                propValue = try expr.execute(viewArgs) as Any
                                            }
                                            else {
                                                propValue = inputValue
                                            }
                                            
                                            item.set(prop.name, propValue)
//                                            item[prop.name] = initArgs[prop.name]
                                        }
                                    }
                                    
                                    finalValue = item
                                }
                                else {
                                    throw "Cannot cast type \(ItemType) to DataItem"
                                }
                            }
                            else {
                                throw "Cannot find family \(stringType)"
                            }
                        }
                        else {
                            throw "Cannot find find family \(stringType)"
                        }
                    }
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
            else {
                throw "Does not recognize argumentType \(argName)"
            }
            
            args[argName] = finalValue
        }
        
        // Last element of arguments array is the context data item
        args["dataItem"] = dataItem ?? cascadingView.resultSet.singletonItem as Any
        
        return args
    }
    
    private func executeActionThrows(_ action:Action, with dataItem:DataItem? = nil) throws {
        // Build arguments dict
        let args = try buildArguments(action, dataItem)
        
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
                
                // TODO this should be removed and fixed more generally
                self.scheduleUIUpdate() { _ in true }
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
    public func executeAction(_ action:Action, with dataItem:DataItem? = nil) {
        do {
            try executeActionThrows(action, with: dataItem)
        }
        catch let error {
            // TODO Log error to the user
            errorHistory.error("\(error)")
        }
    }
    
    public func executeAction(_ actions:[Action], with dataItem:DataItem? = nil) {
        for action in actions {
            do {
                try executeActionThrows(action, with: dataItem)
            }
            catch let error {
                // TODO Log error to the user
                errorHistory.error("\(error)")
                break
            }
        }
    }
}
