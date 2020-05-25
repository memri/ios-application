import Foundation
import Combine
import SwiftUI
import RealmSwift

// Move to integrate with some of the sessions features so that Sessions can be nested
public class Views {
 
    let languages = Languages()
    
    private var realm:Realm
    var main:Main? = nil

    init(_ rlm:Realm) {
        realm = rlm
    }
    
    public func parse(_ def:CVUStoredDefinition, cache:Bool = true) -> [String:Any] {
        guard let definition = def.definition else {
            return [:]
        }
        
        do {
            if let data = definition.data(using: .utf8) {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                if cache {
                    // TODO ???
                }
                
                return json as! [String:Any]
            }
            else {
                 throw "Data is not UTF8"
            }
        }
        catch let error {
            // TODO refactor: Log this for later feedback to developers
            print(error)
            return [:]
        }
    }
 
    public func load(_ mn:Main, _ callback: () -> Void) throws {
        // Store main for use within createCascadingView)
        self.main = mn
        
        try setCurrentLanguage(main?.settings.get("user/language") ?? "English")
        
        // Done
        callback()
    }
    
    // TODO refactor when implementing settings UI call this when changing the language
    public func setCurrentLanguage(_ language:String) throws {
        self.languages.currentLanguage = language
        
        let definitions = try fetchDefinitions(type: "language")
            .compactMap{ try self.parseDefinition($0) }
        
        self.languages.load(definitions)
    }
    
 
    public func install() throws {
        // Load the default views from the package
        try loadStandardViewSetIntoDatabase()
    }
    
    // TODO Refactor: distinguish between views and sessions
    public func loadStandardViewSetIntoDatabase() throws {
        let code = getDefaultViewContents()
        
        do {
            let cvu = CVU(code, lookup: lookupValueOfVariables, execFunc: executeFunction)
            let parsedDefinitions = try cvu.parse() // TODO this could be optimized
            
            let validator = CVUValidator()
            if !validator.validate(parsedDefinitions) {
                validator.debug()
                if validator.warnings.count > 0 {
                    // TODO REPORT TO USER
                }
                if validator.errors.count > 0 {
                    // TODO REPORT TO USER
                    throw "Errors in default view set:    \n\(validator.errors.joined(separator: "\n    "))"
                }
            }
            
            // Loop over lookup table with named views
            for def in parsedDefinitions {
                var values = [
                    "selector": def.selector,
                    "domain": "defaults", // TODO Refactor, is it default or defaults
                    "definition": def.description
                ]
                
                if def is CVUParsedViewDefinition { values["type"] = "view" }
                else if def is CVUParsedRendererDefinition { values["type"] = "renderer" }
                else if def is CVUParsedStyleDefinition { values["type"] = "style" }
                else if def is CVUParsedColorDefinition { values["type"] = "color" }
                else if def is CVUParsedLanguageDefinition { values["type"] = "language" }
                else { throw "Exception: unknown definition" }
                
                // Store definition
                try realm.write { realm.create(CVUStoredDefinition.self, value: values) }
            }
        }
        catch let error {
            if let error = error as? CVUParseErrors {
                // TODO Fatal error handling
                throw "Parse Error: \(error.toString(code))"
            }
            else {
                throw error
            }
        }
    }

    public class func formatDate(_ date:Date?) -> String{
        let showAgoDate:Bool? = Settings.get("user/general/gui/showDateAgo")
        
        if let date = date {
            // Compare against 36 hours ago
            if showAgoDate == false || date.timeIntervalSince(Date(timeIntervalSinceNow: -129600)) < 0 {
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = Settings.get("user/formatting/date") ?? "yyyy/MM/dd HH:mm"
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                return dateFormatter.string(from: date)
            }
            else {
                return date.timestampString ?? ""
            }
        }
        else {
            return "never"
        }
    }
    
    public class func formatDateSinceCreated(_ date:Date?) -> String{
        if let date = date {
            return date.timeDelta ?? ""
        }
        else {
            return "never"
        }
    }
    
    func resolveEdge(_ edge:Edge) throws -> DataItem {
        // TODO REFACTOR: implement
        throw "not implemented"
    }
    
    func getGlobalReference (_ name:String, viewArguments:ViewArguments) -> Any? {
        // Fetch the value of the right property on the right object
        switch name {
        case "main": return main
        case "sessions": return main?.sessions
        case "currentSession": fallthrough
        case "session": return main?.currentSession
        case "cascadingView": return main?.cascadingView
        case "sessionView": return main?.currentSession.currentView
        case "view": return main?.cascadingView
        case "dataItem":
            // TODO Refactor into a variables/arguments object
            if let itemRef:DataItem = viewArguments["."] as? DataItem {
                return itemRef
            }
            else if let item = main?.cascadingView.resultSet.singletonItem {
                return item
            }
            else {
                print("Warning: No item found to get the property off")
            }
        default:
            if let value = viewArguments[name] { return value }
            print("Warning: Unknown object to get the property off: \(name)")
        }
        
        return nil
    }
    
