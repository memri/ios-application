//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

extension View {
    func fullHeight() -> some View {
        self.frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0, maxHeight: .infinity,
                   alignment: Alignment.topLeading)
    }
}

struct Application: View {
    @EnvironmentObject var main: Main
    
    var body: some View {
        ZStack() {
            Browser()
            
            ContextPane()

            if self.main.showNavigation {
                Navigation()
                    .transition(.move(edge: .leading))
                    .animation(.easeOut(duration: 0.3))
            }
        }.fullHeight()
    }
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        Application().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
