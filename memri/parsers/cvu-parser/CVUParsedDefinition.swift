//
// CVUParsedDefinition.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

public class CVUParsedDefinition: Equatable, CVUToString {
    let name: String?
    let selector: String?
    var domain: String?
    var definitionType: String { "" }
    private var isCompiled: Bool = false

    subscript(propName: String) -> Any? {
        get {
            parsed?[propName].flatMap { $0 }
        }
        set(value) {
            if parsed == nil { parsed = [:] }
            parsed?[propName] = value
        }
    }

    public static func == (lhs: CVUParsedDefinition, rhs: CVUParsedDefinition) -> Bool {
        lhs.selector == rhs.selector && lhs.domain == rhs.domain
    }

    var parsed: [String: Any?]?

    public var description: String {
        toCVUString(0, "    ")
    }
    
    var selectorIsForList: Bool {
        selector?.hasSuffix("[]") ?? false
    }

    convenience init(_ parsed: [String: Any?]? = nil) {
        self.init(parsed: parsed)
    }

    required init(
        _ selector: String? = "",
        name: String? = nil,
        domain: String? = "user",
        parsed: [String: Any?]? = nil
    ) {
        self.selector = selector
        self.name = name
        self.domain = domain
        self.parsed = parsed
    }

    func toCVUString(_ depth: Int, _ tab: String) -> String {
        let body = CVUSerializer
            .dictToString(parsed ?? [:], depth + 1, tab, extraNewLine: true) { lhp, rhp in
                let lv = self.parsed?[lhp] as? [String: Any?]
                let rv = self.parsed?[rhp] as? [String: Any?]

                let leftIsDict = lv != nil
                let rightIsDict = rv != nil
                let leftHasChildren = lv?["children"] != nil
                let rightHasChildren = rv?["children"] != nil

                return (leftHasChildren ? 1 : 0, leftIsDict ? 1 : 0, lhp.lowercased())
                    < (rightHasChildren ? 1 : 0, rightIsDict ? 1 : 0, rhp.lowercased())
            }
        return "\(selector != "" ? "\(selector ?? "") " : "")\(body)"
    }

    enum CompileScope {
        case all
        case needed
        case none
    }

    func compile(_ viewArguments: ViewArguments?, scope: CompileScope = .needed) throws {
        guard !isCompiled, let parsed = parsed, scope != .none else { return }

        func recur(_ unknown: Any?) throws -> Any? {
            guard let notnil = unknown else { return unknown }

            if let expr = notnil as? Expression {
                return scope == .all
                    ? try expr.execute(viewArguments)
                    : try expr.compile(viewArguments)
            }
            else if var dict = notnil as? [String: Any?] {
                for (key, value) in dict {
                    dict[key] = try recur(value)
                }
                return dict
            }
            else if var list = notnil as? [Any?] {
                for i in 0 ..< list.count {
                    list[i] = try recur(list[i])
                }
                return list
            }
            else if var list = notnil as? [CVUParsedDefinition] {
                for i in 0 ..< list.count {
                    if let def = try recur(list[i]) as? CVUParsedDefinition {
                        list[i] = def
                    }
                }
                return list
            }
            else if let def = notnil as? CVUParsedDefinition {
                def.parsed = try recur(def.parsed) as? [String: Any?]
            }
            else if let el = notnil as? UIElement {
                if let dict = try recur(el.propertyResolver.properties) as? [String: Any?] {
                    el.propertyResolver.properties = dict
                }
            }

            return notnil
        }

        self.parsed = try recur(parsed) as? [String: Any?]
    }

    /// Cascades a parsed definition into another one by copy
    func mergeValuesWhenNotSet(_ other: CVUParsedDefinition) {
        guard let dict = other.parsed else { return }

        for (key, value) in dict {
            if key == "userState" || key == "viewArguments" {
                if parsed == nil { parsed = [:] }
                if let value = value as? CVUParsedObjectDefinition {
                    if let parsedObject = parsed?[key] as? CVUParsedObjectDefinition {
                        parsedObject.mergeValuesWhenNotSet(value)
                        parsed?[key] = parsedObject
                    }
                    else {
                        parsed?[key] = CVUParsedObjectDefinition(value.parsed)
                    }
                }
            }
            else if parsed?[key] == nil {
                if parsed == nil { parsed = [:] }
                parsed?[key] = value
            }
            else if let def = value as? CVUParsedDefinition {
                (parsed?[key] as? CVUParsedDefinition)?.mergeValuesWhenNotSet(def)
            }
            else if let list = value as? [CVUParsedDefinition] {
                if var localList = parsed?[key] as? [CVUParsedDefinition] {
                    for def in list {
                        var found = false
                        for localDef in localList {
                            if localDef.selector == def.selector {
                                localDef.mergeValuesWhenNotSet(def)
                                found = true
                                break
                            }
                        }
                        if !found {
                            localList.append(def)
                            parsed?[key] = localList
                        }
                    }
                }
            }
            else if let list = value as? [Any?] {
                if var localList = parsed?[key] as? [Any?] {
                    for item in list {
                        localList.append(item)
                    }
                    parsed?[key] = localList
                }
            }
        }
    }
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

    init(
        _ selector: String,
        name: String? = nil,
        type: String? = nil,
        query: ExprNode? = nil,
        domain: String? = "user",
        parsed: [String: Any?]? = nil
    ) {
        self.type = type
        self.query = query

        super.init(selector, name: name, parsed: parsed)
    }

    required init(
        _ selector: String? = "",
        name: String? = nil,
        domain: String? = "user",
        parsed: [String: Any?]? = nil
    ) {
        type = nil
        query = nil

        super.init(selector, name: name, domain: domain, parsed: parsed)
    }
}

public class CVUParsedSessionDefinition: CVUParsedDefinition {
    override var definitionType: String { "session" }
}

public class CVUParsedSessionsDefinition: CVUParsedDefinition {
    override var definitionType: String { "sessions" }
}
