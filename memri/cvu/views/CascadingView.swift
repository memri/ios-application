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

    /// The name of the cascading view
    var name: String { return sessionView.name ?? "" } // by copy??
    
    /// The session view that is being cascaded
    let sessionView: SessionView
    
    var datasource: CascadingDatasource {
        if let x = localCache["datasource"] as? CascadingDatasource { return x }
        
        if let ds = sessionView.datasource {
            let stack = self.cascadeStack.compactMap {
                $0["datasourceDefinition"] as? CVUParsedDatasourceDefinition
            }
            
            let datasource = CascadingDatasource(stack, self.viewArguments, ds)
            localCache["datasource"] = datasource
            return datasource
        }
        else {
            // Missing datasource on sessionview, that should never happen (I think)
            // TODO ERROR REPORTING
            
            return CascadingDatasource([], ViewArguments(), Datasource())
        }
    }
    
    var userState: UserState {
        sessionView.userState ?? UserState(onFirstSave: { args in            realmWriteIfAvailable(self.sessionView.realm) {
                self.sessionView.userState = args
            }
        })
    }
        
    // TODO let this cascade when the use case for it arrises
    override var viewArguments: ViewArguments {
        get {
            sessionView.viewArguments ?? ViewArguments(onFirstSave: { args in
                realmWriteIfAvailable(self.sessionView.realm) { self.sessionView.userState = args }
            })
            // cascadeProperty("viewArguments", )
        }
        set (value) {
            // Do Nothing
        }
    }
    
    var resultSet: ResultSet {
        if let x = localCache["resultSet"] as? ResultSet { return x }
        
        // Update search result to match the query
        // NOTE: allowed force unwrap
        let resultSet = context!.cache.getResultSet(self.datasource.flattened())
        localCache["resultSet"] = resultSet

        // Filter the results
        let ft = userState.get("filterText") ?? ""
        if resultSet.filterText != ft {
            filterText = ft
        }
        
        return resultSet
        
    } // TODO: Refactor set when datasource changes ??
    
    var activeRenderer: String {
        get {
            if let userState = sessionView.userState {
                if let s:String = userState.get("activeRenderer") { return s }
            }
            if let s:String = cascadeProperty("defaultRenderer") { return s }
            
            debugHistory.error("Exception: Unable to determine the active renderer. Missing defaultRenderer in view?")
            return ""
        }
        set (value) {
            localCache.removeValue(forKey: value) // Remove renderConfig reference
            userState.set("activeRenderer", value)
        }
    }
    
    var backTitle: String? { cascadeProperty("backTitle") }
    var searchHint: String { cascadeProperty("searchHint") ?? "" }
    var showLabels: Bool { cascadeProperty("showLabels") ?? true }
    
    var actionButton: Action? { cascadeProperty("actionButton") }
    var editActionButton: Action? { cascadeProperty("editActionButton") }
    
    var sortFields: [String] { cascadeList("sortFields") }
    var editButtons: [Action] { cascadeList("editButtons") }
    var filterButtons: [Action] { cascadeList("filterButtons") }
    var actionItems: [Action] { cascadeList("actionItems") }
    var navigateItems: [Action] { cascadeList("navigateItems") }
    var contextButtons: [Action] { cascadeList("contextButtons") }
    
    var context:MemriContext?
    
    var renderConfig: CascadingRenderConfig? {
        if let x = localCache[activeRenderer] as? CascadingRenderConfig { return x }
        
        var stack = self.cascadeStack.compactMap {
            ($0["renderDefinitions"] as? [CVUParsedRendererDefinition] ?? [])
                .filter { $0.name == activeRenderer }.first
        }
        
        let renderDSLDefinitions = context!.views
            .fetchDefinitions(name:activeRenderer, type:"renderer")
        
        for def in renderDSLDefinitions {
            do {
                if let parsedRenderDef = try context?.views.parseDefinition(def) as? CVUParsedRendererDefinition {
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
                    debugHistory.error("Exception: Unable to cascade render config")
                }
            }
            catch let error {
                // TODO Error logging
                debugHistory.error("\(error)")
            }
        }
                
        if let allRenderers = allRenderers, let RenderConfigType = allRenderers.allConfigTypes[activeRenderer] {
            let renderConfig = RenderConfigType.init(stack, viewArguments)
            // Not actively preventing conflicts in namespace - assuming chance to be low
            localCache[activeRenderer] = renderConfig
            return renderConfig
        }
        else {
            // TODO Error Logging
            debugHistory.error("Exception: Unable to cascade render config")
            return CascadingRenderConfig([], ViewArguments())
        }
    }
    
    private var _emptyResultTextTemp: String? = nil
    var emptyResultText: String {
        get {
            return _emptyResultTextTemp ?? cascadeProperty("emptyResultText") ?? "No items found"
        }
        set (newEmptyResultText) {
            if newEmptyResultText == "" { _emptyResultTextTemp = nil }
            else { _emptyResultTextTemp = newEmptyResultText }
        }
    }
    
    private var _titleTemp: String? = nil
    var title: String {
        get {
            return _titleTemp ?? cascadeProperty("title") ?? ""
        }
        set (newTitle) {
            if newTitle == "" { _titleTemp = nil }
            else { _titleTemp = newTitle }
        }
    }
    
    private var _subtitleTemp: String? = nil
    var subtitle: String {
        get {
            return _subtitleTemp ?? cascadeProperty("subtitle") ?? ""
        }
        set (newSubtitle) {
            if newSubtitle == "" { _subtitleTemp = nil }
            else { _subtitleTemp = newSubtitle }
        }
    }
    
    var filterText: String {
        get {
            return userState.get("filterText") ?? ""
        }
        set (newFilter) {
            // Don't update the filter when it's already set
            if newFilter.count > 0 && _titleTemp != nil &&
                userState.get("filterText")  == newFilter {
                return
            }
            
            // Store the new value
            if (userState.get("filterText") ?? "") != newFilter {
                userState.set("filterText", newFilter)
            }
            
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
            
            if userState.get("filterText") == "" {
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
                
                emptyResultText = "No results found using '\(userState.get("filterText") ?? "")'"
            }
        }
    }
    
    var searchMatchText: String {
        get {
            return userState.get("searchMatchText") ?? ""
        }
        set(newValue) {
            userState.set("searchMatchText", newValue)
        }
    }


    
    init(_ sessionView:SessionView,
         _ cascadeStack:[CVUParsedDefinition]
    ){
        self.sessionView = sessionView
        super.init(cascadeStack, ViewArguments())
    }
    
    subscript(propName:String) -> Any? {
        get {
            switch (propName) {
            case "name": return name
            case "sessionView": return sessionView
            case "datasource": return datasource
            case "userState": return userState
            case "viewArguments": return viewArguments
            case "resultSet": return resultSet
            case "activeRenderer": return activeRenderer
            case "backTitle": return backTitle
            case "searchHint": return searchHint
            case "showLabels": return showLabels
            case "actionButton": return actionButton
            case "editActionButton": return editActionButton
            case "sortFields": return sortFields
            case "editButtons": return editButtons
            case "filterButtons": return filterButtons
            case "actionItems": return actionItems
            case "navigateItems": return navigateItems
            case "contextButtons": return contextButtons
            case "renderConfig": return renderConfig
            case "emptyResultText": return emptyResultText
            case "title": return title
            case "subtitle": return subtitle
            case "filterText": return filterText
            default: return nil
            }
        }
        set (value) {
            switch (propName) {
            case "activeRenderer": activeRenderer = value as? String ?? ""
            case "emptyResultText": emptyResultText = value as? String ?? ""
            case "title": title = value as? String ?? ""
            case "subtitle": subtitle = value as? String ?? ""
            case "filterText": filterText = value as? String ?? ""
            default: return
            }
        }
    }
    
    public class func fromSessionView(_ sessionView:SessionView, in context:MemriContext) throws -> CascadingView {
        var cascadeStack:[CVUParsedDefinition] = []
        var isList = true
        var type = ""
        
        // Fetch query from the view from session
        if let datasource = sessionView.datasource {
            
            // Look up the associated result set
            let resultSet = context.cache.getResultSet(datasource)
            
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
                
                if let parsedDef = try context.views.parseDefinition(def) {
                    parsedDef.domain = domain
                    
                    if activeRenderer == nil, let d = parsedDef["defaultRenderer"] {
                        if let d = d as? String { activeRenderer = d }
                        else {
                            // TODO ERror logging
                            debugHistory.error("Could not fnd default renderer")
                        }
                    }
                    
                    cascadeStack.append(parsedDef)
                }
                else {
                    // TODO Error logging
                    debugHistory.error("Could not parse definition")
                }
            }
            catch let error {
                // TODO Error logging
                if let error = error as? CVUParseErrors {
                    debugHistory.error("\(error.toString(def?.definition ?? ""))")
                }
                else {
                    debugHistory.error("\(error)")
                }
            }
        }
        
        // Find views based on datatype
        for key in ["user", "session", "defaults"] {
            if key == "session" {
                parse(sessionView.viewDefinition, key)
                continue
            }
            
            for needle in needles {
                
                if let sessionViewDef = context.views
                    .fetchDefinitions(selector:needle, domain:key).first {
                    
                    parse(sessionViewDef, key)
                }
                else if key != "user" {
                    // TODO Warn logging
                    debugHistory.warn("Could not find definition for '\(needle)' in domain '\(key)'")
                    print("Could not find definition for '\(needle)' in domain '\(key)'")
                }
            }
        }
        
        if activeRenderer == nil {
            // TODO Error Logging
            throw "Exception: could not determine the active renderer for this view"
        }
        
        // Create a new view
        let c = CascadingView(sessionView, cascadeStack)
        c.context = context
        return c
    }
    
}
