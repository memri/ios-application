//
// ContextualBottomBar.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject var context: MemriContext
    
    var onSearchPressed: () -> Void
    
    var currentFilter: String? {
        context.currentView?.filterText?.nilIfBlankOrSingleLine
    }
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 4) {
                HStack(spacing: 4) {
                    Button(action: onSearchPressed) {
                        HStack(spacing: 0) {
                            Image(systemName: "magnifyingglass")
                                .padding(.trailing, 7)
                            if let filter = currentFilter {
                                Text(filter).font(.caption)
                                    .foregroundColor(Color(.label))
                            }
                        }
                        .padding([.leading, .vertical], 10)
                        .contentShape(Rectangle())
                    }
                    if currentFilter != nil {
                        Button {
                            context.currentView?.filterText = ""
                        } label: {
                            Image(systemName: "clear")
                                .foregroundColor(Color(.label))
                                .font(.caption)
                        }
                        
                    }
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
