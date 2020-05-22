//
//  UIElement.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
    
public class UIElement : CustomStringConvertible {
    var type: String = ""
    var children: [UIElement] = []
    var properties: [String:Any] = [:] // TODO ViewParserDefinitionContext
    
    init(type: String, children: [UIElement] = [], properties: [String:Any]) {
        self.type = type
        self.children = children
        self.properties = properties
    }
    
    public func has(_ propName:String) -> Bool {
        return properties[propName] != nil
    }
    
    public func getString(_ propName:String, _ item:DataItem? = nil) -> String {
        return get(propName, item) ?? ""
    }
    
    public func getBool(_ propName:String, _ item:DataItem? = nil) -> Bool {
        return get(propName, item) ?? false
    }
    
    public func get<T>(_ propName:String, _ item:DataItem? = nil,
                       _ viewArguments:[String:Any] = [:]) -> T? {
        
        if let prop = properties[propName] {
            let propValue = prop
            
            // Execute expression to get the right value
            if let expr = propValue as? Expression {
                let x:T? = expr.execute(variables: viewArguments)
                return x
            }
            
            return (propValue as! T)
        }
        else {
            // TODO REfactor: WARN
        }
        
        return nil
    }
    
    public func getType(_ propName:String, _ item:DataItem) -> (PropertyType, String) {
        // TODO REfactor: Error Handling
        if let prop = properties[propName] {
            let propValue = prop
            
            // Execute expression to get the right value
            if let expr = propValue as? Expression {
                return expr.getTypeOfDataItem() // Should return (type, dataItem, propName)
            }
        }
        
        // TODO Refactor: Error Handling
        return (.any, "")
    }
    
    func processText(_ text: String) -> String{
        var outText = text
        let maxChar:CGFloat? = get("maxchar")
        
        outText = get("removewhitespace") ?? false ? removeWhiteSpace(text: text) : text
        outText = maxChar != nil ? String(outText.prefix(Int(maxChar!))) : outText
        
        return outText
    }
    
    func removeWhiteSpace(text: String) -> String{
        return text.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
    }
    
    func serializeDict() -> String {
        let keys = properties.keys.sorted()
        
        var str = [String]()
        for key in keys {
            if let p = properties[key] as? String {
                str.append("\(key): \"\(p)\"")
            }
            else {
                str.append("\(key): \(properties[key] ?? "")")
            }
        }
        
        return "\(str.joined(separator: ", "))" // TODO remove [ and ]
    }
    
    public var description: String {
        return "\(type) { \(serializeDict()) \(children.count > 0 ? ", \(children.map{ $0.description }.joined(separator: ", "))" : "")}"
    }
}
