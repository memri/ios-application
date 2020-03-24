//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    @EnvironmentObject var main: Main
    @Binding var showContextPane: Bool

    private let forgroundPercentageWidth: CGFloat = 0.75
    
    @State var dragOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            ContextPaneBackground()
                .opacity(0.25)
                .edgesIgnoringSafeArea(.vertical)
            ContextPaneForground()
                .frame(width: UIScreen.main.bounds.width * forgroundPercentageWidth)
                .offset(x: (UIScreen.main.bounds.width / 2.0) * (1.0 - forgroundPercentageWidth) + max(self.dragOffset.width, 0) )
                .offset(y: 20)
                .edgesIgnoringSafeArea(.vertical)
        }
        .gesture(DragGesture()
        .onChanged({ value in
            self.dragOffset = value.translation
        })
            .onEnded{ value in
                self.showContextPane.toggle()
        })
    }
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane(showContextPane: .constant(true)).environmentObject(Main(name: "", key: "").mockBoot())
    }
}
