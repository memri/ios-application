//
//  ContentView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

let _keyBoardResponder = KeyboardResponder()

struct Browser: View {
    @EnvironmentObject var main: MemriContext
    @ObservedObject var keyboardResponder = _keyBoardResponder
    
    var body: some View {
        return ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
//                Loading(isShowing: .constant(self.main.cascadingView.resultSet.isLoading)) {
                    allRenderers?.allViews[self.main.cascadingView.activeRenderer]
                        .fullHeight()
                        .padding(.bottom, keyboardResponder.currentHeight)
//                }.fullHeight()
                Search()
                    .offset(y: min(0, -keyboardResponder.currentHeight+20))
//                .KeyboardAwarePadding()
            }.fullHeight()
            
            ContextPane()
        }
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
