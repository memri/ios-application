//
//  ContentView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct Browser: View {
    @EnvironmentObject var context: MemriContext
    
    var body: some View {
        return ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
//                Loading(isShowing: .constant(self.context.cascadingView.resultSet.isLoading)) {
                    allRenderers?.allViews[self.context.cascadingView.activeRenderer]
                        .fullHeight()
//                }.fullHeight()
                Search()
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
