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
//                Loading(isShowing: .constant(self.main.cascadingView.resultSet.isLoading)) {
                    allRenderers?.allViews[self.main.cascadingView.activeRenderer]
                        .fullHeight()
                        .padding(.bottom, keyboardResponder.currentHeight)
//                }.fullHeight()
                Search()
                    .offset(y: min(0, -keyboardResponder.currentHeight+20))
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
