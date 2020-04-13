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
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
//                Loading(isShowing: .constant(self.main.computedView.resultSet.isLoading)) {
                    self.main.currentRendererView.fullHeight()
//                }.fullHeight()
                Search()
            }.fullHeight()
            
            ContextPane()
        }
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
