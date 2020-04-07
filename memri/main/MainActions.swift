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
    
//    func showNavigation(){
//        try! realm.write {
//            self.sessions.showNavigation = true
//        }
//    }
    
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
            
            // Generate the session view
            // TODO move this to inside openview
            let starredView = DynamicView(viewDeclaration, self).generateView()
            
            // Open View
            openView(starredView)
            
//            // Get a handle to the view to filter
//            let viewToFilter = self.currentSession.currentView
//
//            // Create Starred View
//            let starredView = SessionView(value: viewToFilter)
//
//            // Update the title
//            starredView.title = "Starred \(computedView.title)"
//
//            // Alter the query to add the starred requirement
//            starredView.queryOptions = QueryOptions()
//            starredView.queryOptions!.merge(viewToFilter.queryOptions!)
//            starredView.queryOptions!.query! += " AND starred = true" // TODO this is very naive
//            // TODO perhaps add queryOptions.localOnly = true to prevent server load
//
//            starredView.activeStates.append(starButton.actionName.rawValue)
//
//            // Open View
//            openView(starredView)
        }
        else {
            // Go back to the previous view
            back()
        }
    }
    
//    func toggleEditMode(editButton: ActionDescription){
//
//        //
//        self.sessions.toggleEditMode()
//
//        //
////        self.toggleActive(object: editButton)
//
//        //
//        scheduleComputeView()
//    }
    
//    func toggleFilterPanel(filterPanelButton: ActionDescription){
//        try! realm.write {
//            self.currentSession.showFilterPanel.toggle()
//        }
//    }

//    func openContextPane() {
//        try! realm.write {
//            self.computedView.toggleState("showContextPane")
//            self.currentSession.currentView.toggleState("showContextPane")
//        }
//    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }

}
