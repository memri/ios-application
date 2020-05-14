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
    @EnvironmentObject var main: Main
    
    var proxyMain: Main? = nil
    var toolbar: Bool = true
    var searchbar: Bool = true
    var showCloseButton: Bool = false
    
    // There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
    // By only duplicating that line and setting session later, but I am too lazy to do that.
    // TODO Refactor
    public init (main:Main, viewName: String, context: DataItem, variables:[String: Any]){
        self.toolbar = variables["toolbar"] as? Bool ?? toolbar
        self.searchbar = variables["searchbar"] as? Bool ?? searchbar
        self.showCloseButton = variables["showCloseButton"] as? Bool ?? showCloseButton
        
        // TODO Refactor: maybe prevent the lower sessions from being created??
        var (sess, view) = main.views.getSessionOrView(viewName, wrapView:false, variables)

        // TODO Refactor: error handling
        if view == nil { view = sess!.views.last! }
        
        // TODO Refactor: this serializes variables to json twice:
        view!.variables = variables
        view!.variables!["."] = context
        
        let session = Session()
        session.views.append(view!)
        session.currentViewIndex = 0
        
        self.proxyMain = (main as! RootMain).createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    public init (main: Main, view: SessionView, context: DataItem, variables: [String: Any]){
        self.toolbar = variables["toolbar"] as? Bool ?? toolbar
        self.searchbar = variables["searchbar"] as? Bool ?? searchbar
        self.showCloseButton = variables["showCloseButton"] as? Bool ?? showCloseButton
        
        // TODO Refactor: this serializes variables to json twice:
        view.variables = variables
        view.variables!["."] = context
        
        let session = Session()
        session.views.append(view)
        session.currentViewIndex = 0
        
        self.proxyMain = (main as! RootMain).createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    // TODO refactor: consider inserting Browser here and adding variables instead
    public var body : some View {
//        ZStack {
            VStack(alignment: .center, spacing: 0) {
                if self.toolbar {
                    TopNavigation(inSubView: true, showCloseButton: showCloseButton)
                }
                
                self.proxyMain!.currentRendererView
                    .fullHeight()
                
                if self.searchbar {
                    Search()
                }
            }
            .fullHeight()
            .environmentObject(self.proxyMain!)
            
//            ContextPane()
//        }
    }
}
