//
//  CompiledView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class CompiledView {
 
    var name: String = ""
 
    var variables: [String:String] = [:]
 
    var parsed: [String:Any]? = nil
 
    var jsonString: String = ""
 
    var dynamicView:DynamicView
 
    var lastSessionView:SessionView? = nil
 
    var hasSession:Bool = false
 
    var views:[CompiledView] = []
    
    private var main:Main

    init(_ view:DynamicView, _ mn:Main) throws {
        main = mn
        dynamicView = view
    }
    
 
    func parse() throws {
        // Turn the declaration in json data
        let data = dynamicView.declaration.data(using: .utf8)!
        
        // Parse the declaration
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        guard let object = json as? [String: Any] else {
            throw "Exception: Invalid JSON while parsing view" // TODO better errors
        }
            
        // Store the parsed json in memory
        parsed = object
        
        // Detect whether this item has a session
        hasSession = object["views"] != nil
        
        // Find all dynamic properties and compile them
        func recursiveWalk(_ parsed:inout [String:Any]) throws {
            for (key, _) in parsed {

                // Do not parse actionStateName as it is handled at runtime (when action is executed)
                if key == "actionStateName" { continue }
                
                // TODO make actionArgs runtime parsed
                    
                // Turn renderDescription in a string for persistence in realm
                else if key == "renderDescription" {
                    parsed.updateValue(RenderConfig.parseRenderDescription(parsed[key]!), forKey: key)
                }
                // Same for virtual renderDescriptions
                else if key == "virtual" {
                    parsed.updateValue(RenderConfig.parseRenderDescription(parsed[key]!), forKey: key)
                }
                    
                // Parse rest of the json
                else {
                    
                    func innerWalk(_ pItem:Any) -> Any {
                        // If its an object continue the walk to find strings to update
                        var subParsed = pItem as? [String:Any]
                        if subParsed != nil {
                            try! recursiveWalk(&subParsed!)
                            return subParsed!
                        }
                        // Update arrays
                        else if var arr = pItem as? [Any] {
                            for i in 0..<arr.count {
                                arr[i] = innerWalk(arr[i])
                            }
                            return arr
                        }
                        // Update strings
                        else if let propValue = pItem as? String {
                            
                            // Compile the property for easy lookup
                            let newValue = compileProperty(propValue)
                            
                            // Updated the parsed object with the new value
                            return newValue
                        }
                        
                        return pItem
                    }
                    
                    parsed.updateValue(innerWalk(parsed[key] as Any), forKey: key)
                }
            }
        }
        
        // Generating a session of multiple compiled views
        if hasSession, let list = object["views"] as? [Any] {
            
            // Loop through all view
            for i in 0..<list.count {
                
                // If the view is a string look up its template
                if let value = list[i] as? String {
                    
                    // Find the compiled view
                    let compiledView = main.views.getCompiledView(value)
                    
                    // Append it to the list of views
                    views.append(compiledView!) // TODO error handling
                }
                    
                // Or if its a literal view parse it
                else if var value = list[i] as? [String: Any] {
                    
                    // Start walking to parse values from this part of the subtree
                    try! recursiveWalk(&value)
                    
                    // Create a dynamic view
                    let dynamicView = DynamicView(value: [
                        "declaration": serialize(AnyCodable(value))
                    ])
                    
                    // Create the compiled view
                    let compiledView = try! CompiledView(dynamicView, main)
                    
                    // Append it to the list of views
                    views.append(compiledView)
                }
            }
        }
        // Generating a single view template
        else {
            // Start walking
            try! recursiveWalk(&parsed!)
            
            // Set the new session view json
            jsonString = serialize(AnyCodable(parsed))
        }
    }
    
    public func compileProperty(_ expr:String) -> String {
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]+\.?[^\}]*)\})?)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var result:String = ""
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expr.startIndex..<expr.endIndex, in: expr)
        regex.enumerateMatches(in: expr, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            // We should have 4 matches
            if match.numberOfRanges == 3 {
                
                // Fetch the text portion of the match
                if let rangeText = Range(match.range(at: 1), in: expr) {
                    result += String(expr[rangeText])
                }
                
                // compute the string result of the expression
                if let rangeQuery = Range(match.range(at: 2), in: expr) {
                    let query = String(expr[rangeQuery])
                    
                    // Add the query to the variable list
                    if variables[query] == nil {
                        variables[query] = String(variables.count)
                    }
                    
                    // Add an easy to find reference to the string
                    result += "{$\(variables[query]!)}"
                }
            }
        }
        
        return result
    }
    
 
    func generateView(_ varValues:[String:Any]? = nil) throws -> SessionView {
        // Prevent views generated from a session template
        if self.hasSession { throw "Exception: Cannot generate view from a session template" }
        
        // Parse at first use
        if parsed == nil { try! parse() }
        
        // Return last compiled session view if this is not a dynamic view
        if dynamicView.fromTemplate == nil && variables.count == 0 && lastSessionView != nil {
            
            // Return a copy of the session view
            // TODO this can be optimized by signaling when views are used as a base in computing a view
            let view = SessionView()
            view.merge(lastSessionView!)
            
            return view
        }
        
        // Copy from the current view
        var view:SessionView? = nil
        if ["{view}", "{sessionView}"].contains(dynamicView.fromTemplate)  {
            
            // TODO add feature that validates the current view and checks whether
            //      the dynamic view can operate on it
            
            // Copy the current view
            view = SessionView()
            view!.merge(main.currentSession.currentView)
        }
        // Copy from a named view
        else if let templateName = dynamicView.fromTemplate {
            view = main.views.getSessionView(templateName) ?? SessionView()
        }
        
        var extraVars = varValues ?? [:]
        if let view = view, let vars = view.variables {
            for (key, value) in vars {
                extraVars[key] = value
            }
        }
        
        // Fill the template with variables
        let template = insertVariables(extraVars)
        
        // Generate session view from template
        let sessionView:SessionView = try! SessionView.fromJSONString(template)
        
        // Merge with the view that is copied, if any
        if let view = view {
            view.merge(sessionView)
        }
        else {
            view = sessionView
        }
        
        // Cache session view object in case it isnt dynamic
        lastSessionView = view
        
        return view!
    }
    
    func generateSession(_ variables:[String:Any]? = nil) throws -> Session {
        // Prevent views generated from a session template
        if !self.hasSession { throw "Exception: Cannot generate session from a view template" }
        
        // Parse at first use
        if parsed == nil { try! parse() }
        
        // Create new session object
        let session = Session(value: ["name": parsed!["name"] as! String])
        
//        var computedView:ComputedView
        for i in 0..<views.count {
            session.views.append(try! views[i].generateView(variables))
            
            // TODO The code below is the beginning of allow dynamic views that refer the view
            //      or computedView to get the right reference. A major problem is that the data
            //      may not be loaded yet. This may be solved by loading from cache, or annotating
            //      the session view description. More thought is needed, so I'm leaving that out
            //      for now
            
//            overrides:[
//                "view": { () -> Any in views[i - 1] ?? nil },
//                "computedView": { () -> Any in
//                    if let cv = computedView { return computedView }
//                    else if i > 0 {
//                        computedView = main.views.computeView(session.views[i - 1])
//                        return computedView!
//                    }
//                }
//            ])
        }
        
        // set current session indicator to last element
        session.currentViewIndex = session.views.count - 1
        
        return session
    }
    
    public func insertVariables(_ extraVars:[String:Any]) -> String {
        var i = 0, template = jsonString
        for (key, index) in variables {
            // Compute the value of the variable
            let computedValue = queryObject(key, extraVars)
            
            // Update the template with the variable
            // TODO make this more efficient. This could just be one regex search
            template = template.replace("\\{\\$" + index + "\\}", computedValue)
            
            // Increment counter
            i += 1
        }
        
        return template
    }
    
    public func queryObject(_ expr:String, _ extraVars:[String:Any]) -> String{

//        let isNegationTest = expression.first == "!"
//        let expr = isNegationTest
//            ? expression.substr(1)
//            : expression
        
        // Split the property by dots to look up each property separately
        let propParts = expr == "."
            ? ["."]
            : expr
                .split(separator: ".", omittingEmptySubsequences: false)
                .map{ String($0) }
        
        // Get the first property of the object
        var value:Any? = getProperty(propParts[0], propParts[safe: 1] ?? "", extraVars)
        
//        if isNegationTest { value = negateAny(value) }
        
        // Check if the value is not nil
        if value != nil {
            
            // Loop through the properties and fetch each
            if propParts.count > 2 {
                for i in 2..<propParts.count {
                    value = (value as! Object)[propParts[i]]
                }
            }
            
            // Return the value as a string
            return value as! String
        }
        
        return ""
    }
    
    public func getProperty(_ object:String, _ prop:String, _ extraVars:[String:Any]) -> Any? {
        // Fetch the value of the right property on the right object
        switch object {
        case "main":
            return main[prop]
        case "sessions":
            return main.sessions[prop]
        case "currentSession":
            fallthrough
        case "session":
            return main.currentSession[prop]
        case "computedView":
            return main.computedView.getPropertyValue(prop)
        case "sessionView":
            return main.currentSession.currentView[prop]
        case "view":
            return main.computedView.getPropertyValue(prop)
        case "dataItem":
            // TODO Refactor into a variables/arguments object
            if let itemRef = extraVars["."] as? DataItemReference {
                let type = DataItemFamily.getType(itemRef.type)
                let item = main.realm.object(ofType: type() as! Object.Type, forPrimaryKey: itemRef.uid)
                return item?[prop]
            }
            else if let item = extraVars["."] as? DataItem ?? main.computedView.resultSet.singletonItem {
                return item[prop]
            }
            else {
                print("Warning: No item found to get the property off")
            }
        default:
            if let value = extraVars[object == "" ? "." : object] {
                // TODO Refactor into a variables/arguments object
                if let itemRef = value as? DataItemReference {
                    let type = DataItemFamily.getType(itemRef.type)
                    let item = main.realm.object(ofType: type() as! Object.Type, forPrimaryKey: itemRef.uid)
                    
                    if prop == "" { return item }
                    else { return item?[prop] } // TODO error handling
                }
                else {
                    if prop == "" { return value }
                    else { return (value as? Object)?[prop] } // TODO error handling
                }
            }
            
            print("Warning: Unknown object to get the property off: \(object) \(prop)")
        }
        
        return nil
    }
    
    public class func parseNamedViewList(_ data:Data) throws -> [DynamicView]? {
        
        // Parse JSON
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        if var parsedList = json as? [[String: Any]] {
            
            // Define result
            var result:[DynamicView] = []
            
            // Loop over results from parsed json
            for i in 0..<parsedList.count {
                
                // Create the dynamic view
                let view = DynamicView()
                
                // Parse values out of json
                if parsedList[i]["views"] == nil {
                    view.name = parsedList[i].removeValue(forKey: "name") as! String
                    view.fromTemplate = parsedList[i].removeValue(forKey: "fromTemplate") as? String ?? nil
                }
                else {
                    view.name = parsedList[i]["name"] as! String
                }
                
                view.declaration = serialize(AnyCodable(parsedList[i]))
                
                // Add the dynamic view to the result
                result.append(view)
            }
            
            return result
        }
        else {
            print("Warn: Invalid JSON while reading named view list")
        }
        
        return nil
    }
    
    public class func parseNamedViewDict(_ data:Data) throws -> ([String:[String:DynamicView]], [String:DynamicView]) {
        
        // Parse JSON
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        guard let parsedObject = json as? [String: [String: Any]] else {
            throw "Exception: Invalid JSON while reading named view list"
        }
            
        // Define result
        var result:[String:[String:DynamicView]] = [:]
        var named:[String:DynamicView] = [:]
        
        // Loop over results from parsed json
        for (section, lut) in parsedObject {
        
            // Loop over lookup table with named views
            for (key, object) in lut {
                let object = object as! [String:Any]
                    
                // Create the dynamic view
                let view = DynamicView()
                
                // Parse values out of json
                view.name = section + ":" + key
                view.fromTemplate = nil
                view.declaration = serialize(AnyCodable(object))
                
                // Add the dynamic view to the result
                if result[section] == nil { result[section] = [:] }
                
                // Store based on key
                result[section]![key] = view
                
                // Store based on name if set
                if object["name"] != nil {
                    named[object["name"] as! String] = view
                }
            }
        }
        
        // Done
        return (result, named)
    }
    
    public class func parseExpression(_ expression:String, _ defObject:String) -> (object:String, prop:String) {
        // By default we update the named property on the view
        var objectToUpdate:String = defObject, propToUpdate:String = expression
        
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"\{([^\.]+).(.*)\}"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expression.startIndex..<expression.endIndex, in: expression)
        regex.enumerateMatches(in: expression, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            if match.numberOfRanges == 3,
              let rangeObject = Range(match.range(at: 1), in: expression),
              let rangeProp = Range(match.range(at: 2), in: expression)
            {
                objectToUpdate = String(expression[rangeObject])
                propToUpdate = String(expression[rangeProp])
            }
        }
        
        return (objectToUpdate, propToUpdate)
    }
}
