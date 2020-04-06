//
//  MainActions.swift
//  memri
//
//  Created by Koen van der Veen on 06/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Main {
    
    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ item:DataItem? = nil, _ items:[DataItem]? = nil) {
        let params = action.actionArgs
        
        // For use configured ActionDescriptions we track state in order to manage
        // the ActionButton's state for them
        var stateValue = false
        let currentView = self.computedView.sessionView
        if action.hasState.value == true && action.actionStateName != nil {
            stateValue = self.computedView.hasState(action.actionStateName!)
        }
        
        switch action.actionName {
        case .back: back()
        case .add: addFromTemplate(params[0].value as! DataItem)
        case .delete:
            if let item = item { cache.delete(item) }
            else if let items = items { cache.delete(items) }
            scheduleUIUpdate()
        case .openView:
            if (params.count > 0) { openView(params[0].value as! SessionView) }
            else if let item = item { openView(item) }
            else if let items = items { openView(items) }
        case .toggleEditMode: toggleEditMode(editButton: action)
        case .toggleFilterPanel: toggleFilterPanel(filterPanelButton: action)
        case .star:
            if let item = item { star([item]) }
            else if let items = items { star(items) }
        case .showStarred: showStarred(starButton: action)
        case .showContextPane: openContextPane()
        case .showNavigation: showNavigation()
        case .openContextView: break
        case .share: showSharePanel()
        case .setRenderer: changeRenderer(rendererObject: action as! RendererObject)
        case .addToList: addToList()
        case .duplicate:
            if let item = item { addFromTemplate(item) }
        case .exampleUnpack:
            let (_, _) = (params[0].value, params[1].value) as! (String, Int)
            break
        default:
            print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
        }
        
        // If this is a state button and there is a user set actionStateName
        if action.hasState.value == true && action.actionStateName != nil {
            
            // If the actions didnt change the current view or the value is moving to true
            if currentView == self.computedView.sessionView || stateValue {
                
                // Toggle the state of the button
                try! realm.write {
                    self.computedView.toggleState(action.actionStateName!)
                    self.computedView.sessionView!.toggleState(action.actionStateName!)
                }
            }
        }
    }
          
    func back(){
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            try! realm.write {
                session.currentViewIndex -= 1
            }
            
            scheduleComputeView()
        }
    }
    
    func showNavigation(){
        try! realm.write {
            self.sessions.showNavigation = true
        }
    }
    
    func changeRenderer(rendererObject: RendererObject){
        //
//        self.setInactive(objects: Array(self.renderObjects.values))
    
        //
//        setActive(object: rendererObject)
    
        //
        let session = currentSession
        try! realm.write {
            session.currentView.rendererName = rendererObject.name
        }
        
        //
        scheduleComputeView()
    }
    
    func star(_ items:[DataItem]) {
        try! realm.write {
            for item in items {
                item.starred = true
            }
        }
        
        // TODO if starring is ever allowed in a list resultset view,
        // it won't be updated as of now
    }

    func showStarred(starButton: ActionDescription){
        
        // If button is active lets create a filtered view
        if !self.computedView.hasState(starButton.actionName.rawValue) {
            
            // Get a handle to the view to filter
            let viewToFilter = self.currentSession.currentView
            
            // Create Starred View
            let starredView = SessionView(value: viewToFilter)
            
            // Update the title
            starredView.title = "Starred \(computedView.title)"
            
            // Alter the query to add the starred requirement
            starredView.queryOptions = QueryOptions()
            starredView.queryOptions!.merge(viewToFilter.queryOptions!)
            starredView.queryOptions!.query! += " AND starred = true" // TODO this is very naive
            // TODO perhaps add queryOptions.localOnly = true to prevent server load
            
            starredView.activeStates.append(starButton.actionName.rawValue)
            
            // Open View
            openView(starredView)
        }
        else {
            // Go back to the previous view
            back()
        }
    }
    
    func toggleEditMode(editButton: ActionDescription){
    
        //
        self.sessions.toggleEditMode()
    
        //
//        self.toggleActive(object: editButton)
    
        //
        scheduleComputeView()
    }
    
    func toggleFilterPanel(filterPanelButton: ActionDescription){
        try! realm.write {
            self.currentSession.showFilterPanel.toggle()
        }
    }

    func openContextPane() {
        try! realm.write {
            self.currentSession.showContextPane.toggle()
        }
    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }

}
