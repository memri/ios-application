//
// MemriTextEditor_Toolbar.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct MemriTextEditor_Toolbar: View {
    weak var textView: MemriTextEditor_UIKit?

    enum Item {
        case button(
            label: String,
            icon: AnyView,
            hideInactive: Bool = false,
            isActive: Bool = false,
            onPress: () -> Void
        )
        case label(AnyView)
        case divider

        var view: AnyView {
            switch self {
            case let .button(label, icon, hideInactive, isActive, onPress):
                return AnyView(
                    Group {
                        if hideInactive && !isActive {
                            EmptyView()
                        }
                        else {
                            Button(action: onPress) {
                                icon
                                    .frame(minWidth: 30, minHeight: 36)
                                    .background(RoundedRectangle(cornerRadius: 4)
                                        .fill((isActive && !hideInactive) ?
                                            Color(.tertiarySystemBackground) : .clear))
                                    .contentShape(Rectangle())
                                    .accessibility(hint: Text(label))
                            }
                        }
                    }
                )
            case let .label(view):
                return view
            case .divider:
                return AnyView(Divider().padding(.vertical, 8))
            }
        }
    }

    var items: [Item]
    var showBackButton: Bool
    var onBackButton: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: 2) {
                        if showBackButton {
                            Button(action: onBackButton) {
                                Image(systemName: "arrowshape.turn.up.left.circle")
                                    .foregroundColor(Color(.label))
                                    .frame(minWidth: 30, minHeight: 36)
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                                    .accessibility(hint: Text("Back"))
                            }
                            Divider()
                                .padding(.trailing, 8)
                        }
                        ForEach(self.items.indexed(), id: \.index) { item in
                            item.view
                        }
                    }
                    .padding(.horizontal, self.padding)
                }

                #if !targetEnvironment(macCatalyst)
                    Divider()
                    Button(action: { self.textView?.resignFirstResponder() }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(Color(.label))
                            .frame(minWidth: 30, minHeight: 36)
                            .padding(.horizontal, 10)
                            .contentShape(Rectangle())
                            .accessibility(hint: Text("Close Keyboard"))
                    }
                #endif
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            #if targetEnvironment(macCatalyst)
                Divider()
            #endif
        }
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    var padding: CGFloat {
        #if targetEnvironment(macCatalyst)
            return 15
        #else
            return 4
        #endif
    }
}
