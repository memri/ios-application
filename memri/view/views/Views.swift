import Foundation
import Combine
import SwiftUI
import RealmSwift

// Move to integrate with some of the sessions features so that Sessions can be nested
public class Views {
 
    let language = Languages()
    
    private var realm:Realm
    var main:Main? = nil

    init(_ rlm:Realm) {
        realm = rlm
    }
    
    public func parse(_ def:BaseDefinition, cache:Bool = true) -> [String:Any] {
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
        
        setCurrentLanguage(main?.settings.get("user/language") ?? "English")
        
        // Done
        callback()
    }
    
    // TODO refactor when implementing settings UI call this when changing the language
    public func setCurrentLanguage(_ language:String) {
        self.language.currentLanguage = language
        
        let definitions = Array(realm.objects(LanguageDefinition.self)
            .filter("selector = '[language = \(language)'")
            .map{ self.parse($0, cache:false) })
        
        self.language.load(definitions)
    }
    
 
    public func install() throws {
        
        // Load the default views from the package
        try loadStandardViewSetIntoDatabase()
        
        // Load named views from the package
        if let namedViews = try CompiledView.parseNamedViewList(jsonDataFromFile("named_views")) {
            try realm.write {
                for viewDef in namedViews {
                    realm.create(SessionViewDefinition.self,
                        value: ["selector": viewDef.name, "definition": viewDef.definition],
                        update: .modified)
                }
            }
        }
        
        // Load named views from the package
        if let namedSessions = try CompiledView.parseNamedViewList(jsonDataFromFile("named_sessions")) {
            try realm.write {
                for sessionDef in namedSessions {
                    realm.create(SessionDefinition.self,
                        value: ["selector": sessionDef.name, "views": sessionDef.views.map {
                            SessionViewDefinition(value: ["definition": $0])
                        }],
                        update: .modified)
                }
            }
        }
    }
    
    
    public func loadStandardViewSetIntoDatabase() throws {
        do {
            let data = try jsonDataFromFile("views_from_server")
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let parsedObject = json as? [String: Any] else {
                throw "Exception: Invalid JSON while reading named view list"
            }
            
            // Loop over lookup table with named views
            for (selector, object) in parsedObject {
                let definition = serialize(AnyCodable(object))
                
                var def:BaseDefinition
                if selector.test(#"\[\]$"#) { // superfluous
                    def = SessionViewDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                else if selector.test(#"^\[renderer = .*\]$"#) {
                    def = RenderDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                else if selector.test(#"^\[style = .*\]$"#) {
                    def = StyleDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                else if selector.test(#"^\[color = .*\]$"#) {
                    def = ColorDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                else if selector.test(#"^\[language = .*\]$"#) {
                    def = LanguageDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                else if let matches = selector.match(#"^\"(.*)\"$"#) {
                    def = SessionViewDefinition(value:
                        ["selector": matches[1], "definition": definition])
                }
                else {
                    def = SessionViewDefinition(value:
                        ["selector": selector, "definition": definition])
                }
                
                // Store definition
                try realm.write { realm.add(def) }
            }
        }
        catch {
            // TODO Fatal error handling
        }
    }
    
 
    public func getDynamicView (_ viewName:String) -> DynamicView? {
        var dynamicView:DynamicView?
        
        // If a declaration is passed instead of a name create new DynamicView
        if viewName.prefix(1) == "{" {
            dynamicView = DynamicView(viewName)
        }
        // Otherwise load from the database the dynamic view with that name
        else {
            dynamicView = realm.objects(DynamicView.self).filter("name = '\(viewName)'").first
        }
        
        return dynamicView
    }
    
 
    public func getCompiledView (_ viewName:String) -> CompiledView? {
        // Find an already compiled view
        if let compiledView = compiledViews[viewName] {
            return compiledView
        }
        
        // Otherwise generate it from a dynamic view
        if let dynamicView = getDynamicView(viewName) {
            return compileView(dynamicView)
        }
        
        return nil
    }
    
 
    public func getSessionView (_ viewName:String,
                                _ variables:[String:Any]? = nil) -> SessionView? {
        if let compiledView = getCompiledView(viewName) {
            return try! compiledView.generateView(variables)
        }
        
        return nil
    }
 
    public func getSessionView (_ view:DynamicView?,
                                _ variables:[String:Any]? = nil) -> SessionView? {
        if let dynamicView = view {
            return try! compileView(dynamicView).generateView(variables)
        }
        
        return nil
    }
 
    // TODO: Refactor: THis function needs to die
    public func getSessionOrView(_ viewName:String, wrapView:Bool=false,
                                 _ variables:[String:Any]? = nil) -> (Session?, SessionView?) {
        if let compiledView = getCompiledView(viewName) {
            
            // Parse so we now if it includes a session
            try! compiledView.parse()
            
            if compiledView.hasSession {
                return (try! compiledView.generateSession(variables), nil)
            }
            else {
                let view = try! compiledView.generateView(variables)
                return (wrapView ? Session(value: ["views": [view]]) : nil, view)
            }
        }
        
        return (nil, nil)
    }
    
//    LookupNode([VariableNode(__DEFAULT__), VariableNode(bar)])
//    LookupNode([VariableNode(bar), VariableNode(foo)])
//    LookupNode([VariableNode(bar), LookupNode([BinaryOpNode(ConditionEquals, lhs: LookupNode([VariableNode(foo)]), rhs: NumberNode(10.0))])])
    
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
    
    func resolveEdge(_ edge:Edge) -> DataItem {
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
        case "computedView": return main?.computedView
        case "sessionView": return main?.currentSession.currentView
        case "view": return main?.computedView
        case "dataItem":
            // TODO Refactor into a variables/arguments object
            if let itemRef:DataItem = viewArguments["."] as? DataItem {
                return itemRef
            }
            else if let item = main?.computedView.resultSet.singletonItem {
                return item
            }
            else {
                print("Warning: No item found to get the property off")
            }
        default:
            print("Warning: Unknown object to get the property off: \(name)")
        }
        
        return nil
    }
    
    // TODO:REFACTOR:Maybe add the viewArguments here to support property access?
    func lookupValueOfVariables (lookup: ExprLookupNode, viewArguments:ViewArguments) -> Any? {
        return lookupValueOfVariables (lookup: lookup, viewArguments:viewArguments, isFunction:false)
    }
    
    func lookupValueOfVariables (lookup: ExprLookupNode, viewArguments:ViewArguments, isFunction:Bool = false) -> Any? {
        var value:Any? = nil
        var first = true
        
        for node in lookup.sequence {
            if isFunction && node == lookup.sequence.last {
                value = (value as? DataItem).functions
            }
            
            if let node = node as? ExprVariableNode {
                if first {
                    value = getGlobalReference(node.name == "__DEFAULT__" ? "dataItem" : node.name, viewArguments:viewArguments)
                    first = false
                }
                else {
                    if let value = value as? DataItem {
                        if !value.objectSchema[node.name] {
                            // TODO Warn
                            return nil
                        }
                    }
                    else if let value = value as? RealmSwift.ListBase {
                        switch node.name {
                        case "count": value = value.count
                        case "first": value = value.first
                        case "last": value = value.last
                        case "sum": value = value.sum
                        case "min": value = value.min
                        case "max": value = value.max
                        }
                    }
                    
                    value = value[prop] // How to handle errors?
                }
            }
            // .addresses[primary = true] || [0]
            else if let node = node as? ExprLookupNode {
                // TODO REFACTOR: parse and query
            }
            
            if let edge = value as? Edge {
                value = resolveEdge(edge)
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
    
    func executeFunction (lookup: ViewLookupNode, args:[Any], viewArguments:ViewArguments) -> Any? {
        if let f = lookupValueOfVariables(lookup: lookup, viewArguments:viewArguments, isFunction:true) {
            return f(args)
        }
    }
    
    func getParsedDefinition(_ viewDef:SessionViewDefinition) throws -> ViewParseContext {
        let viewDef = ViewDefinitionParser(self.definition,
                                           lookup: lookupValueOfVariables,
                                           execFunc: executeFunction)
        return try viewDef.parse()
    }
    
    public func createCascadingView(_ sessionView:SessionView? = nil) throws -> CascadingView {
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        let viewFromSession = sessionView == nil
            ? main.sessions.currentSession.currentView
            : sessionView!
        
        let cascadingView = CascadingView.fromSessionView(viewFromSession, main.cache)
        
        // TODO REFACTOR: move these to a better place (main??)
        
        // turn off editMode when navigating
        if main.sessions.currentSession.editMode == true {
            try! realm.write {
                main.sessions.currentSession.editMode = false
            }
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if main.sessions.currentSession.showFilterPanel {
            if cascadingView.filterButtons.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                try! realm.write {
                    main.sessions.currentSession.showFilterPanel = false
                }
            }
        }
        
        return cascadingView
    }
    
    // TODO: Refactor: Consider caching computedView based on the type of the item
    public func renderItemCell(_ item:DataItem, _ rendererNames: [String],
                               _ viewOverride: String? = nil,
                               _ variables: [String: () -> Any]? = nil) throws -> UIElementView {
        
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        // TODO: If there is a view override, find it, otherwise
        if viewOverride != nil { throw "View Override Not Implemented" }

        // Create a new view
        let computedView = CascadingView(main.cache)

        let searchOrder = ["defaults", "user"]
        let needles = ["{[type:*]}", "{[type:\(item.genericType)]}"]

        // Find views based on datatype
        for needle in needles {
            for key in searchOrder {
                if let view = getSessionView(self.defaultViews[key]![needle]) {
                    computedView.merge(view) // TODO Refactor: can this be optimized to only pick the top-most renderDescription?
                }
            }
        }

        // Find the first cascaded renderer for the type and render the item
        for name in rendererNames {
            if let _ = computedView.renderConfigs.objectSchema[name],
               let renderConfig = computedView.renderConfigs[name] as? RenderConfig {
                return renderConfig.render(item: item, part: name, variables: variables ?? [:])
                                                    // Refactor: look at how variables is passed
            }
            else if let _ = computedView.renderConfigs.virtual?.renderDescription?[name] {
                return computedView.renderConfigs.virtual!
                    .render(item: item, part: name, variables: variables ?? [:])
            }
        }
        
        return UIElementView(UIElement(), item, variables ?? [:])
    }
}
