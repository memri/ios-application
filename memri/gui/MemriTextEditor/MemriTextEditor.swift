//
// MemriTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct MemriTextEditor: UIViewRepresentable {
    init(
        initialContentHTML: String? = nil,
        titleBinding: Binding<String?>? = nil,
        titlePlaceholder: String? = nil,
        fontSize: CGFloat = 18,
        headingFontSize: CGFloat = 26,
        isEditing: Binding<Bool>? = nil,
        preferredHeight: Binding<CGFloat>? = nil,
        onTextChanged: ((NSAttributedString) -> Void)? = nil
    ) {
        self.initialContentHTML = initialContentHTML
        self.titleBinding = titleBinding
        self.titlePlaceholder = titlePlaceholder
        self.fontSize = fontSize
        self.headingFontSize = headingFontSize
        self.isEditing = isEditing
        self.preferredHeight = preferredHeight
        self.onTextChanged = onTextChanged
    }

    var initialContentHTML: String?
    var titleBinding: Binding<String?>?
    var titlePlaceholder: String?
    var fontSize: CGFloat
    var headingFontSize: CGFloat
    var isEditing: Binding<Bool>?
    var preferredHeight: Binding<CGFloat>?
    var onTextChanged: ((NSAttributedString) -> Void)?

    public func makeUIView(context _: Context) -> MemriTextEditorWrapper_UIKit {
        MemriTextEditorWrapper_UIKit(
            MemriTextEditor_UIKit(initialContentHTML: initialContentHTML,
                                  titleBinding: titleBinding,
                                  titlePlaceholder: titlePlaceholder,
                                  fontSize: fontSize,
                                  headingFontSize: headingFontSize)
        )
    }

    public func updateUIView(_ wrapper: MemriTextEditorWrapper_UIKit, context _: Context) {
        wrapper.textEditor.titleBinding = titleBinding
        wrapper.textEditor.preferredHeightBinding = preferredHeight
        wrapper.textEditor.onTextChanged = onTextChanged
        wrapper.textEditor.fontSize = fontSize
        wrapper.textEditor.isEditingBinding = isEditing
    }
}
