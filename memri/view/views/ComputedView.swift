//
//  ComputedView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public class ComputedView: ObservableObject {

    var queryOptions: QueryOptions = QueryOptions()
    var resultSet: ResultSet

    var name: String = ""
    var rendererName: String = ""
    var backTitle: String = ""
    var icon: String = ""
    var browsingMode: String = ""

    var showLabels: Bool = true

    var cascadeOrder: [String] = []
    var sortFields: [String] = []
    var selection: [DataItem] = []
    var editButtons: [ActionDescription] = []
    var filterButtons: [ActionDescription] = []
    var actionItems: [ActionDescription] = []
    var navigateItems: [ActionDescription] = []
    var contextButtons: [ActionDescription] = []
    var activeStates: [String] = []
    
    var renderer: Renderer? = nil // TODO
    var rendererView: AnyView? = nil // TODO
    var sessionView: SessionView? = nil
    var renderConfigs: RenderConfigs = RenderConfigs()
    var actionButton: ActionDescription? = nil
    var editActionButton: ActionDescription? = nil
    
    var variables: [String:Any] = [:]
    
    private var _emptyResultText: String = "No items found"
    private var _emptyResultTextTemp: String? = nil
    var emptyResultText: String {
        get {
            return _emptyResultTextTemp ?? _emptyResultText
        }
        set (newEmptyResultText) {
            if newEmptyResultText == "" { _emptyResultTextTemp = nil }
            else { _emptyResultTextTemp = newEmptyResultText }
        }
    }
    
    private var _title: String = ""
    private var _titleTemp: String? = nil
    var title: String {
        get {
            return _titleTemp ?? _title
        }
        set (newTitle) {
            if newTitle == "" { _titleTemp = nil }
            else { _titleTemp = newTitle }
        }
    }
    
    private var _subtitle: String = ""
    private var _subtitleTemp: String? = nil
    var subtitle: String {
        get {
            return _subtitleTemp ?? _subtitle
        }
        set (newSubtitle) {
            if newSubtitle == "" { _subtitleTemp = nil }
            else { _subtitleTemp = newSubtitle }
        }
    }
    
    private var _filterText: String = ""
    var filterText: String {
        get {
            return _filterText
        }
        set (newFilter) {
            
            // Store the new value
            _filterText = newFilter
            
            // If this is a multi item result set
            if self.resultSet.isList {
                
                // TODO we should probably ask the renderer if this is preferred
                // Some renderers such as the charts would probably rather highlight the
                // found results instead of filtering the other data points out
                
                // Filter the result set
                self.resultSet.filterText = _filterText
            }
            else {
                print("Warn: Filtering for single items not Implemented Yet!")
            }
            
            if _filterText == "" {
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
                
                emptyResultText = "No results found using '\(_filterText)'"
            }
            
            // Save the state on the session view
            try! cache.realm.write { sessionView!.filterText = filterText }
        }
    }
    
    private let cache:Cache
    
    init(_ ch:Cache){
        cache = ch
        resultSet = ResultSet(cache)
    }
    
    public func merge(_ view:SessionView) {
        // TODO this function is called way too often
        
        self.queryOptions.merge(view.queryOptions!)
        
        self.name = view.name ?? self.name
        self.rendererName = view.rendererName ?? self.rendererName
        self.backTitle = view.backTitle ?? self.backTitle
        self.icon = view.icon ?? self.icon
        self.browsingMode = view.browsingMode ?? self.browsingMode
        
        _title = view.title ?? _title
        _subtitle = view.subtitle ?? _subtitle
        _filterText = view.filterText ?? _filterText
        _emptyResultText = view.emptyResultText ?? _emptyResultText
        
        self.showLabels = view.showLabels.value ?? self.showLabels
        
        if view.sortFields.count > 0 {
            self.sortFields.removeAll()
            self.sortFields.append(contentsOf: view.sortFields)
        }
        
        self.cascadeOrder.append(contentsOf: view.cascadeOrder)
        self.selection.append(contentsOf: view.selection)
        self.editButtons.append(contentsOf: view.editButtons)
        self.filterButtons.append(contentsOf: view.filterButtons)
        self.actionItems.append(contentsOf: view.actionItems)
        self.navigateItems.append(contentsOf: view.navigateItems)
        self.contextButtons.append(contentsOf: view.contextButtons)
        self.activeStates.append(contentsOf: view.activeStates)
        
        if let renderConfigs = view.renderConfigs {
            self.renderConfigs.merge(renderConfigs)
        }
        
        self.actionButton = view.actionButton ?? self.actionButton
        self.editActionButton = view.editActionButton ?? self.editActionButton
        
        if let variables = view.variables {
            for (key, value) in variables {
                self.variables[key] = value
            }
        }
    }
    
    public func finalMerge(_ view:SessionView) {
        // Merge view into self
        merge(view)
        
        // Store session view on self
        sessionView = view
        
        // Update search result to match the query
        self.resultSet = cache.getResultSet(self.queryOptions)
        
        // Filter the results
        filterText = _filterText
    }

    /// Validates a merged view
    public func validate() throws {
        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
        
        let renderProps = self.renderConfigs.objectSchema.properties
        if renderProps.filter({ (property) in property.name == self.rendererName }).count == 0 {
//            throw("Missing renderConfig for \(self.rendererName) in this view")
            print("Warn: Missing renderConfig for \(self.rendererName) in this view")
        }
        
        if self.queryOptions.query == "" { throw("No query is defined for this view") }
        if self.actionButton == nil && self.editActionButton == nil {
            print("Warn: Missing action button in this view")
        }
    }
    
    public func toggleState(_ stateName:String) {
        if let index = activeStates.firstIndex(of: stateName){
            activeStates.remove(at: index)
        }
        else {
            activeStates.append(stateName)
        }
    }
    
    public func hasState(_ stateName:String) -> Bool{
        if activeStates.contains(stateName){
            return true
        }
        return false
    }
    
    public func getPropertyValue(_ name:String) -> Any {
        let type: Mirror = Mirror(reflecting:self)

        for child in type.children {
            if child.label! == name || child.label! == "_" + name {
                return child.value
            }
        }
        
        return ""
    }
    
}
