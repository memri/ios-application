//
//  MainActions.swift
//  memri
//
//  Created by Koen van der Veen on 06/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

extension Main {
    
    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ itm:DataItem? = nil, _ itms:[DataItem]? = nil) {
        
        let params = action.actionArgs
        let item = itm ?? computedView.resultSet.item
        let selection = itms ?? computedView.selection
        
        if action.actionName.opensView {
            switch action.actionName {
            case .openView:
                if (params.count > 0) { openView(params[0].value as! SessionView) }
                else if selection.count > 0 { openView(selection) } // TODO does this mean anything?
                else if let item = item as? SessionView { openView(item) }
                else if let item = item { openView(item) }
            case .openViewByName:
                openView(params[0].value as! String)
            case .openSession:
                if (params.count > 0) { openSession(params[0].value as! Session) }
                else if let item = item as? Session { openSession(item) }
            case .openSessionByName:
                openSession(params[0].value as! String)
            case .showStarred:
                showStarred(starButton: action)
            case .back: back()
            case .forward: forward()
            case .forwardToFront: forwardToFront()
            case .backAsSession: backAsSession()
            case .add: addFromTemplate(params[0].value as! DataItem)
            default:
                print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
            }
        }
        else {
            
            // Track state of the action and toggle the state variable based on actionStateName
            if selection.count == 0 && action.hasState.value == true,
              let actionStateName = action.actionStateName {
                toggleState(actionStateName, item)
            }
            
            switch action.actionName {
            case .delete:
                if selection.count > 0 { cache.delete(selection) }
                else if let item = item { cache.delete(item) }
                scheduleUIUpdate()
            case .star:
                if selection.count > 0, let item = item { star(selection, item.starred) }
            case .share: showSharePanel()
            case .setRenderer: changeRenderer(rendererObject: action as! Renderer)
            case .addToList: addToList()
            case .duplicate:
                if selection.count > 0 {
                    selection.forEach{ item in addFromTemplate(item) }
                }
                else if let item = item { addFromTemplate(item) }
            case .showSessionSwitcher:
                break
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
        
    func toggleState(_ statePattern:String, _ itm:DataItem? = nil) {
        // Make sure we have an item update
        let item = itm ?? computedView.resultSet.item
        
        // Parse the state pattern
        let (objectToUpdate, propToUpdate) = CompiledView.parseExpression(statePattern, "view")
        
        // TODO error handling
        
        // Persist these changes
        try! realm.write {

            // Toggle the right property on the right object
            switch objectToUpdate {
            case "main":
                self[propToUpdate] = !(self[propToUpdate] as! Bool)
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
                    
                    // TODO currently there are no listeners on data??
                    scheduleUIUpdate()
                }
                else {
                    print("Warning: No item found to update")
                }
            default:
                print("Warning: Unknown object to update: \(statePattern)")
            }
        }
    }
    
    func hasState(_ statePattern:String, _ itm:DataItem? = nil) -> Bool {
        // Make sure we have an item update
        let item = itm ?? computedView.resultSet.item
        
        // Parse the state pattern
        let (objectToQuery, propToQuery) = CompiledView.parseExpression(statePattern, "view")
        
        // Toggle the right property on the right object
        switch objectToQuery {
        case "main":
            return self[propToQuery] as! Bool
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
                print("Warning: No item found to query")
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
        session.setCurrentView(view)
        
        // Set accessed date to now
        view.access()
        
        // Recompute view
        scheduleComputeView()
    }
    
    func openView(_ item:DataItem){
        // Create a new view
        let view = SessionView()
        
        // Set the query options to load the item
        let primKey = DataItemFamily(rawValue: item.type)!.getPrimaryKey()
        view.queryOptions!.query = "\(item.type) AND \(primKey) = '\(item.getString(primKey))'"
        
        // Open the view
        self.openView(view)
    }
    
    public func openView(_ viewName: String, _ stateName:String?=nil) {
        
        // Fetch a dynamic view based on its name
        if let view:SessionView = views.getSessionView(viewName) {
            
            // Toggle the state to true
            if let stateName = stateName { view.toggleState(stateName) }
            
            // Open the view
            openView(view)
        }
        else {
            print("Warn: Could not find view: '\(viewName)")
        }
    }
    public func openView(_ items: [DataItem]) {}

    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    func openSession(_ session:Session) {
        let sessions = self.sessions // TODO generalize
        
        // Add view to session and set it as current
        sessions.setCurrentSession(session)
        
        // Recompute view
        scheduleComputeView()
    }
    /**
     *
     */
    public func openSession(_ name:String) {
        
        // TODO: This should not fetch the session from named sessions
        //       but instead load a sessionview that loads the named sessions by
        //       computing them (implement viewFromSession that is used in dynamic
        //       view to sessionview
        
        // Fetch a dynamic view based on its name
        let (session, _) = views.getSessionOrView(name, wrapView:true)
        if let session = session {
            
            // Open the view
            openSession(session)
        }
        else {
            print("Warn: Could not find session: '\(name)")
        }
    }
    
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
    
    func forward() {
        let session = currentSession
        
        if session.currentViewIndex == session.views.count - 1 {
            print("Warn: Can't go forward. Already at last view in session")
        }
        else {
            try! realm.write {
                session.currentViewIndex += 1
            }
            
            scheduleComputeView()
        }
    }
    func forwardToFront() {
        let session = currentSession
        
        try! realm.write {
            session.currentViewIndex = session.views.count - 1
        }
        
        scheduleComputeView()
    }
    
    func backAsSession() {
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("Warn: Can't go back. Already at earliest view in session")
        }
        else {
            let duplicateSession = cache.duplicate(session as! DataItem) as! Session // This will work when merged with multiple-data-types branch
            
            try! realm.write {
                duplicateSession.currentViewIndex -= 1
            }
            
            openSession(duplicateSession)
        }
    }
    
    func changeRenderer(rendererObject: Renderer){
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
    
    func star(_ items:[DataItem], _ toValue:Bool=true) {
        try! realm.write {
            for item in items {
                item.starred = toValue
            }
        }
        
        // TODO if starring is ever allowed in a list resultset view,
        // it won't be updated as of now
    }

    func showStarred(starButton: ActionDescription){
        
        // If button is active lets create a filtered view
        if !self.computedView.hasState(starButton.actionStateName!) {
        
            // Open named view 'showStarred'
            openView("filter-starred", starButton.actionStateName)
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
