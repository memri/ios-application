//
//  UIElement.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift
    
public class UIElement : CVUToString {
    var type: UIElementFamily
    var children: [UIElement] = []
    var properties: [String:Any] = [:] // TODO ViewParserDefinitionContext
    
    init(_ type: UIElementFamily, children: [UIElement]? = nil, properties: [String:Any] = [:]) {
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
                viewArguments.set(".", item)
                
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
    case VStack, HStack, ZStack, EditorSection, EditorRow, EditorLabel, Title, Button, FlowStack,
         Text, Textfield, ItemCell, SubView, Map, Picker, SecureField, Action, MemriButton, Image,
         Circle, HorizontalLine, Rectangle, RoundedRectangle, Spacer, Divider, Empty
}

public enum UIElementProperties : String, CaseIterable {
    case resizable, show, alignment, align, textalign, spacing, title, text, image, nopadding,
         press, bold, italic, underline, strikethrough, list, viewName, view, arguments, location,
         address, systemname, cornerradius, hint, value, datasource, defaultValue, empty, style,
         frame, color, font, padding, background, rowbackground, cornerborder, border, margin,
         shadow, offset, blur, opacity, zindex, minWidth, maxWidth, minHeight, maxHeight
    
    func validate(_ key:String, _ value:Any) -> Bool {
        if value is Expression { return true }
        
        let prop = UIElementProperties(rawValue: key)
        switch prop {
        case .resizable, .title, .text, .viewName, .systemname, .hint, .empty, .style, .defaultValue:
            return value is String
        case .show, .nopadding, .bold, .italic, .underline, .strikethrough:
            return value is Bool
        case .alignment: return value is VerticalAlignment || value is HorizontalAlignment
        case .align: return value is Alignment
        case .textalign: return value is TextAlignment
        case .spacing, .cornerradius, .minWidth, .maxWidth, .minHeight, .maxHeight, .blur, .opacity, .zindex:
            return value is CGFloat
        case .image: return value is File || value is String
        case .press: return value is Action || value is [Action]
        case .list: return value is [DataItem]
        case .view: return value is CVUParsedDefinition || value is [String:Any]
        case .arguments: return value is [String:Any]
        case .location: return value is Location
        case .address: return value is Address
        case .value: return true
        case .datasource: return value is Datasource
        case .color, .background, .rowbackground: return value is Color
        case .font:
            if let list = value as? [Any] {
                return list[0] is CGFloat || list[0] is CGFloat && list[1] is Font.Weight
            }
            else { return value is CGFloat }
        case .padding, .margin:
            if let list = value as? [Any] {
                return list[0] is CGFloat && list[1] is CGFloat
                    && list[2] is CGFloat && list[3] is CGFloat
            }
            else { return value is CGFloat }
        case .border:
            if let list = value as? [Any] {
                return list[0] is Color && list[1] is CGFloat
            }
            else { return false }
        case .shadow:
            if let list = value as? [Any] {
                return list[0] is Color && list[1] is CGFloat
                    && list[2] is CGFloat && list[3] is CGFloat
            }
            else { return false }
        case .offset:
            if let list = value as? [Any] {
                return list[0] is CGFloat && list[1] is CGFloat
            }
            else { return false }
        default:
            return false
        }
    }
}
