//
//  UIElement.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift
    
public class UIElement : CVUToString {
    var type: String
    var children: [UIElement] = []
    var properties: [String:Any] = [:] // TODO ViewParserDefinitionContext
    
    init(_ type: String, children: [UIElement]? = nil, properties: [String:Any] = [:]) {
        self.type = type
        self.children = children ?? self.children
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
                       _ viewArguments:ViewArguments = ViewArguments()) -> T? {
        
        if let prop = properties[propName] {
            let propValue = prop
            
            // Execute expression to get the right value
            if let expr = propValue as? Expression {
                do { let x:T? = try expr.execute(viewArguments) as? T; return x }
                catch {
                    // TODO Refactor error handling
                    
                    return nil
                }
            }
            
            return (propValue as! T)
        }
        else {
            // TODO REfactor: WARN
        }
        
        return nil
    }
    
    public func getType(_ propName:String, _ item:DataItem) -> (PropertyType, DataItem, String) {
        // TODO REfactor: Error Handling
        if let prop = properties[propName] {
            let propValue = prop
            
            // Execute expression to get the right value
            if let expr = propValue as? Expression {
                do { return try expr.getTypeOfDataItem() }
                catch {
                    // Log error
                }
            }
        }
        
        // TODO Refactor: Error Handling
        return (.any, item, "")
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
    
    func toCVUString(_ depth:Int, _ tab:String) -> String {
        let tabs = Array(0..<depth).map{_ in ""}.joined(separator: tab)
        let tabsPlus = Array(0..<depth + 1).map{_ in ""}.joined(separator: tab)
//        let tabsEnd = Array(0..<depth - 1).map{_ in ""}.joined(separator: tab)
        
        return properties.count > 0 || children.count > 0
            ? "\(type) {\n"
                + (properties.count > 0
                    ? "\(tabsPlus)\(CVUSerializer.dictToString(properties, depth, tab, withDef: false))"
                    : "")
                + (properties.count > 0 && children.count > 0
                    ? "\n\n"
                    : "")
                + (children.count > 0
                    ? "\(tabsPlus)\(CVUSerializer.arrayToString(children, depth, tab, withDef: false, extraNewLine: true))"
                    : "")
                + "\n\(tabs)}"
            : "\(type)\n"
    }
    
    public var description: String {
        toCVUString(0, "    ")
    }
}

public enum UIElementFamily : String, CaseIterable {
    case VStack
    case HStack
    case ZStack
    case EditorSection
    case EditorRow
    case EditorLabel
    case Title
    case Button
    case FlowStack
    case Text
    case Textfield
    case ItemCell
    case SubView
    case Map
    case Picker
    case SecureField
    case Action
    case MemriButton
    case Image
    case Circle
    case HorizontalLine
    case Rectangle
    case RoundedRectangle
    case Spacer
    case Divider
    case Empty
}
