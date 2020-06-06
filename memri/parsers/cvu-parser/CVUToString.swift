//
//  CVUToString.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

protocol CVUToString : CustomStringConvertible {
    func toCVUString(_ depth:Int, _ tab:String) -> String
}

class CVUSerializer {
    
    class func valueToString(_ value:Any?, _ depth:Int = 0, _ tab:String = "    ") -> String{
        if value == nil || (value as? String != "nil") && "\(value!)" == "nil" {
            return "null"
        }
        else if let p = value {
            if let p = p as? String { //}, (p.contains(" ") || p.contains("\t") || p.contains("\"") || p == "") {
                return "\"\(p.replace("\"", "\\\\\""))\""
            }
            else if let p = p as? [Any?] {
                return arrayToString(p, depth+1, tab)
            }
            else if let p = p as? [String:Any?] {
                return dictToString(p, depth+1, tab)
            }
            else if let p = p as? CVUToString {
                return p.toCVUString(depth + 1, tab)
            }
            else if let p = p as? Color {
                return String(p.description.lowercased().prefix(7))
            }
            else if let p = p as? Double {
                if p.truncatingRemainder(dividingBy: 1) == 0 {
                    return "\(Int(p))"
                }
            }
            else if let p = p as? CGFloat {
                if p.truncatingRemainder(dividingBy: 1) == 0 {
                    return "\(Int(p))"
                }
            }
            else if let p = p as? VerticalAlignment {
                switch p {
                case .top: return "top"
                case .center: return "center"
                case .bottom: return "bottom"
                default: return "center"
                }
            }
            else if let p = p as? HorizontalAlignment {
                switch p {
                case .leading: return "left"
                case .center: return "center"
                case .trailing: return "right"
                default: return "center"
                }
            }
            else if let p = p as? Alignment {
                switch p {
                case .top: return "top"
                case .center: return "center"
                case .bottom: return "bottom"
                case .leading: return "left"
                case .trailing: return "right"
                default: return "center"
                }
            }
            else if let p = p as? TextAlignment {
                switch p {
                case .leading: return "left"
                case .center: return "center"
                case .trailing: return "right"
                }
            }
            else if let p = p as? Font.Weight {
                switch p {
                case .regular: return "regular"
                case .bold: return "bold"
                case .semibold: return "semibold"
                case .heavy: return "heavy"
                case .light: return "light"
                case .ultraLight: return "ultralight"
                case .black: return "black"
                default: return "regular"
                }
            }
            
            return "\(p)"
        }
        
        return ""
    }
    
    class func arrayToString(_ list:[Any?], _ depth:Int = 0, _ tab:String = "    ",
                             withDef:Bool = true, extraNewLine:Bool = false) -> String {
        
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        
        var str = [String]()
        var isMultiline = false
        for value in list {
            let strValue = valueToString(value, depth, tab)
            str.append(strValue)
            if !isMultiline { isMultiline = strValue.contains("\n") }
        }
        
        return withDef
            ? isMultiline
                ? "[\n\(tabs)\(str.joined(separator:"\n\(tabs)"))\n\(tabsEnd)]"
                : str.joined(separator: " ")
            : str.joined(separator: (extraNewLine ? "\n" : "") + "\n\(tabs)")
    }
    
    class func dictToString(_ dict:[String:Any?], _ depth:Int = 0, _ tab:String = "    ",
                            withDef:Bool = true, extraNewLine:Bool = false,
                            _ sortFunc:((Dictionary<String, Any?>.Keys.Element, Dictionary<String, Any?>.Keys.Element) throws -> Bool)? = nil) -> String {
        var keys:[String]
        do {
            keys = (sortFunc != nil)
                ? try dict.keys.sorted(by: sortFunc!)
                : dict.keys.sorted(by: {
                    $0 > $1
                })
        }
        catch {
            keys = dict.keys.sorted()
        }
        
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        
        var str = [String]()
        for key in keys {
            if key == "children" || key == "renderDefinitions" || key == "datasourceDefinition"
              || key == "sessionDefinitions" || key == "viewDefinitions" {
                continue
            }
            else if key == "cornerradius" {
                if var value = dict[key] as? [Any] {
                    let radius = value.popLast()
                    str.append("cornerradius: \(valueToString(radius, depth, tab))")
                    str.append("border: \(valueToString(value, depth, tab))")
                }
                else {
                    // ???
                }
            }
            else if key == "frame" {
                let names = ["minWidth", "maxWidth", "minHeight", "maxHeight", "align"]
                if let list = dict[key] as? [Any?] {
                    for i in 0..<list.count {
                        if let v = list[i] {
                            str.append("\(names[i]): \(valueToString(v, depth, tab))")
                        }
                    }
                }
            }
            else {
                if let p = dict[key] as? [String:Any?] {
                    str.append((extraNewLine ? "\n" + (withDef ? tabs : tabsEnd) : "")
                        + "\(key): \(valueToString(p, depth, tab))")
                }
                else if let value = dict[key]{
                    str.append("\(key): \(valueToString(value, depth, tab))")
                }
            }
        }
        
        var children:String = ""
        var definitions:String = ""
        if let p = dict["children"] as? [UIElement], p.count > 0 {
            let body = arrayToString(p, depth, tab, withDef:false, extraNewLine:true)
            children = "\(str.count > 0 ? "\n\n\(tabs)" : "")\(body)"
        }
        if let p = dict["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
            let body = p.toCVUString(depth - 1, tab)
            definitions = "\(str.count > 0 ? "\n\n\(tabs)" : "")\(body)"
        }
        if let p = dict["sessionDefinitions"] as? [CVUParsedSessionDefinition], p.count > 0 {
            let body = arrayToString(p, depth - 1, tab, withDef:false, extraNewLine:true)
            definitions = "\(str.count > 0 ? "\n\n\(tabs)" : "")\(body)"
        }
        if let p = dict["viewDefinitions"] as? [CVUParsedViewDefinition], p.count > 0 {
            let body = arrayToString(p, depth - 1, tab, withDef:false, extraNewLine:true)
            definitions = "\(str.count > 0 ? "\n\n\(tabs)" : "")\(body)"
        }
        if let p = dict["renderDefinitions"] as? [CVUParsedRendererDefinition], p.count > 0 {
            let body = arrayToString(p, depth - 1, tab, withDef:false, extraNewLine:true)
            definitions = "\(str.count > 0 ? "\n\n\(tabs)" : "")\(body)"
        }
        
        return withDef
            ? "{\n\(tabs)\(str.joined(separator: "\n\(tabs)"))\(children)\(definitions)\n\(tabsEnd)}"
            : "\(str.joined(separator: "\n\(tabs)"))\(children)\(definitions)"
    }
}
