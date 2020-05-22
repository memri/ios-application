//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public protocol ViewNode: CustomStringConvertible {
}

/*
    Always a literal in the dict except:
    - Expression
    - ViewRendererDefinition (in .renderDefinitions)
 */

public class ViewSelector:ViewNode {
    let name:String?
    let selector:String?
    let domain:String?
    
    subscript(propName:String) -> Any? {
        return parsed[propName]
    }
    
//    var unparsed:String = ""
    var parsed:[String:Any] = [:]
    
    func serializeDict() -> String {
        let keys = parsed.keys.sorted()
        
        var str = [String]()
        for key in keys {
            if let p = parsed[key] as? String {
                str.append("\(key): \"\(p)\"")
            }
            else {
                str.append("\(key): \(parsed[key] ?? "")")
            }
        }
        
        return "[\(str.joined(separator: ";"))]" // TODO remove [ and ] 
    }
    
    public var description: String {
        return "Selector(\(name ?? ""), context:\(serializeDict())"
    }
    
    init(_ selector:String, name:String? = nil, domain:String? = "user", parsed:[String:Any]? = nil) {
        self.selector = selector
        self.name = name
        self.domain = domain
        self.parsed = parsed ?? self.parsed
    }
}
public class ViewStyleDefinition:ViewSelector {
    override public var description: String {
        return "[style = \"\(name ?? "")\"] { \(serializeDict()) }"
    }
}
public class ViewLanguageDefinition:ViewSelector {
    override public var description: String {
        return "[language = \"\(name ?? "")\"]  \(serializeDict()) }"
    }
}
public class ViewColorDefinition:ViewSelector {
    override public var description: String {
        return "[color = \"\(name ?? "")\"] { \(serializeDict()) }"
    }
}
public class ViewRendererDefinition:ViewSelector {
    override public var description: String {
        return "[renderer = \"\(name ?? "")\"] { \(serializeDict()) }"
    }
}
public class ViewDefinition:ViewSelector {
    let type:String?
    let query:ExprNode?
    
    override public var description: String {
        if name != nil {
            return ".\(name ?? "") { \(serializeDict()) }"
        }
        else if type != nil {
            //return "\(type ?? "")\(query == nil ? "" : "[\(query ?? "")]") {\n\(serializeDict())\n}"
            return "\(type ?? "") { \(serializeDict()) }"
        }
        else {
            return ""
        }
    }
    
    init(_ selector:String, name:String? = nil, type:String? = nil, query:ExprNode? = nil) {
        self.type = type
        self.query = query
        
        super.init(selector, name:name)
    }
}
// TODO Refactor: implement
//public class ViewSessionDefinition:ViewSelector {
//    override public var description: String {
//        return ".\(name ?? "") { \(serializeDict()) }"
//    }
//}
//public class ViewSessionsDefinition:ViewSelector {
//    override public var description: String {
//        return ".\(name ?? "") { \(serializeDict()) }"
//    }
//}
