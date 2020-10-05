//
// Search.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var context: MemriContext
    @Binding var isActive: Bool

    @ViewBuilder
    var body: some View {
        if isActive {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.systemFill))
                    MemriTextField(
                        value: Binding<String>(
                            get: { self.context.currentView?.filterText ?? "" },
                            set: { self.context.currentView?.filterText = $0 }
                        ),
                        placeholder: context.currentView?.searchHint ?? "",
                        clearButtonMode: .always,
                        showPrevNextButtons: false,
                        isEditing: $isActive
                    )
                    .onEditingEnded {
                        self.isActive = false
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
            }
            .background(Color.white)
            .modifier(KeyboardModifier())
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .transition(.opacity)
        }
    }
}
