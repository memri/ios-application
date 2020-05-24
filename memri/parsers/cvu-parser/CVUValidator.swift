//
//  CVUValidator.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

/*
 TODO:
    - queryOptions (cascading, etc)
    - case insensitive fields for definition
    - include
    - when looking for an array but there is only one element, wrap it in an array (while cascading)
        - or when a known field do this during parsing
    - support for array of actions in a single trigger (e.g. press)
*/

    
    // TODO REFACTOR: Move to parser
//    public func validate() throws {
//        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
//
//        let renderProps = self.renderConfigs.objectSchema.properties
//        if renderProps.filter({ (property) in property.name == self.rendererName }).count == 0 {
////            throw("Missing renderConfig for \(self.rendererName) in this view")
//            print("Warn: Missing renderConfig for \(self.rendererName) in this view")
//        }
//
//        if self.queryOptions.query == "" { throw("No query is defined for this view") }
//        if self.actionButton == nil && self.editActionButton == nil {
//            print("Warn: Missing action button in this view")
//        }
//    }

class CVUValidator {
    // Based on keyword when its added to the dict
    let knownActions:[String:String] = {
        var result = [String:String]()
        for name in ActionFamily.allCases {
            result[name.rawValue.lowercased()] = name.rawValue
        }
        return result
    }()
    // Only when key is this should it parse the properties
    let knownUIElements:[String:String] = {
        var result = [String:String]()
        for name in UIElementFamily.allCases {
            result[name.rawValue.lowercased()] = name.rawValue
        }
        return result
    }()
    
    // Check syntax errors in colors
    func validateColor(_ color:Color) throws {
        // Note this is only possible inside the parser...
    }
    
    /// Forces parsing of expression
    func validateExpression(_ expr:Expression) throws {
        try expr.validate()
    }
    
    // Check that there are no fields that are not known UIElement properties (warn)
    // Check that they have the right type (error)
    // Error if required fields are missing (e.g. text for Text, image for Image)
    func validateUIElement(_ element:UIElement) throws {
        for (key, value) in element.properties {
            if let prop = UIElementProperties(rawValue: key) {
                if prop.validate(key, value) {
                    throw "Invalid property value \(value) for \(key) at element \(element.type)."
                }
            }
            else {
                // TODO Warn to user:
                "Unknown property \(key) for element \(element.type). Typo?"
            }
        }
        
        for child in element.children {
            try validateUIElement(child)
        }
    }
    
    // Check that there are no fields that are not known Action properties (warn)
    // Check that they have the right type (error)
    func validateAction(_ action:Action) throws {
        for (key, value) in action.values {
            if let prop = ActionProperties(rawValue: key) {
                if prop.validate(key, value) {
                    throw "Invalid property value \(value ?? "nil") for \(key) at element \(action.name.rawValue)."
                }
            }
            else {
                // TODO Warn to user:
                "Unknown property \(key) for element \(action.name.rawValue). Typo?"
            }
        }
    }
    
    func validateDefinition(_ definition:CVUParsedDefinition) throws {
        func check(_ definition:CVUParsedDefinition, _ validate:(String,Any) throws -> Bool) {
            for (key, value) in definition.parsed {
                do {
                    if !(try validate(key, value)) {
                        throw "Invalid property value \(value) for \(key) at definition \(definition.selector ?? "")."
                    }
                }
                catch {
                    // TODO Warn to user:
                    "Unknown property \(key) for element \(definition.selector ?? ""). Typo?"
                }
            }
        }
        
        if definition is CVUParsedSessionsDefinition {
            check(definition) { (key, value) in
                switch key {
                case "currentSessionIndex": return value is Int
                case "sessions": return value is [CVUParsedSessionDefinition]
                default: throw "Unknown"
                }
            }
        }
        else if definition is CVUParsedSessionDefinition {
            check(definition) { (key, value) in
                switch key {
                case "name": return value is String
                case "currentViewIndex": return value is Int
                case "views": return value is [CVUParsedViewDefinition]
                case "editMode", "showFilterPanel", "showContextPane": return value is Bool
                case "screenshot": return value is File
                default: throw "Unknown"
                }
            }
        }
        else if definition is CVUParsedViewDefinition {
            check(definition) { (key, value) in
                switch key {
                case "name", "emptyResultText", "title", "subTitle", "filterText",
                     "activeRenderer", "backTitle", "searchHint":
                    return value is String
                case "userState": return value is Int
                case "queryOptions": return value is [CVUParsedViewDefinition]
                case "viewArguments": return value is Bool
                case "showLabels": return value is Bool
                case "actionButton", "editActionButton":
                    if let value = value as? Action { try validateAction(value) }
                    else { return false }
                case "sortFields": return value is [String]
                case "editButtons", "filterButtons", "actionItems",
                     "navigateItems", "contextButtons":
                    if let value = value as? [Any] {
                        for action in value {
                            if let action = action as? Action { try validateAction(action) }
                            else {
                                throw "Expected action definition but found \(action) at property \(key) of \(definition.selector ?? "")"
                            }
                        }
                    }
                    else if let action = value as? Action { try validateAction(action) }
                    else { return false }
                case "renderDefinitions": return value is File
                default: throw "Unknown"
                }
                return false
            }
        }
        else if definition is CVUParsedRendererDefinition {
            // TODO support all the properties properties
            check(definition) { (key, value) in
                if (definition.parsed[key] as? [String:Any?])?["children"] != nil {
                    return false
                }
                return true
            }
            
            if let children = definition.parsed["children"] as? [Any] {
                for child in children {
                    if let element = child as? UIElement { try validateUIElement(element) }
                    else {
                        throw "Expected element definition but found \(child) in \(definition.selector ?? "")"
                    }
                }
            }
        }
        // TODO Color, Style, Language
    }
    
    func validate(_ definitions:[CVUParsedDefinition]) throws {
        for def in definitions {
            try validateDefinition(def)
        }
    }
}
