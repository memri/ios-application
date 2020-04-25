//
//  Search.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct Search: View {
    @EnvironmentObject var main: Main

    var body: some View {
        VStack{
            Divider().background(Color(hex: "#efefef"))
            HStack{
                TextField("type your search query here", text: $main.computedView.filterText)
                
                ForEach(self.main.computedView.filterButtons){ filterButton in
                    Action(action: filterButton)
                        .font(Font.system(size: 20, weight: .medium))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            
            if self.main.currentSession.showFilterPanel {
                FilterPanel()
            }
        }
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
