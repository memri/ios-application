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
    
    class func arrayToString(_ list:[Any?], _ depth:Int = 0, _ tab:String = "    ") -> String {
        let tabs = Array(0...depth).map{_ in tab}.joined()
        
        var str = [String]()
        var isMultiline = false
        for value in list {
            let strValue = value is CVUToString
                ? (value as? CVUToString)?.toString(depth + 1, tab) ?? "nil"
                : "\(value ?? "nil")"
            str.append(strValue)
            if !isMultiline { isMultiline = strValue.contains("\n") }
        }
        
        return isMultiline
            ? "[\n\(tabs)\(str.joined(separator:"\n\(tabs)"))\(tabs)\n]"
            : str.joined(separator: " ")
    }

    class func dictToString(_ dict:[String:Any?], _ depth:Int = 0, _ tab:String = "    ") -> String {
        let keys = dict.keys.sorted()
        let tabs = Array(0..<depth).map{_ in tab}.joined()
        let tabsEnd = Array(0..<depth - 1).map{_ in tab}.joined()
        
        var str = [String]()
        for key in keys {
            if dict[key] == nil {
                str.append("\(key): null")
            }
            else if let p = dict[key]! {
                if let p = p as? String, (p.contains(" ") || p.contains("\t")) {
                    str.append("\(key): \"\(p)\"")
                }
                else if let p = p as? [Any?] {
                    str.append("\(key): \"\(arrayToString(p, depth+1, tab))\"")
                }
                else if let p = p as? [String:Any?] {
                    str.append("\(key): \"\(dictToString(p, depth+1, tab))\"")
                }
                else if let p = p as? CVUToString {
                    str.append("\(key): \(p.toString(depth + 1, tab))")
                }
                else {
                    str.append("\(key): \(p)")
                }
            }
        }
        
        return "{\n\(tabs)\(str.joined(separator: "\n\(tabs)"))\n\(tabsEnd)}"
    }
}
