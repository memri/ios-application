//
//  ContentView.swift
//  memri
//
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
    
    func fullWidth() -> some View{
        return self.frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.topLeading)
    }
}

struct Application: View {
    @EnvironmentObject var main: Main
    
    @State var showNavigation = false
    
    var body: some View {
        (main as! RootMain).initNavigation(self.$showNavigation)
        
        let drag = DragGesture()
            .onEnded {
                if self.showNavigation {
                    if $0.translation.width < -100 {
                        withAnimation {
                            self.main.showNavigation = false
                        }
                    }
                }
            }
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if self.main.showSessionSwitcher {
                    SessionSwitcher()
                }
                else {
                    Browser()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showNavigation ? geometry.size.width * 0.8 : 0)
                        .disabled(self.showNavigation ? true : false)
                        .overlay(
                            Color.black
                                .opacity(self.showNavigation ? 0.40 : 0)
                                .edgesIgnoringSafeArea(.vertical)
                                .offset(x: self.showNavigation ? geometry.size.width * 0.8 : 0)
                        )
                    
                    if self.showNavigation {
                        Navigation()
                            .frame(width: geometry.size.width * 0.8)
                            .edgesIgnoringSafeArea(.vertical)
                            .transition(.move(edge: .leading))
                    }
                }
            }
//
// TODO - Ruben - Commented out so TableView receives swipe gestures
//
//            .gesture(drag)
        }
    }
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        let main = RootMain(name: "", key: "").mockBoot()
        return Application().environmentObject(main)
    }
}
