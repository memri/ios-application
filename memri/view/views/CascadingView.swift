//
//  ComputedView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class Cascadable {
    var cascadeStack = [ViewSelector]()
    var localCache = [String:Any]()
    
    // TODO execute x when Expression
    func cascadeProperty<T>(_ name:String, _ defaultValue:T) -> T {
        if let x = localCache[name] as? T { return x }
        
        for def in cascadeStack {
            if let x = def[name] as? T {
                localCache[name] = x
                return x
            }
        }
        
        return defaultValue
    }
    
    
    // TODO support deleting items
    func cascadeList<T>(_ name:String, _ merge:Bool = true) -> [T] {
        if let x = localCache[name] as? [T] { return x }
        
        var result = [T]()
        
        for def in cascadeStack {
            if let x = def[name] as? [T] {
                if !merge {
                    localCache[name] = x
                    return x
                }
                else {
                    result.append(contentsOf: x)
                }
            }
        }
        
        localCache[name] = result
        return result
    }
    
    
    func cascadeDict<T>(_ name:String, _ defaultDict:[String:T] = [:]) -> [String:T] {
        if let x = localCache[name] as? [String:T] { return x }
        
        var result = defaultDict
        
        for def in cascadeStack {
            if let x = def[name] as? [String:T] {
                result.merge(x)
            }
        }
        
        localCache[name] = result
        return result
    }
}

public class CascadingView: Cascadable, ObservableObject {

    private let sessionView: SessionView
    
    var name: String { return sessionView.name ?? "" } // by copy??
    // Find usage of .activeStates = replace with userState
    var userState: UserState { return sessionView.userState ?? UserState() } // set same ref??
    // TODO how to cascade this??
    
    //self.queryOptions.merge(view.queryOptions!)
    var queryOptions: QueryOptions { return sessionView.queryOptions ?? QueryOptions() } // set same ref??
    var viewArguments: [String:Any] { cascadeDict("viewArguments", sessionView.viewArguments) } // set same ref??
    
    var resultSet: ResultSet {
        /* lookup based on queryOptions */ 1
        
        // TODO: set filterText the first time resultSet is loaded
//        // Update search result to match the query
//        self.resultSet = cache.getResultSet(self.queryOptions)
//
//        // Filter the results
//        filterText = _filterText
        
    } // set when queryOptions changes ??
    
    // TODO: REFACTOR: On change clear renderConfig in localCache
    var activeRenderer: String // Set on creation | when changed set on userState
    
    var backTitle: String? { cascadeProperty("backTitle", nil) }
    var showLabels: Bool { cascadeProperty("showLabels", true) }
    
    var actionButton: Action? { cascadeProperty("actionButton", nil) }
    var editActionButton: Action? { cascadeProperty("editActionButton", nil) }
    
    
    var cascadeOrder: [String] { cascadeList("cascadeOrder") }
    var sortFields: [String] { cascadeList("sortFields") }
    var editButtons: [Action] { cascadeList("editButtons") }
    var filterButtons: [Action] { cascadeList("filterButtons") }
    var actionItems: [Action] { cascadeList("actionItems") }
    var navigateItems: [Action] { cascadeList("navigateItems") }
    var contextButtons: [Action] { cascadeList("contextButtons") }
    
    
    
//    var renderer: Renderer? = nil // TODO
//    var rendererView: AnyView? = nil // TODO
    
    var renderConfig: CascadingRenderConfig? {
        if let x = localCache[activeRenderer] { return (x as! CascadingRenderConfig) }
        
        if let renderDefinition = cache.realm.objects(RenderDefinition.self)
            .filter("selector = '[renderer = \(activeRenderer)]'").first {
            
            if let RenderConfigType = globalRenderers!.allConfigTypes[activeRenderer] {
                let renderConfig = RenderConfigType.init(
                    // TODO set renderDefinition parsed version as first element of cascadeStack
                    cascadeStack: self.cascadeStack
                        .compactMap { $0["renderConfigs"]?[activeRenderer] },
                    viewArguments: self.viewArguments
                )
                
                // Not actively preventing conflicts in namespace - assuming chance to be low
                localCache[activeRenderer] = renderConfig
                return renderConfig
            }
        }
    }
    
