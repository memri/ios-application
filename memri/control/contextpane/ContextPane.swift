//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ContextPane: View {

    @EnvironmentObject var main: Main

    private let forgroundPercentageWidth: CGFloat = 0.75
    
    @State var dragOffset = CGSize.zero

    var body: some View {
        ZStack {
            if self.main.currentSession.showContextPane {
                ContextPaneBackground()
                    .opacity(0.60)
                    .edgesIgnoringSafeArea(.vertical)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.6))
                    .gesture(TapGesture()
                        .onEnded{ value in
                            try! self.main.realm.write {
                                self.main.currentSession.showContextPane.toggle()
                            }
                        })
            
                ContextPaneForground()
                    .frame(width: UIScreen.main.bounds.width * forgroundPercentageWidth)
                    .offset(x: (UIScreen.main.bounds.width / 2.0) * (1.0 - forgroundPercentageWidth) + max(self.dragOffset.width, 0) )
                    .edgesIgnoringSafeArea(.vertical)
                    .gesture(DragGesture()
                        .onChanged({ value in
                            self.dragOffset = value.translation
                        })
                        .onEnded{ value in
                            try! self.main.realm.write {
                                self.main.currentSession.showContextPane.toggle()
                            }
                        })
                    .transition(.move(edge: .trailing))
                    .animation(.easeOut(duration: 0.3))
            }
        }
    }
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
