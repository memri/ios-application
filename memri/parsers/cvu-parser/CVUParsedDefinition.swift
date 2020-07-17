//
//  Nodes.swift
//
//  Based on work by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class CVUParsedDefinition: Equatable, CVUToString {
	let name: String?
	let selector: String?
	var domain: String?
    var definitionType: String { "" }

	subscript(propName: String) -> Any? {
        get {
            parsed?[propName].flatMap { $0 }
        }
        set (value) {
            if parsed == nil { parsed = [:] }
            parsed?[propName] = value
        }
	}

	public static func == (lhs: CVUParsedDefinition, rhs: CVUParsedDefinition) -> Bool {
		lhs.selector == rhs.selector && lhs.domain == rhs.domain
	}

	var parsed: [String: Any?]?

	func toCVUString(_ depth: Int, _ tab: String) -> String {
        let body = CVUSerializer.dictToString(parsed ?? [:], depth + 1, tab, extraNewLine: true) { lhp, rhp in
			let lv = self.parsed?[lhp] as? [String: Any?]
			let rv = self.parsed?[rhp] as? [String: Any?]

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
    
    convenience init(_ parsed: [String:Any?]? = nil) {
        self.init(parsed: parsed)
    }

	required init (_ selector: String? = "", name: String? = nil, domain: String? = "user", parsed: [String: Any?]? = nil) {
		self.selector = selector
		self.name = name
		self.domain = domain
		self.parsed = parsed
	}
    
//    public func merge(_ state: UserState) throws {
//        let dict = asDict().merging(state.asDict(), uniquingKeysWith: { _, new in new })
//        try storeInCache(dict as [String: Any?])
//        persist()
//    }
//
//    func toCVUString(_ depth: Int, _ tab: String) -> String {
//        CVUSerializer.dictToString(asDict(), depth, tab)
//    }
//
//    public class func clone(_ viewArguments: ViewArguments? = nil,
//                            _ values: [String: Any?]? = nil,
//                            managed: Bool = true,
//                            item: Item? = nil) throws -> UserState {
//        var dict = viewArguments?.asDict() ?? [:]
//        if let values = values {
//            dict.merge(values, uniquingKeysWith: { _, r in r })
//        }
//
//        if managed { return try UserState.fromDict(dict, item: item) }
//        else { return try UserState(dict) }
//    }
//
//    public class func fromDict(_ dict: [String: Any?], item: Item? = nil) throws -> UserState {
//        let userState = try Cache.createItem(UserState.self, values: [:])
//
//        // Resolve expressions
//        var dct = dict
//        for (key, value) in dct {
//            if let expr = value as? Expression {
//                dct[key] = try expr.execute(ViewArguments([".": item]))
//            }
//        }
//
//        try userState.storeInCache(dct)
//        userState.persist()
//        return userState
//    }
}

public class CVUParsedObjectDefinition: CVUParsedDefinition {
    override var definitionType: String { "object" }
}

public class CVUParsedDatasourceDefinition: CVUParsedDefinition {
    override var definitionType: String { "datasource" }
}

public class CVUParsedStyleDefinition: CVUParsedDefinition {
    override var definitionType: String { "style" }
}

public class CVUParsedLanguageDefinition: CVUParsedDefinition {
    override var definitionType: String { "language" }
}

public class CVUParsedColorDefinition: CVUParsedDefinition {
    override var definitionType: String { "color" }
}

public class CVUParsedRendererDefinition: CVUParsedDefinition {
    override var definitionType: String { "renderer" }
}

public class CVUParsedViewDefinition: CVUParsedDefinition {
	let type: String?
	let query: ExprNode?
    override var definitionType: String { "view" }

	init(_ selector: String, name: String? = nil, type: String? = nil, query: ExprNode? = nil,
         domain: String? = "user", parsed: [String: Any?]? = nil) {
        
		self.type = type
		self.query = query

        super.init(selector, name: name, parsed: parsed)
	}
    
    required init(_ selector: String? = "", name: String? = nil, domain: String? = "user", parsed: [String : Any?]? = nil) {
        self.type = nil
        self.query = nil
        
        super.init(selector, name: name, domain: domain, parsed: parsed)
    }
}

public class CVUParsedSessionDefinition: CVUParsedDefinition {
    override var definitionType: String { "session" }
}

public class CVUParsedSessionsDefinition: CVUParsedDefinition {
    override var definitionType: String { "sessions" }
}
