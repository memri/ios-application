//
// RichTextToolbar.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct RichTextToolbarView: View {
    weak var textView: MemriTextEditor_UIKit?

    var state_bold: Bool = false
    var state_italic: Bool = false
    var state_underline: Bool = false
    var state_strikethrough: Bool = false

    var onPress_bold: () -> Void = {}
    var onPress_italic: () -> Void = {}
    var onPress_underline: () -> Void = {}
    var onPress_strikethrough: () -> Void = {}
    var onPress_indent: () -> Void = {}
    var onPress_outdent: () -> Void = {}
    var onPress_orderedList: () -> Void = {}
    var onPress_unorderedList: () -> Void = {}

    var body: some View {
        let insetDivider = Divider().padding(.vertical, 8)
        // ScrollView(.horizontal) {
        return VStack(spacing: 0) {
            Divider()
            GeometryReader { _ in
                // ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    Group {
                        self.button(
                            icon: Image(systemName: "bold"),
                            action: self.onPress_bold,
                            highlighted: self.state_bold
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "italic"),
                            action: self.onPress_italic,
                            highlighted: self.state_italic
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "underline"),
                            action: self.onPress_underline,
                            highlighted: self.state_underline
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "strikethrough"),
                            action: self.onPress_strikethrough,
                            highlighted: self.state_strikethrough
                        )
                    }
                    Divider()
                    Divider()
                    Group {
                        self.button(
                            icon: Image(systemName: "list.bullet"),
                            action: self.onPress_unorderedList,
                            highlighted: false
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "list.number"),
                            action: self.onPress_orderedList,
                            highlighted: false
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "decrease.indent"),
                            action: self.onPress_outdent
                        )
                        insetDivider
                        self.button(
                            icon: Image(systemName: "increase.indent"),
                            action: self.onPress_indent
                        )
                    }
                    Divider()
                    Spacer()

                    #if !targetEnvironment(macCatalyst)
                        Divider()
                        self.button(icon:
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundColor(Color(.label)),
                                    action: {
                                self.textView?.resignFirstResponder()
            })
                    #endif
                }
                .padding(.horizontal, 4)
            }
            #if targetEnvironment(macCatalyst)
                Divider()
            #endif
        }
        .frame(minHeight: 40, idealHeight: 40, maxHeight: 60)
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    func button<Label: View>(
        icon: Label,
        action: @escaping () -> Void,
        highlighted: Bool = false
    ) -> some View {
        Button(action: action) {
            icon
                .frame(minWidth: 30, minHeight: 36)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(highlighted ? Color(.tertiarySystemBackground) : .clear))
                .contentShape(Rectangle())
        }
    }
}

struct RichTextToolbar_Previews: PreviewProvider {
    static var previews: some View {
        RichTextToolbarView(state_italic: true)
    }
}
