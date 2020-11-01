//
// ContextualBottomBar.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct ContextualBottomBar: View {
    @EnvironmentObject var context: MemriContext

    var shouldShow: Bool {
        ((context.currentView?.renderConfig as? ConfigurableRenderConfig)?
            .showContextualBarInEditMode ?? true)
            && context.editMode
    }

    var nonEmptySelection: Bool {
        !(context.currentView?.userState.get("selection", type: [Item].self)?.isEmpty ?? true)
    }

    @ViewBuilder
    var body: some View {
        if shouldShow {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    if context.editMode {
                        Button(action: {
                            withAnimation {
                                self.context.executeAction(ActionSelectAll(self.context))
                            }
                        }) {
                            Text("Select All")
                                .padding(5)
                        }
                    }
                    Spacer()
                    if context.editMode {
                        Button(action: {
                            withAnimation {
                                self.context.executeAction(ActionDelete(self.context))
                            }
                        }) {
                            Image(systemName: "trash")
                                .fixedSize()
                                .padding(5)
                                .foregroundColor(nonEmptySelection ? Color.red : Color.secondary)
                        }
                        .disabled(!nonEmptySelection)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
            }
            .font(.body)
            .background(Color(.secondarySystemBackground))
        }
    }
}

struct ContextualBottomBar_Previews: PreviewProvider {
    static var previews: some View {
        ContextualBottomBar()
    }
}
