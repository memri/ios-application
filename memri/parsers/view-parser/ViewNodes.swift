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
    var domain:String?
    
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
        "\(selector ?? "") { \(serializeDict()) }"
    }
    
    init(_ selector:String, name:String? = nil, domain:String? = "user", parsed:[String:Any]? = nil) {
        self.selector = selector
        self.name = name
        self.domain = domain
        self.parsed = parsed ?? self.parsed
    }
}
public class ViewStyleDefinition:ViewSelector {
}
public class ViewLanguageDefinition:ViewSelector {
}
public class ViewColorDefinition:ViewSelector {
}
public class ViewRendererDefinition:ViewSelector {
}
public class ViewDefinition:ViewSelector {
    let type:String?
    let query:ExprNode?
    
    init(_ selector:String, name:String? = nil, type:String? = nil, query:ExprNode? = nil) {
        self.type = type
        self.query = query
        
        super.init(selector, name:name)
    }
}
public class ViewSessionDefinition:ViewSelector {
    override public var description: String {
        return ".\(name ?? "") { \(serializeDict()) }"
    }
}
public class ViewSessionsDefinition:ViewSelector {
    override public var description: String {
        return ".\(name ?? "") { \(serializeDict()) }"
    }
}
