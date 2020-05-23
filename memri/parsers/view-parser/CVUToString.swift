//
//  CVUToString.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

protocol CVUToString : CustomStringConvertible {
    func toString(_ depth:Int, _ tab:String) -> String
}

class CVUSerializer {
    
    class func arrayToString(_ list:[Any?], _ depth:Int = 0, _ tab:String = "    ", _ dec:Bool = true) -> String {
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        
        var str = [String]()
        var isMultiline = false
        for value in list {
            let strValue = value is CVUToString
                ? (value as? CVUToString)?.toString(depth + 1, tab) ?? "nil"
                : "\(value ?? "nil")"
            str.append(strValue)
            if !isMultiline { isMultiline = strValue.contains("\n") }
        }
        
        return dec
            ? isMultiline
                ? "[\n\(tabs)\(str.joined(separator:"\n\(tabs)"))\(tabsEnd)\n\(tabsEnd)]"
                : str.joined(separator: " ")
            : str.joined(separator: "\n\(tabs)")
    }
    
    class func dictToString(_ dict:[String:Any?], _ depth:Int = 0, _ tab:String = "    ", _ dec:Bool = true) -> String {
        let keys = dict.keys.sorted()
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = depth > 0 ? Array(0..<depth - 1).map{_ in tab}.joined() : ""
        
        var str = [String]()
        for key in keys {
            if key == "children" || key == "renderDefinitions" {
                continue
            }
            else if dict[key] == nil {
                str.append("\(key): null")
            }
            else if let p = dict[key]! {
                if let p = p as? String, (p.contains(" ") || p.contains("\t") || p == "") {
                    str.append("\(key): \"\(p)\"")
                }
                else if let p = p as? [Any?] {
                    str.append("\(key): \(arrayToString(p, depth+1, tab))")
                }
                else if let p = p as? [String:Any?] {
                    str.append("\(key): \(dictToString(p, depth+1, tab))")
                }
                else if let p = p as? CVUToString {
                    str.append("\(key): \(p.toString(depth + 1, tab))")
                }
                else {
                    str.append("\(key): \(p)")
                }
            }
        }
        
        var children:String = ""
        var definitions:String = ""
        if let p = dict["children"] as? [UIElement], p.count > 0 {
            children = "\n\n\(tabs)\(arrayToString(p, depth, tab, false))"
        }
        if let p = dict["renderDefinitions"] as? [ParsedRendererDefinition], p.count > 0 {
            definitions = "\n\n\(tabs)\(arrayToString(p, depth, tab, false))"
        }
        
        return dec
            ? "{\n\(tabs)\(str.joined(separator: "\n\(tabs)"))\(children)\(definitions)\n\(tabsEnd)}"
            : "\(str.joined(separator: "\n\(tabsEnd)"))\(children)\(definitions)"
    }
}