    func lookupValueOfVariables (lookup: ExprLookupNode, viewArguments:ViewArguments) throws -> Any? {
        return try lookupValueOfVariables (
            lookup: lookup,
            viewArguments:viewArguments,
            isFunction:false
        )
    }
    
    func lookupValueOfVariables (lookup: ExprLookupNode,
                                 viewArguments:ViewArguments,
                                 isFunction:Bool = false) throws -> Any? {
        var value:Any? = nil
        var first = true
        
        // TODO support language lookup: {$name}
        // TOOD support viewArguments lookup: {name}
        
        var i = 0
        for node in lookup.sequence {
            i += 1
            
            if isFunction && i == lookup.sequence.count {
                value = (value as? DataItem)?.functions
                if value == nil {
                    // TODO parse [blah]
                    let message = "Exception: Invalid function call. Could not find"
                    throw "\(message) \((node as? ExprVariableNode)?.name ?? "")"
                }
            }
            
            if let node = node as? ExprVariableNode {
                if first {
                    let name = node.name == "__DEFAULT__" ? "dataItem" : node.name
                    value = getGlobalReference(name, viewArguments:viewArguments)
                    first = false
                }
                else {
                    if let value = value as? DataItem {
                        if value.objectSchema[node.name] == nil {
                            // TODO Warn
                            return nil
                        }
                    }
                    else if let v = value as? RealmSwift.List<Edge> {
                        switch node.name {
                        case "count": value = v.count
                        case "first": value = v.first
                        case "last": value = v.last
//                        case "sum": value = v.sum
                        case "min": value = v.min
                        case "max": value = v.max
                        default:
                            // TODO Warn
                            break
                        }
                    }
                    else {
                        if let v = value as? CascadingView {
                            value = v[node.name]
                        }
                        else if let v = value as? Object {
                            if v.objectSchema[node.name] == nil {
                                // TODO error handling
                            }
                            else {
                                value = v[node.name] // How to handle errors?
                            }
                        }
                    }
                }
            }
            // .addresses[primary = true] || [0]
            else if let _ = node as? ExprLookupNode {
                // TODO REFACTOR: parse and query
            }
            
            if let edge = value as? Edge {
                value = try resolveEdge(edge)
            }
        }
        
        // Format a date
        if let date = value as? Date {
            value = Views.formatDate(date)
        }
        
        // TODO check for string mode
//        // Get the image uri from a file
//        else if let file = value as? File {
//            if T.self == String.self {
//                value = file.uri
//            }
//        }
        
//        if let lastPart = lastPart, lastObject?.objectSchema[lastPart]?.isArray ?? false,
//           let className = lastObject?.objectSchema[lastPart]?.objectClassName {
//
//            // Convert Realm List into Array
//            value = DataItemFamily(rawValue: className.lowercased())!.getCollection(value as Any)
//        }
        
        return value
    }
    
    func executeFunction(lookup: ExprLookupNode, args:[Any], viewArguments:ViewArguments) throws -> Any {
        let f = try lookupValueOfVariables( lookup: lookup, viewArguments: viewArguments, isFunction: true )
        if let f = f as? ([Any]) -> Any {
            return f(args) as Any
        }
        
        let x:String? = nil
        return x as Any
    }
    
    public func fetchDefinitions(_ selector:String = "", type:String? = nil,
                                   domain:String? = nil) -> [CVUStoredDefinition] {
        
        let filter = (type != nil ? "type = '\(type ?? "")'" : "selector = '\(selector)'")
            + (domain != nil  ? "and domain = '\(domain!)'" : "")
        
        return main!.realm.objects(CVUStoredDefinition.self)
            .filter(filter)
            .map({ (def) -> CVUStoredDefinition in def }) // Convert to normal Array
    }
    
    func parseDefinition(_ viewDef:CVUStoredDefinition?) throws -> CVUParsedDefinition? {
        guard let viewDef = viewDef else {
            throw "Exception: Missing view definition"
        }
        
        let cached = try InMemoryObjectCache.get("uid: \(viewDef.uid)")
        if let cached = cached as? CVU {
            return try cached.parse().first
        }
        else if let definition = viewDef.definition {
            let viewDefParser = CVU(definition,
                lookup: lookupValueOfVariables,
                execFunc: executeFunction
            )
            try InMemoryObjectCache.set("uid: \(viewDef.uid)", viewDefParser)
            return try viewDefParser.parse().first
        }
        else {
            throw "Exception: Missing view definition"
        }
    }
    
