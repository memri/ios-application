//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct Browser: View {
    @EnvironmentObject var main: Main
    
    var body: some View {
        ZStack {
            VStack() {
                TopNavigation()
                Loading(isShowing: .constant(self.main.computedView.resultSet.isLoading)) {
                    self.main.renderers.allViews[self.main.computedView.rendererName].fullHeight()
                }.fullHeight()
                Search()
            }.fullHeight()
            
            if self.main.currentSession.showContextPane {
                animateInContextPane()
            }
            
            if self.main.sessions.showNavigation{
                Navigation()
                    .transition(.move(edge: .leading))
                    .animation(.easeOut(duration: 0.3))
            }
        }
    }
}

struct animateInContextPane: View {

    @EnvironmentObject var main: Main

    var body: some View {
        ContextPane()
            .transition(.move(edge: .trailing))
            .animation(.easeOut(duration: 0.3))
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