    private var _emptyResultTextTemp: String? = nil
    var emptyResultText: String {
        get {
            return _emptyResultTextTemp ?? cascadeProperty("emptyResultText", "No items found")
        }
        set (newEmptyResultText) {
            if newEmptyResultText == "" { _emptyResultTextTemp = nil }
            else { _emptyResultTextTemp = newEmptyResultText }
        }
    }
    
    private var _titleTemp: String? = nil
    var title: String {
        get {
            return _titleTemp ?? cascadeProperty("title", "")
        }
        set (newTitle) {
            if newTitle == "" { _titleTemp = nil }
            else { _titleTemp = newTitle }
        }
    }
    
    private var _subtitleTemp: String? = nil
    var subtitle: String {
        get {
            return _subtitleTemp ?? cascadeProperty("subtitle", "")
        }
        set (newSubtitle) {
            if newSubtitle == "" { _subtitleTemp = nil }
            else { _subtitleTemp = newSubtitle }
        }
    }
    
    var filterText: String {
        get {
            return userState["filterText"]
        }
        set (newFilter) {
            
            // Store the new value
            userState["filterText"] = newFilter
            
            // If this is a multi item result set
            if self.resultSet.isList {
                
                // TODO we should probably ask the renderer if this is preferred
                // Some renderers such as the charts would probably rather highlight the
                // found results instead of filtering the other data points out
                
                // Filter the result set
                self.resultSet.filterText = userState["filterText"]
            }
            else {
                print("Warn: Filtering for single items not Implemented Yet!")
            }
            
            if userState.filterText == "" {
                title = ""
                subtitle = ""
                emptyResultText = ""
            }
            else {
                // Set the title to an appropriate message
                if resultSet.count == 0 { title = "No results" }
                else if resultSet.count == 1 { title = "1 item found" }
                else { title = "\(resultSet.count) items found" }
                
                // Temporarily hide the subtitle
                // subtitle = " " // TODO how to clear the subtitle ??
                
                emptyResultText = "No results found using '\(userState["filterText"])'"
            }
        }
    }
    
    private let cache:Cache
    
    init(_ ch:Cache, sessionView:SessionView, cascadeStack:[ViewSelector]){
        self.cache = ch
        self.sessionView = sessionView
        self.cascadeStack = cascadeStack
    }
    
    // TODO REFACTOR: Move to parser
//    public func validate() throws {
//        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
//
//        let renderProps = self.renderConfigs.objectSchema.properties
//        if renderProps.filter({ (property) in property.name == self.rendererName }).count == 0 {
////            throw("Missing renderConfig for \(self.rendererName) in this view")
//            print("Warn: Missing renderConfig for \(self.rendererName) in this view")
//        }
//
//        if self.queryOptions.query == "" { throw("No query is defined for this view") }
//        if self.actionButton == nil && self.editActionButton == nil {
//            print("Warn: Missing action button in this view")
//        }
//    }
    
    subscript(propName:String) -> Any {
        get {
            let type: Mirror = Mirror(reflecting:self)

            for child in type.children {
                if child.label! == name || child.label! == "_" + name {
                    return child.value
                }
            }
            
            let x:String? = nil
            return x as Any
        }
    }
    
    public class func fromSessionView(_ sessionView:SessionView, main:Main) throws -> CascadingView {
        var cascadeStack:[[String:Any]] = [main.views.getParsedDefinition(sessionView.viewDefinition)]
        let viewArguments = sessionView.viewArguments
        var isList = true
        var type = ""
        
        // Fetch query from the view from session
        if let queryOptions = sessionView.queryOptions {
            
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

        var needles:[String]
        if type != "mixed" {
            // Determine query
            needles = [
                isList ? "\(type)[]" : "\(type)", // TODO if this is not found it should get the default template
                isList ? "*[]" : "*"
            ]
        }
        else {
            needles = [isList ? "*[]" : "*"]
        }
        
        // Find views based on datatype
        for needle in needles {
            for key in ["user", "defaults"] {
                
                if let sessionViewDef = main.realm.objects(SessionViewDefinition.self)
                    .filter("selector = '\(needle)' and domain = '\(key)").first {
                    
                    cascadeStack.append(main.views.getParsedDefinition(sessionViewDef))
                }
            }
        }
        
        // Create a new view
        return CascadingView(cache, sessionView, cascadeStack)
    }
    
}
