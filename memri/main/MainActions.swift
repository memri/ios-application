//
//  MainActions.swift
//  memri
//
//  Created by Koen van der Veen on 06/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Main {
    public func executeAction(_ action:ActionDescription, _ item:DataItem? = nil, _ items:[DataItem]? = nil) {
          let params = action.actionArgs
          
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
              
              setComputedView()
          }
      }
      
      func showNavigation(){
          try! realm.write {
              self.sessions.showNavigation = true
          }
          
          scheduleUIUpdate()
      }
      
      func changeRenderer(rendererObject: RendererObject){
          //
          self.setInactive(objects: Array(self.renderObjects.values))
      
          //
          setActive(object: rendererObject)
      
          //
          let session = currentSession
          try! realm.write {
              session.currentView.rendererName = rendererObject.name
          }
          
          //
          setComputedView()
      }
      
      func star(_ items:[DataItem]) {
          try! realm.write {
              for item in items {
                  item.starred = true
              }
          }
          
          // TODO if starring is ever allowed in a list resultset view,
          // it won't be updated as of now
          
          scheduleUIUpdate()
      }

      func showStarred(starButton: ActionDescription){
          
          // Toggle state of the star button
          toggleActive(object: starButton)
          
          // If button is active lets create a filtered view
          if starButton.state.value == true {
              
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
              
              // Open View
              openView(starredView)
          }
          else {
              // Go back to the previous view
              back()
          }
      }
      
      func toggleActive(object: ActionDescription){
          try! realm.write {
              object.state.value!.toggle()
          }
          
          scheduleUIUpdate()
      }
      
      func setActive(object: ActionDescription){
          object.color = object.activeColor ?? object.color
          object.state.value = true
      }
      
      func setInactive(objects: [ActionDescription]){
          for obj in renderObjects.values{
              obj.state.value = false
          }
      }
      
      func toggleEditMode(editButton: ActionDescription){
      
          //
          self.sessions.toggleEditMode()
      
          //
          self.toggleActive(object: editButton)
      
          //
          setComputedView()
      }
      
      func toggleFilterPanel(filterPanelButton: ActionDescription){
          self.toggleActive(object: filterPanelButton)
          
          try! realm.write {
              self.currentSession.showFilterPanel.toggle()
          }
          
          scheduleUIUpdate()
      }

      func openContextPane() {
          try! realm.write {
              self.currentSession.showContextPane.toggle()
          }
          
          scheduleUIUpdate()
      }

      func showSharePanel() {
          print("shareNote")
      }

      func addToList() {
          print("addToList")
      }
}
