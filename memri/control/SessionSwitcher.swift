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

    var body: some View {
        ZStack {
            if self.main.showSessionSwitcher {
                
            }
        }
    }
}

struct SessionSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
