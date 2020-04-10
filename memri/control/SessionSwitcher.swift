//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct SessionSwitcher: View {
    @EnvironmentObject var main: Main

    let items: [Int] = [0,1,2,3,4,5,6,7,8,9,10]
    
    var body: some View {
        ZStack {
            if self.main.showSessionSwitcher || true {
                Image("session-switcher-tile")
                    .resizable(resizingMode: .tile)
                    .edgesIgnoringSafeArea(.vertical)
                
                ForEach(items, id: \.self) { i in
                    Image("screenshot-example")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280 - CGFloat((10-i) * 10), height: nil, alignment: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .offset(x: 0, y: CGFloat(i * 30))
                        .shadow(color: .init(hex: "#222"), radius: 15, x: 10, y: 10)
//                        .rotation3DEffect(.degrees(0.3), axis: (x:0, y:1, z:0), anchor: .center, anchorZ: .zero, perspective: 100)
                        .rotation3DEffect(.degrees(40), axis: (x: 0, y: 0, z: 0))
                        
                }
                
                Text("Hello world")
            }
        }
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct SessionSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        SessionSwitcher().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
