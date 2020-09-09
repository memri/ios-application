//
// ContextualBottomBar.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject var context: MemriContext
    
    var onSearchPressed: () -> Void
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                Button(action: onSearchPressed) {
                    Image(systemName: "magnifyingglass")
                        .padding(10)
                        .contentShape(Rectangle())
                }
                Spacer()
                ForEach(context.currentView?.filterButtons ?? [], id: \.transientUID) { filterButton in
                    ActionButton(action: filterButton)
                }
            }
            .padding(.horizontal, 10)
            .font(Font.system(size: 20, weight: .medium))
            .background(Color(.secondarySystemBackground).edgesIgnoringSafeArea(.bottom))
        }
    }
}
