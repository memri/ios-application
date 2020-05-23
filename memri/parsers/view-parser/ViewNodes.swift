//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class ParsedDefinition : CVUToString {
    let name:String?
    let selector:String?
    var domain:String?
    
    subscript(propName:String) -> Any? {
        return parsed[propName]
    }
    
//    var unparsed:String = ""
    var parsed:[String:Any] = [:]
    
    func toString(_ depth:Int, _ tab:String) -> String {
        let tabs = Array(0...depth).map{_ in ""}.joined(separator: tab)
        return "\(tabs)\(selector ?? "") \(CVUSerializer.dictToString(parsed, depth+1, tab))\n"
    }
    
    public var description: String {
        toString(0, "    ")
    }
    
    init(_ selector:String, name:String? = nil, domain:String? = "user", parsed:[String:Any]? = nil) {
        self.selector = selector
        self.name = name
        self.domain = domain
        self.parsed = parsed ?? self.parsed
    }
}
public class ParsedStyleDefinition:ParsedDefinition {
}
public class ParsedLanguageDefinition:ParsedDefinition {
}
public class ParsedColorDefinition:ParsedDefinition {
}
public class ParsedRendererDefinition:ParsedDefinition {
}
public class ParsedViewDefinition:ParsedDefinition {
    let type:String?
    let query:ExprNode?
    
    init(_ selector:String, name:String? = nil, type:String? = nil, query:ExprNode? = nil) {
        self.type = type
        self.query = query
        
        super.init(selector, name:name)
    }
}
public class ParsedSessionDefinition:ParsedDefinition {
}
public class ParsedSessionsDefinition:ParsedDefinition {
}
