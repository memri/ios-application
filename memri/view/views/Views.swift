import Foundation
import Combine
import SwiftUI
import RealmSwift

// Move to integrate with some of the sessions features so that Sessions can be nested
public class Views {
    /**
     *
     */
    var compiledViews: [String:CompiledView] = [:]
    /**
     *
     */
    var defaultViews: [String:[String:DynamicView]] = [:]
    
    private var realm:Realm
    var main:Main? = nil

    init(_ rlm:Realm) {
        realm = rlm
    }
    
    /**
     *
     */
    public func load(_ mn:Main, _ callback: () -> Void) throws {
        // Store main for use within computeView()
        self.main = mn
        
        // Load the default views from the package
        let data = try! jsonDataFromFile("views_from_server")
        let (parsed, named) = try! CompiledView.parseNamedViewDict(data)
        
        // Set the parsed views to the defaultViews property for later use in computeView
        self.defaultViews = parsed
        
        // TODO Refactor: I think we want to stop getting named views from the defaults and create
        //                references to them instead
        
        // Add the named views to the compiled views
        for (name, view) in named {
            compiledViews[name] = compileView(view)
        }
        
        // Done
        callback()
    }
    
    /**
     *
     */
    public func install() {
        
        // Load named views from the package
        let namedViews = try! CompiledView.parseNamedViewList(jsonDataFromFile("named_views"))
        
        // Store named views
        if let namedViews = namedViews {
            try! realm.write {
                for dynamicView in namedViews {
                    realm.add(dynamicView, update: .modified)
                }
            }
        }
    }
    
    /**
     *
     */
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
    
    /**
     *
     */
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
    
    /**
     *
     */
    public func getSessionView (_ viewName:String,
                                _ variables:[String:Any]? = nil) -> SessionView? {
        if let compiledView = getCompiledView(viewName) {
            return try! compiledView.generateView(variables)
        }
        
        return nil
    }
    /**
     *
     */
    public func getSessionView (_ view:DynamicView?,
                                _ variables:[String:Any]? = nil) -> SessionView? {
        if let dynamicView = view {
            return try! compileView(dynamicView).generateView(variables)
        }
        
        return nil
    }
    /**
     *
     */
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
    
    /**
     *
     */
    func compileView(_ dynamicView:DynamicView) -> CompiledView {
        // If we have a cached version, let's return that
        if let compiledView = compiledViews[dynamicView.name] {
            return compiledView
        }
        
        // Create a compiled view based on the dynamic view
        let compiledView = try! CompiledView(dynamicView, main!)
        
        // Add the dynamic view for easy reference
        compiledViews[dynamicView.name] = compiledView
        
        return compiledView
    }
    
    /*
    "{type:Note}"
    "{renderer:list}"
    "{[type:Note]}"
    */
    public func computeView(_ argView:SessionView? = nil) throws -> ComputedView {
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        let viewFromSession = argView == nil
            ? main.sessions.currentSession.currentView
            : argView!
        
        // Create a new view
        let computedView = ComputedView(main.cache)
        
        let variables = viewFromSession.variables
        var isList = true
        var type = ""
        
        // Fetch query from the view from session
        if let queryOptions = viewFromSession.queryOptions {
            
            // Look up the associated result set
            let resultSet = main.cache.getResultSet(queryOptions)
            
            // Determine whether this is a list or a single item resultset
            isList = resultSet.isList
            
            // Fetch the type of the results
            if let determinedType = resultSet.determinedType {
                type = determinedType
            }
            else {
                throw "Exception: ResultSet does not know the type of its data"
            }
        }
        else {
            throw "Exception: Cannot compute a view without a query to fetch data"
        }

        // Helper lists
        var renderViews:[SessionView] = []
        var datatypeViews:[SessionView] = []
        var rendererNames:[String] = []
        var cascadeOrders:[String:[RealmSwift.List<String>]] = ["defaults":[List()], "user":[]]
        let searchOrder = ["defaults", "user"]
        
        // Default to the rendererName we know from the view from the session
        var rendererName = viewFromSession.rendererName ?? ""
        
        cascadeOrders["defaults"]![0].append(objectsIn: ["renderer", "datatype"])
        
        // If we know the type of data we are rendering use it to determine the view
        var needles:[String]
        if type != "mixed" {
            // Determine query
            needles = [
                isList ? "{[type:*]}" : "{type:*}",
                isList ? "{[type:\(type)]}" : "{type:\(type)}", // TODO if this is not found it should get the default template
            ]
        }
        else {
            needles = [isList ? "{[type:*]}" : "{type:*}"]
        }
        
        // Find views based on datatype
        for needle in needles {
            for key in searchOrder {
                if let datatypeView = getSessionView(self.defaultViews[key]![needle], variables) {
                    if datatypeView.name != nil && datatypeView.name == viewFromSession.name {
                        continue
                    }
                    
                    datatypeViews.append(datatypeView)
                    
                    if let S = datatypeView.rendererName { rendererNames.append(S) }
                    if datatypeView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(datatypeView.cascadeOrder)
                    }
                }
            }
        }
                
