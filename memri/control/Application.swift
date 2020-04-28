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
                if $0.translation.width < -100 {
                    withAnimation {
                        self.main.showNavigation = false
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
                        .overlay(Group{
                            if self.showNavigation {
                                Color.black
                                    .opacity(0.40)
                                    .edgesIgnoringSafeArea(.vertical)
                                    .transition(.opacity)
                                    .gesture(TapGesture()
                                        .onEnded{ value in
                                            withAnimation {
                                                self.main.showNavigation = false
                                            }
                                        })
                            }
                        })
                    
                    if self.showNavigation {
                        Navigation()
                            .frame(width: geometry.size.width * 0.8)
                            .edgesIgnoringSafeArea(.vertical)
                            .transition(.move(edge: .leading))
                    }
                }
            }
            .gesture(drag)
        }
    }
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        let main = RootMain(name: "", key: "").mockBoot()
        return Application().environmentObject(main)
    }
}
