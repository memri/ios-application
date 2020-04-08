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
        
        if action.actionName.opensView {
            switch action.actionName {
            case .openView:
                if (params.count > 0) { openView(params[0].value as! SessionView) }
                else if let item = item { openView(item) }
                else if let items = items { openView(items) }
            case .openViewByName:
                openView(params[0].value as! String)
            case .showStarred:
                showStarred(starButton: action)
            default:
                print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
            }
        }
        else {
            
            // Track state of the action and toggle the state variable based on actionStateName
            if action.hasState.value == true, let actionStateName = action.actionStateName{
                toggleState(actionStateName, item)
            }
            
            switch action.actionName {
            case .back: back()
            case .add: addFromTemplate(params[0].value as! DataItem)
            case .delete:
                if let item = item { cache.delete(item) }
                else if let items = items { cache.delete(items) }
                scheduleUIUpdate()
            case .star:
                if let item = item { star([item]) }
                else if let items = items { star(items) }
            case .share: showSharePanel()
            case .setRenderer: changeRenderer(rendererObject: action as! RendererObject)
            case .addToList: addToList()
            case .duplicate:
                if let item = item { addFromTemplate(item) }
            case .toggleEditMode, .toggleFilterPanel, .showContextPane, .showNavigation:
                break // Do nothing
            case .exampleUnpack:
                let (_, _) = (params[0].value, params[1].value) as! (String, Int)
                break
            default:
                print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
            }
        }
    }
        
    func toggleState(_ statePattern:String, _ item:DataItem? = nil) {
        // Parse the state pattern
        let (objectToUpdate, propToUpdate) = DynamicView.parseExpression(statePattern, "view")
        
        // TODO error handling
        
        // Persist these changes
        try! realm.write {

            // Toggle the right property on the right object
            switch objectToUpdate {
            case "sessions":
                self.sessions[propToUpdate] = !(self.sessions[propToUpdate] as! Bool)
            case "currentSession":
                fallthrough
            case "session":
                self.currentSession[propToUpdate] = !(self.currentSession[propToUpdate] as! Bool)
            case "computedView":
                self.computedView.toggleState(propToUpdate)
            case "sessionView":
                self.currentSession.currentView.toggleState(propToUpdate)
                setComputedView()
            case "view":
                self.computedView.toggleState(propToUpdate)
                self.currentSession.currentView.toggleState(propToUpdate)
            case "dataItem":
                if let item = item {
                    item[propToUpdate] = !(item[propToUpdate] as! Bool)
                }
                else {
                    print("Warning: No item found to update")
                }
            default:
                print("Warning: Unknown object to update: \(statePattern)")
            }
        }
    }
    
    func hasState(_ statePattern:String, _ item:DataItem? = nil) -> Bool {
        
        // Parse the state pattern
        let (objectToQuery, propToQuery) = DynamicView.parseExpression(statePattern, "view")
        
        // Toggle the right property on the right object
        switch objectToQuery {
        case "sessions":
            return self.sessions[propToQuery] as! Bool
        case "currentSession":
            fallthrough
        case "session":
            return self.currentSession[propToQuery] as! Bool
        case "computedView":
            return self.computedView.hasState(propToQuery)
        case "sessionView":
            return self.currentSession.currentView.hasState(propToQuery)
        case "view":
            return self.computedView.hasState(propToQuery)
        case "dataItem":
            if let item = item {
                return item[propToQuery] as! Bool
            }
            else {
                print("Warning: No item found to update")
            }
        default:
            print("Warning: Unknown object to query: \(statePattern) \(objectToQuery) \(propToQuery)")
        }
        
        return false
    }

    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    func openView(_ view:SessionView) {
        let session = self.currentSession
        
        // Add view to session
        session.addView(view)
        
        // Recompute view
        scheduleComputeView()
    }
    
    func openView(_ item:DataItem){
        // Create a new view
        let view = SessionView()
        
        // Set the query options to load the item
        view.queryOptions!.query = item.getString("uid")
        
        // Open the view
        self.openView(view)
    }
    
    public func openView(_ viewDeclaration: String, _ stateName:String?=nil) {
        // If this is a dynamic view
        if (viewDeclaration.prefix(1) == "{") {
            
            // Generate the session view
            let view = DynamicView(viewDeclaration, self).generateView()
            
            // Toggle the state to true
            if let stateName = stateName { view.toggleState(stateName) }
            
            // Open the view
            openView(view)
        }
        else {
            // TODO find view by name
        }
    }
    public func openView(_ items: [DataItem]) {}

    /**
     * Add a new data item and displays that item in the UI
     * in edit mode
     */
    public func addFromTemplate(_ template:DataItem) {
        // Copy template
        let copy = self.cache.duplicate(template)
        
        // Add the new item to the cache
        _ = try! self.cache.addToCache(copy)
        
        // Open view with the now managed copy
        self.openView(copy)
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
        if !self.computedView.hasState(starButton.actionStateName!) {
        
            // Define a dynamic view that shows a starred subset of the current view
            let viewDeclaration = """
            {
                "copyCurrentView": true,
                "queryOptions": {
                    "query": "{computedView.queryOptions.query} AND starred = true"
                },
                "title": "Starred {computedView.title}"
            }
            """
            
            // Open View
            openView(viewDeclaration, starButton.actionStateName)
        }
        else {
            // Go back to the previous view
            back()
        }
    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }

}