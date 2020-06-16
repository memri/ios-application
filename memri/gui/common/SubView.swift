//
//  SubView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

// TODO Refactor: optimize this for performance
public struct SubView : View {
    @EnvironmentObject var context: MemriContext
    
    var proxyMain: MemriContext? = nil
    var toolbar: Bool = true
    var searchbar: Bool = true
    var showCloseButton: Bool = false
    
    // There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
    // By only duplicating that line and setting session later, but I am too lazy to do that.
    // TODO Refactor
    public init (context:MemriContext, viewName: String, dataItem: DataItem, args:ViewArguments){
        self.toolbar = args.get("toolbar") ?? toolbar
        self.searchbar = args.get("searchbar") ?? searchbar
        self.showCloseButton = args.get("showCloseButton") ?? showCloseButton
        
        do {
            guard let context = context as? RootContext else {
                throw "Exception: Too much nesting"
            }
            let storedDef = context.views.fetchDefinitions(name:viewName, type:"view").first
            var def = try context.views.parseDefinition(storedDef)
            if def is CVUParsedSessionDefinition {
                if let list = def?["views"] as? [CVUParsedViewDefinition] { def = list.first }
            }
            guard let viewDef = def else {
                throw "Exception: Missing view"
            }
            
            args.set(".", dataItem)
            
            var values = [
                "viewDefinition": storedDef,
                "viewArguments": args
            ]
            
            if let sourceDef = viewDef["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
                values["datasource"] = try Datasource.fromCVUDefinition(sourceDef, args)
            }
            
            let view = SessionView(value: values)
        
            let session = Session()
            session.views.append(view)
            session.currentViewIndex = 0
            
            self.proxyMain = context.createSubContext(session)
            do { try self.proxyMain?.updateCascadingView() }
            catch {
                // TODO Refactor error handling
                throw "Cannot update CascadingView \(self): \(error)"
            }
        }
        catch let error {
            // TODO Refactor: error handling
            print("Error: cannot init subview: \(error)")
            debugHistory.error("Error: cannot init subview: \(error)")
        }
    }
    
    public init (context: MemriContext, view: SessionView, dataItem: DataItem, args:ViewArguments){
        self.toolbar = args.get("toolbar") ?? toolbar
        self.searchbar = args.get("searchbar") ?? searchbar
        self.showCloseButton = args.get("showCloseButton") ?? showCloseButton
        
        do {
            guard let context = context as? RootContext else {
                throw "Exception: Too much nesting"
            }
            
            args.set(".", dataItem)
            
            view.viewArguments = args
            
            let session = Session()
            session.views.append(view)
            session.currentViewIndex = 0
            
            self.proxyMain = context.createSubContext(session)
            try self.proxyMain?.updateCascadingView()
        }
        catch {
            // TODO Refactor error handling
            print("Error: cannot init subview, failed to update CascadingView: \(error)")
            debugHistory.error("Error: cannot init subview, failed to update CascadingView: \(error)")
        }
    }
    
    // TODO refactor: consider inserting Browser here and adding variables instead
    public var body : some View {
//        ZStack {
            VStack(alignment: .center, spacing: 0) {
                if self.toolbar {
                    TopNavigation(inSubView: true, showCloseButton: showCloseButton)
                }
                allRenderers?.allViews[self.proxyMain?.cascadingView.activeRenderer ?? "list"]
                    .fullHeight()
                
                if self.searchbar {
                    Search()
                }
            }
            .fullHeight()
            // NOTE: Allowed force unwrap
            .environmentObject(self.proxyMain!)
            
//            ContextPane()
//        }
    }
}