    public func createCascadingView(_ sessionView:SessionView? = nil) throws -> CascadingView {
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        let viewFromSession = sessionView == nil
            ? main.sessions.currentSession.currentView
            : sessionView!
        
        let cascadingView = try CascadingView.fromSessionView(viewFromSession, in: main)
        
        // TODO REFACTOR: move these to a better place (main??)
        
        // turn off editMode when navigating
        if main.sessions.currentSession.editMode == true {
            realmWriteIfAvailable(realm) {
                main.sessions.currentSession.editMode = false
            }
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if main.sessions.currentSession.showFilterPanel {
            if cascadingView.filterButtons.filter({ $0.name == .toggleFilterPanel }).count == 0 {
                realmWriteIfAvailable(realm) {
                    main.sessions.currentSession.showFilterPanel = false
                }
            }
        }
        
        return cascadingView
    }
    
    // TODO: Refactor: Consider caching cascadingView based on the type of the item
    public func renderItemCell(with dataItem:DataItem, search rendererNames: [String] = [],
                               inView viewOverride: String? = nil,
                               use viewArguments: ViewArguments = ViewArguments()) -> UIElementView {
        do {
            guard let main = self.main else {
                throw "Exception: Main is not defined in views"
            }
            
            func searchForRenderer(in viewDefinition:CVUStoredDefinition) throws -> Bool {
                let parsed = try main.views.parseDefinition(viewDefinition)
                for def in parsed?["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [] {
                    for name in rendererNames {
                        
                        // TODO: Should this first search for the first renderer everywhere
                        //       before trying the second renderer?
                        if let renderDef = def[name] as? CVUParsedRendererDefinition, renderDef["children"] != nil {
                            cascadeStack.append(renderDef)
                            return true
                        }
                    }
                }
                return false
            }
            
            var cascadeStack:[CVUParsedDefinition] = []

            // If there is a view override, find it, otherwise
            if let viewOverride = viewOverride {
                if let viewDefinition = main.views.fetchDefinitions("\(viewOverride)").first {
                    if viewDefinition.type == "renderer" {
                        if let parsed = try main.views.parseDefinition(viewDefinition) {
                            if parsed["children"] != nil { cascadeStack.append(parsed) }
                            else {
                                throw "Exception: Specified view does not contain any UI elements: \(viewOverride)"
                            }
                        }
                        else {
                            throw "Exception: View definition is missing: \(viewOverride)"
                        }
                    }
                    else if viewDefinition.type == "view" {
                        _ = try searchForRenderer(in: viewDefinition)
                    }
                    else {
                        throw "Exception: incompatible view type of \(viewDefinition.type ?? ""), expected renderer or view"
                    }
                }
                else {
                    throw "Exception: Could not find view to override: \(viewOverride)"
                }
            }
            else {
                // Find views based on datatype
                outerLoop: for needle in ["\(dataItem.genericType)[]", "*[]"] {
                    for key in ["user", "defaults"] {
                        
                        if let viewDefinition = main.views.fetchDefinitions(needle, domain:key).first {
                            if try searchForRenderer(in: viewDefinition) { break outerLoop }
                        }
                    }
                }
            }
            
            // If we cant find a way to render using one of the views,
            // then find a renderer for one of the renderers
            if cascadeStack.count == 0 {
                for name in rendererNames {
                    for key in ["user", "defaults"] {
                        if let viewDefinition = main.views.fetchDefinitions("[renderer = \(name)]", domain:key).first {
                            if let parsed = try main.views.parseDefinition(viewDefinition) {
                                if parsed["children"] != nil { cascadeStack.append(parsed) }
                            }
                        }
                    }
                }
            }
                            
            if cascadeStack.count == 0 {
                throw "Exception: Unable to find a way to render this element: \(dataItem.genericType)"
            }
            
            // Create a new view
            let cascadingRenderConfig = CascadingRenderConfig(cascadeStack, viewArguments)

            // Return the rendered UIElements in a UIElementView
            return cascadingRenderConfig.render(item: dataItem)
        }
        catch {
            // TODO Refactor: Log error to the user
            
            return UIElementView(UIElement("Text", properties: ["text": "Could not render this view"]), dataItem)
        }
    }
}

func getDefaultViewContents() -> String{
    let urls = Bundle.main.urls(forResourcesWithExtension: "cvu", subdirectory: ".")
    return urls == nil ? "":
        urls!.compactMap{try? String(contentsOf: $0)}.joined(separator: "\n")
}
