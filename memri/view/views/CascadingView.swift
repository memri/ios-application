//
//  ComputedView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class CascadingView: Cascadable, ObservableObject {

    private let sessionView: SessionView
    
    var name: String { return sessionView.name ?? "" } // by copy??
    // Find usage of .activeStates = replace with userState
    var userState: UserState { return sessionView.userState ?? UserState() } // set same ref??
    // TODO how to cascade this??
    
    //self.queryOptions.merge(view.queryOptions!)
    var queryOptions: QueryOptions { return sessionView.queryOptions ?? QueryOptions() } // set same ref??
    var viewArguments: ViewArguments {
        sessionView.viewArguments ?? ViewArguments()
        // TODO let this cascade when the use case for it arrises
        // cascadeProperty("viewArguments", )
    }
    
    var resultSet: ResultSet {
        if let x = localCache["resultSet"] as? ResultSet { return x }
        
        // Update search result to match the query
        // NOTE: allowed force unwrap
        let resultSet = main!.cache.getResultSet(self.queryOptions)
        localCache["resultSet"] = resultSet

        // Filter the results
        filterText = userState["filterText"] as? String ?? ""
        
        return resultSet
        
    } // TODO: Refactor set when queryOptions changes ??
    
    // TODO: REFACTOR: On change clear renderConfig in localCache
    var activeRenderer: String // Set on creation | when changed set on userState
    
    var backTitle: String? { cascadeProperty("backTitle", nil) }
    var searchHint: String { cascadeProperty("searchHint", nil) ?? "" }
    var showLabels: Bool { cascadeProperty("showLabels", true) }
    
    var actionButton: Action? { cascadeProperty("actionButton", nil) }
    var editActionButton: Action? { cascadeProperty("editActionButton", nil) }
    
    var sortFields: [String] { cascadeList("sortFields") }
    var editButtons: [Action] { cascadeList("editButtons") }
    var filterButtons: [Action] { cascadeList("filterButtons") }
    var actionItems: [Action] { cascadeList("actionItems") }
    var navigateItems: [Action] { cascadeList("navigateItems") }
    var contextButtons: [Action] { cascadeList("contextButtons") }
    
    var main:Main?
    
    var renderConfig: CascadingRenderConfig? {
        if let x = localCache[activeRenderer] as? CascadingRenderConfig { return x }
        
        var stack = self.cascadeStack.compactMap {
            ($0["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [])
                .filter { $0.name == activeRenderer }.first
        }
        
        let renderDSLDefinitions = main!.views.fetchDefinitions("[renderer = \"\(activeRenderer)\"]")
        for def in renderDSLDefinitions {
            do {
                if let parsedRenderDef = try main?.views.parseDefinition(def) as? CVUParsedRendererDefinition {
                    if parsedRenderDef.domain == "user" {
                        let insertPoint:Int = {
                            for i in 0..<stack.count { if stack[i].domain == "view" { return i } }
                            return stack.count
                        }()
                        
                        stack.insert(parsedRenderDef, at: insertPoint)
                    }
                    else {
                        stack.append(parsedRenderDef)
                    }
                }
                else {
                    // TODO Error logging
                }
            }
            catch {
                // TODO Error logging
            }
        }
        
        
        if let allRenderers = allRenderers, let RenderConfigType = allRenderers.allConfigTypes[activeRenderer] {
            let renderConfig = RenderConfigType.init(cascadeStack, viewArguments)
            // Not actively preventing conflicts in namespace - assuming chance to be low
            localCache[activeRenderer] = renderConfig
            return renderConfig
        }
        else {
            // TODO Error Logging
            
            return CascadingRenderConfig([], ViewArguments())
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
            return userState["filterText"] as? String ?? ""
        }
        set (newFilter) {
            // Don't update the filter when it's already set
            if newFilter.count > 0 && _titleTemp != nil &&
                userState["filterText"] as? String == newFilter {
                return
            }
            
            // Store the new value
            userState["filterText"] = newFilter
            
            // If this is a multi item result set
            if self.resultSet.isList {
                
                // TODO we should probably ask the renderer if this is preferred
                // Some renderers such as the charts would probably rather highlight the
                // found results instead of filtering the other data points out
                
                // Filter the result set
                self.resultSet.filterText = newFilter
            }
            else {
                print("Warn: Filtering for single items not Implemented Yet!")
            }
            
            if userState["filterText"] == "" {
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
                
                emptyResultText = "No results found using '\(userState["filterText"] ?? "")'"
            }
        }
    }
    
    init(_ sessionView:SessionView,
         _ cascadeStack:[CVUParsedDefinition],
         _ activeRenderer:String
    ){
        self.sessionView = sessionView
        self.activeRenderer = activeRenderer
        super.init()
        self.cascadeStack = cascadeStack
    }
    
    subscript(propName:String) -> Any {
        get {
            let type: Mirror = Mirror(reflecting:self)

            for child in type.children {
                if child.label == name || child.label == "_" + name {
                    return child.value
                }
            }
            
            let x:String? = nil
            return x as Any
        }
    }
    
    public class func fromSessionView(_ sessionView:SessionView, in main:Main) throws -> CascadingView {
        var cascadeStack:[CVUParsedDefinition] = []
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
        
        var activeRenderer:String? = nil
        
        func parse(_ def:CVUStoredDefinition?, _ domain:String){
            do {
                guard let def = def else {
                    throw "Exception: missing view definition"
                }
                
                if let parsedDef = try main.views.parseDefinition(def) {
                    parsedDef.domain = domain
                    
                    if activeRenderer == nil, let d = parsedDef["defaultRenderer"] {
                        if let d = d as? String { activeRenderer = d }
                        else {
                            // TODO ERror logging
                        }
                    }
                    
                    cascadeStack.append(parsedDef)
                }
                else {
                    // TODO Error logging
                }
            }
            catch {
                // TODO Error logging
            }
        }
        
        // Find views based on datatype
        for needle in needles {
            for key in ["user", "session", "defaults"] {
                if key == "view" { parse(sessionView.viewDefinition, key) }
                else if let sessionViewDef = main.views.fetchDefinitions(needle, domain:key).first {
                    parse(sessionViewDef, key)
                }
            }
        }
        
        if activeRenderer == nil {
            // TODO Error Logging
        }
        
        // Create a new view
        let c = CascadingView(sessionView, cascadeStack, activeRenderer ?? "")
        c.main = main
        return c
    }
    
}
