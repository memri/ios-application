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
    @EnvironmentObject var main: MemriContext

    var body: some View {
        VStack{
            Divider().background(Color(hex: "#efefef"))
            HStack{
                TextField(main.cascadingView.searchHint,
                          text: $main.cascadingView.filterText)
                Text(main.cascadingView.searchMatchText)
                
                ForEach(main.cascadingView.filterButtons, id: \.self){ filterButton in
                    ActionButton(action: filterButton)
                        .font(Font.system(size: 20, weight: .medium))
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 5)
            .padding(.bottom, 5)
            
            if self.main.currentSession.showFilterPanel {
                FilterPanel()
            }
        }
        .background(Color.white)
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
