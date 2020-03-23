//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    private let forgroundPercentageWidth: CGFloat = 0.75
    
    var body: some View {
        ZStack {
            BackgroundContextPane()
                .opacity(0.25)
            ForgroundContextPane()
                .frame(width: UIScreen.main.bounds.width * forgroundPercentageWidth)
                .offset(x: (UIScreen.main.bounds.width / 2.0) * (1.0 - forgroundPercentageWidth))
        }
    }
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
