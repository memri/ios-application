//
// Search.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

struct Search: View {
    @EnvironmentObject var context: MemriContext
    @State var isEditing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "#efefef"))
            HStack {
                MemriTextField(value: Binding<String>(
                    get: { self.context.currentView?.filterText ?? "" },
                    set: { self.context.currentView?.filterText = $0 }
                ),
                               placeholder: context.currentView?.searchHint ?? "",
                               showPrevNextButtons: false)
                    .onEditingBegan {
                        self.isEditing = true
                    }
                    .onEditingEnded {
                        self.isEditing = false
                    }
                    .layoutPriority(-1)
                Text(context.currentView?.searchMatchText ?? "")

                ForEach(context.currentView?.filterButtons ?? [], id: \.self) { filterButton in
                    ActionButton(action: filterButton)
                        .font(Font.system(size: 20, weight: .medium))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 6)
        }
        .background(Color.white)
        .modifier(KeyboardModifier(enabled: isEditing))
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
