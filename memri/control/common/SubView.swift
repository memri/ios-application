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
    @EnvironmentObject var main: Main
    
    var proxyMain: Main? = nil
    var toolbar: Bool = true
    var searchbar: Bool = true
    
    /*
        TODO: There are several problems
                (1) the main reference is in at least .views which means that CompiledView refers
                    to the wrong version main when it is compiling and finding the data item
                (2) the data item that needs to be used to query the properties to dynamically
                    create the view is gotton from currentView.resultSet.item. This is wrong. It
                    must be the dataItem that is passed to SubView.
                (3) I removed dataItem from being passed to SubView as I forgot why this was needed.
                    Can this be inferred from the context? It feels strange to pass it from within
                    the json.
                (4) There is a strange recursion where the SubView gets called again, although the
                    query clearly points to photo, not person. It must somehow not use the proxyMain
                    to render the content. Perhaps Main is references somewhere else as well. I
                    probably want to create any object that has a reference to Main.
     */

    // There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
    // By only duplicating that line and setting session later, but I am too lazy to do that.
    // TODO Refactor
    public init (main:Main, viewName: String, toolbar: Bool, searchbar: Bool, variables:[String: Any]){
        self.toolbar = toolbar
        self.searchbar = searchbar
        
        // TODO Refactor: maybe prevent the lower sessions from being created??
        var (sess, view) = main.views.getSessionOrView(viewName, wrapView:false, variables)

        // TODO Refactor: error handling
        if view == nil { view = sess!.views.last! }
        
        // TODO: Refactor: This can be optimized by not querying for othe dataItem
//        view!.queryOptions = QueryOptions(query: "\(item.genericType) AND uid = '\(item.uid)'")
        view!.variables = variables
        
        let session = Session()
        session.views.append(view!)
        session.currentViewIndex = 0
        
        self.proxyMain = (main as! RootMain).createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    public init (main:Main, view: SessionView, toolbar: Bool, searchbar: Bool, variables:[String: Any]){
        self.toolbar = toolbar
        self.searchbar = searchbar
        
        // TODO: Refactor: This can be optimized by not querying for othe dataItem
//        view.queryOptions = QueryOptions(query: "\(item.genericType) AND uid = '\(item.uid)'")
        view.variables = variables
        
        print (view.queryOptions!.query)
        
        let session = Session()
        session.views.append(view)
        session.currentViewIndex = 0
        
        self.proxyMain = (main as! RootMain).createProxy(session)
        self.proxyMain!.setComputedView()
    }
    
    public var body: some View {
//        ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
                self.proxyMain!.currentRendererView.fullHeight()
                Search()
            }
            .fullHeight()
            .environmentObject(self.proxyMain!)
            
//            ContextPane()
//        }
    }
}
