//
//  SubView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

// TODO Refactor: optimize this for performance
public struct SubView: View {
    @EnvironmentObject var main: RootMain
    
    var proxyMain: Main? = nil

    // There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
    // By only duplicating that line and setting session later, but I am too lazy to do that.
    // TODO Refactor
    public init (_ viewName: String, _ item: DataItem, _ variables:[String: Any]){
        // TODO Refactor: maybe prevent the lower sessions from being created??
        var (sess, view) = main.views.getSessionOrView(viewName, wrapView:false, variables)

        // TODO Refactor: error handling
        if view == nil { view = sess!.views.last! }
        
        // TODO: Refactor: This can be optimized by not querying for othe dataItem
        view!.queryOptions = QueryOptions(query: "\(item.genericType) AND uid = '\(item.uid)'")
        view!.variables = variables
        
        let session = Session()
        session.views.append(view!)
        session.currentViewIndex = 0
        
        self.proxyMain = main.createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    public init (_ view: SessionView, _ item: DataItem, _ variables:[String: Any]){
        // TODO: Refactor: This can be optimized by not querying for othe dataItem
        view.queryOptions = QueryOptions(query: "\(item.genericType) AND uid = '\(item.uid)'")
        view.variables = variables
        
        let session = Session()
        session.views.append(view)
        session.currentViewIndex = 0
        
        self.proxyMain = main.createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    public var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
                self.proxyMain!.currentRendererView.fullHeight()
                Search()
            }.fullHeight()
            
//            ContextPane()
        }.environmentObject(self.proxyMain!)
    }
}
