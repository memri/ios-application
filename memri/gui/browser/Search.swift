//
//  Search.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import memriUI
import Combine

struct Search: View {
    @EnvironmentObject var context: MemriContext
    @ObservedObject var keyboard = KeyboardResponder()

    var body: some View {
        VStack{
            Divider().background(Color(hex: "#efefef"))
            HStack{
                MemriTextField(value: $context.cascadingView.filterText, placeholder: context.cascadingView.searchHint)
                    .layoutPriority(-1)
                Text(context.cascadingView.searchMatchText)
                
                ForEach(context.cascadingView.filterButtons, id: \.self){ filterButton in
                    ActionButton(action: filterButton)
                        .font(Font.system(size: 20, weight: .medium))
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 5)
            .padding(.bottom, 5)
            
            if self.context.currentSession.showFilterPanel {
                FilterPanel()
            }
        }
        .background(Color.white)
        .offset(x: 0, y: -keyboard.currentHeight)
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
