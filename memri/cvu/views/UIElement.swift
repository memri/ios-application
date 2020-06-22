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
    var properties: [String:Any?] = [:] // TODO ViewParserDefinitionContext
    
    init(_ type: UIElementFamily, children: [UIElement]? = nil, properties: [String:Any?] = [:]) {
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
                viewArguments.set(".", item) // TODO Optimization This is called a billion times. Find a better place for this
                
                do {
                    if T.self == [DataItem].self {
                        let x = try expr.execute(viewArguments);
                        
                        var result = [DataItem]()
                        if let list = x as? List<Edge> {
                            for edge in list {
                                if let d = getDataItem(edge) {
                                    result.append(d)
                                }
                            }
                        }
                        else {
                            result = dataItemListToArray(x as Any)
                        }
                        
                        return (result as! T)
                    }
                    else {
                        let x:T? = try expr.execForReturnType(viewArguments); return x
                    }
                }
                catch let error {
                    // TODO Refactor error handling
                    debugHistory.error("Could note compute \(propName)\n"
                        + "Arguments: [\(viewArguments.asDict().keys.joined(separator: ", "))]\n"
                        + (expr.startInStringMode
                            ? "Expression: \"\(expr.code)\"\n"
                            : "Expression: \(expr.code)\n")
                        + "Error: \(error)")
                    return nil
                }
            }
            return (propValue as? T)
        }
        else {
            // TODO REfactor: WARN
//            debugHistory.info("Property \(propName) not defined for \(type.rawValue)")
        }
        
        return nil
    }
    
    public func getType(_ propName:String, _ item:DataItem,
                        _ viewArguments:ViewArguments) -> (PropertyType, DataItem, String) {
        
        if let prop = properties[propName] {
            let propValue = prop
            
            // Execute expression to get the right value
            if let expr = propValue as? Expression {
                do { return try expr.getTypeOfDataItem(viewArguments) }
                catch {
                    // TODO Refactor: Error Handling
                    debugHistory.error("could not get type of \(item)")
                }
            }
        }
        
        // TODO Refactor: Error Handling
        return (.any, item, "")
    }
    
    func processText(_ text: String?) -> String? {
        guard var outText = text else { return nil }
        outText = (get("removeWhiteSpace") ?? false) ? removeWhiteSpace(text: outText) : outText
        outText = (get("maxChar") as CGFloat?).map { String(outText.prefix(Int($0))) } ?? outText
        guard outText.contains(where: { !$0.isWhitespace }) else { return nil } //Return nil if blank
        return outText
    }
    
    func removeWhiteSpace(text: String) -> String{
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines) // Remove whitespace/newLine from start/end of string
            .split { $0.isNewline }.joined(separator: " ") // Replace new-lines with a space
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
         Circle, HorizontalLine, Rectangle, RoundedRectangle, Spacer, Divider, RichTextfield, Empty
}

public enum UIElementProperties : String, CaseIterable {
    case resizable, show, alignment, align, textAlign, spacing, title, text, image, nopadding,
         press, bold, italic, underline, strikethrough, list, viewName, view, arguments, location,
         address, systemName, cornerRadius, hint, value, datasource, defaultValue, empty, style,
         frame, color, font, padding, background, rowbackground, cornerborder, border, margin,
         shadow, offset, blur, opacity, zindex, minWidth, maxWidth, minHeight, maxHeight
    
    func validate(_ key:String, _ value:Any?) -> Bool {
        if value is Expression { return true }
        
        let prop = UIElementProperties(rawValue: key)
        switch prop {
        case .resizable, .title, .text, .viewName, .systemName, .hint, .empty, .style, .defaultValue:
            return value is String
        case .show, .nopadding, .bold, .italic, .underline, .strikethrough:
            return value is Bool
        case .alignment: return value is VerticalAlignment || value is HorizontalAlignment
        case .align: return value is Alignment
        case .textAlign: return value is TextAlignment
        case .spacing, .cornerRadius, .minWidth, .maxWidth, .minHeight, .maxHeight, .blur, .opacity, .zindex:
            return value is CGFloat
        case .image: return value is File || value is String
        case .press: return value is Action || value is [Action]
        case .list: return value is [DataItem]
        case .view: return value is CVUParsedDefinition || value is [String:Any?]
        case .arguments: return value is [String:Any?]
        case .location: return value is Location
        case .address: return value is Address
        case .value: return true
        case .datasource: return value is Datasource
        case .color, .background, .rowbackground: return value is Color
        case .font:
            if let list = value as? [Any?] {
                return list[0] is CGFloat || list[0] is CGFloat && list[1] is Font.Weight
            }
            else { return value is CGFloat }
        case .padding, .margin:
            if let list = value as? [Any?] {
                return list[0] is CGFloat && list[1] is CGFloat
                    && list[2] is CGFloat && list[3] is CGFloat
            }
            else { return value is CGFloat }
        case .border:
            if let list = value as? [Any?] {
                return list[0] is Color && list[1] is CGFloat
            }
            else { return false }
        case .shadow:
            if let list = value as? [Any?] {
                return list[0] is Color && list[1] is CGFloat
                    && list[2] is CGFloat && list[3] is CGFloat
            }
            else { return false }
        case .offset:
            if let list = value as? [Any?] {
                return list[0] is CGFloat && list[1] is CGFloat
            }
            else { return false }
        default:
            return false
        }
    }
}
