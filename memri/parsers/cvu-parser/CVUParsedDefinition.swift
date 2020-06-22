//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class CVUParsedDefinition : Equatable, CVUToString {
    
    let name:String?
    let selector:String?
    var domain:String?
    
    subscript(propName:String) -> Any? {
        return parsed[propName].flatMap { $0 }
    }
    
    public static func == (lhs: CVUParsedDefinition, rhs: CVUParsedDefinition) -> Bool {
        lhs.selector == rhs.selector && lhs.domain == rhs.domain
    }
    
//    var unparsed:String = ""
    var parsed:[String:Any?] = [:]
    
    func toCVUString(_ depth:Int, _ tab:String) -> String {
        let body = CVUSerializer.dictToString(parsed, depth+1, tab, extraNewLine: true) { lhp, rhp in
            let lv = self.parsed[lhp] as? [String:Any?]
            let rv = self.parsed[rhp] as? [String:Any?]
            
            let leftIsDict = lv != nil
            let rightIsDict = rv != nil
            let leftHasChildren = lv?["children"] != nil
            let rightHasChildren = rv?["children"] != nil
            
            return (leftHasChildren ? 1 : 0, leftIsDict ? 1 : 0, lhp.lowercased())
                < (rightHasChildren ? 1 : 0, rightIsDict ? 1 : 0, rhp.lowercased())
        }
        return "\(selector ?? "") \(body)"
    }
    
    public var description: String {
        toCVUString(0, "    ")
    }
    
    init(_ selector:String, name:String? = nil, domain:String? = "user", parsed:[String:Any?]? = nil) {
        self.selector = selector
        self.name = name
        self.domain = domain
        self.parsed = parsed ?? self.parsed
    }
}
public class CVUParsedDatasourceDefinition:CVUParsedDefinition {
}
public class CVUParsedStyleDefinition:CVUParsedDefinition {
}
public class CVUParsedLanguageDefinition:CVUParsedDefinition {
}
public class CVUParsedColorDefinition:CVUParsedDefinition {
}
public class CVUParsedRendererDefinition:CVUParsedDefinition {
}
public class CVUParsedViewDefinition:CVUParsedDefinition {
    let type:String?
    let query:ExprNode?
    
    init(_ selector:String, name:String? = nil, type:String? = nil, query:ExprNode? = nil) {
        self.type = type
        self.query = query
        
        super.init(selector, name:name)
    }
}
public class CVUParsedSessionDefinition:CVUParsedDefinition {
}
public class CVUParsedSessionsDefinition:CVUParsedDefinition {
}