        if rendererNames.count > 0 {
            rendererName = rendererNames[rendererNames.count - 1]
        }
        
        // Find renderer views
        if rendererName != "" {
            // Determine query
            let needle = "{renderer:\(rendererName)}"
            
            for key in searchOrder {
                if let rendererView = getSessionView(self.defaultViews[key]![needle], variables) {
                    renderViews.append(rendererView)
                    
                    if rendererView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(rendererView.cascadeOrder)
                    }
                }
            }
        }
        else {
            throw "Exception: Could not find which renderer to use. rendererName not set in this view"
        }

        // Choose cascade order
        let preferredCascadeOrder = (cascadeOrders["user"]!.count > 0
            ? cascadeOrders["user"]
            : cascadeOrders["defaults"]) ?? []
        
        var cascadeOrder = preferredCascadeOrder[preferredCascadeOrder.count - 1]
        if (cascadeOrder.count == 0) {
            cascadeOrder = List()
            cascadeOrder.append(objectsIn: ["renderer", "datatype"])
        }
        
        if (Set(preferredCascadeOrder).count > 1) {
            print("Warn: Found multiple cascadeOrders when cascading view. Choosing \(cascadeOrder)")
        }
        
        // Cascade the different views
        for key in cascadeOrder {
            var views:[SessionView]
            
            if key == "renderer" { views = renderViews }
            else if key == "datatype" { views = datatypeViews }
            else {
                throw ("Exception: Unknown cascadeOrder type specified: \(key)")
            }
            
            for view in views {
                computedView.merge(view)
            }
        }
        
        // Cascade the view from the session
        // Loads user interactions, e.g. selections, scrollstate, changes of renderer, etc.
        computedView.finalMerge(viewFromSession)
        
        do {
            try computedView.validate()
        }
        catch {
            throw "Exception: Invalid Computed View: \(error)"
        }
        
        // turn off editMode when navigating
        if main.sessions.currentSession.editMode == true {
            try! realm.write {
                main.sessions.currentSession.editMode = false
            }
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if main.sessions.currentSession.showFilterPanel {
            if computedView.filterButtons.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                try! realm.write {
                    main.sessions.currentSession.showFilterPanel = false
                }
            }
        }
        
        return computedView
    }
    
    // TODO: Refactor: Consider caching computedView based on the type of the item
    public func renderItemCell(_ item:DataItem, _ rendererNames: [String],
                               _ viewOverride: String? = nil,
                               _ variables: [String: () -> Any]? = nil) throws -> GUIElementInstance {
        
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        // TODO: If there is a view override, find it, otherwise
        if viewOverride != nil { throw "View Override Not Implemented" }

        // Create a new view
        let computedView = ComputedView(main.cache)

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
        
        return GUIElementInstance(GUIElementDescription(), item, variables ?? [:])
    }
}

public struct DataItemReference {
    let type: DataItemFamily
    let uid: String
    
    init(type:DataItemFamily, uid:String) {
        self.type = type
        self.uid = uid
    }
    
    init(dataItem:DataItem) {
        type = DataItemFamily(rawValue: dataItem.genericType)! // TODO refactor: error handling
        uid = dataItem.uid
    }
}
