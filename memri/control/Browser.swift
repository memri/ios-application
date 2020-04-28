//
//  ContentView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct Browser: View {
    @EnvironmentObject var main: Main
    
    @ObservedObject var keyboardResponder = KeyboardResponder()
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
//                Loading(isShowing: .constant(self.main.computedView.resultSet.isLoading)) {
                    self.main.currentRendererView.fullHeight()
                        .padding(.bottom, keyboardResponder.currentHeight*0.9)
//                }.fullHeight()
                Search()
                    .offset(y: -keyboardResponder.currentHeight*0.9)
            }.fullHeight()
            
            ContextPane()
        }
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
