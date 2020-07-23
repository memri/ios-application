//
// RichTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct _RichTextEditor: View {
    @EnvironmentObject var context: MemriContext

    var htmlContentBinding: Binding<String?>?
    var plainContentBinding: Binding<String?>
    var titleBinding: Binding<String?>?
    var titleHint: String?

    var fontSize: CGFloat = 18
    var headingFontSize: CGFloat = 26

    var editModeBinding: Binding<Bool> {
        Binding<Bool>(get: { self.context.currentSession?.editMode ?? false },
                      set: { self.context.currentSession?.editMode = $0 })
    }

    let filterText: Binding<String>

    var body: some View {
        VStack(spacing: 0) {
            MemriTextEditor(
                initialContentHTML: htmlContentBinding?.wrappedValue ?? plainContentBinding
                    .wrappedValue,
                titleBinding: titleBinding,
                titlePlaceholder: titleHint,
                fontSize: fontSize,
                headingFontSize: headingFontSize,
                isEditing: editModeBinding,
                preferredHeight: nil,
                onTextChanged: { newAttributedString in
                    self.htmlContentBinding?.wrappedValue = newAttributedString.toHTML()
                    self.plainContentBinding.wrappedValue = newAttributedString.string
                }
            )
        }
    }
}
