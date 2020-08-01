//
// MemriTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct MemriTextEditor: UIViewRepresentable {
    init(
        contentHTMLBinding: Binding<String>,
        titleBinding: Binding<String?>? = nil,
        titlePlaceholder: String? = nil,
        fontSize: CGFloat = 18,
        headingFontSize: CGFloat = 26,
        backgroundColor: ColorDefinition? = nil,
        isEditing: Binding<Bool>? = nil,
        onContentChanged: ((String) -> Void)? = nil
    ) {
        self.contentHTMLBinding = contentHTMLBinding
        self.titleBinding = titleBinding
        self.titlePlaceholder = titlePlaceholder
        self.fontSize = fontSize
        self.headingFontSize = headingFontSize
        self.backgroundColor = backgroundColor
        self.isEditing = isEditing
        self.onContentChanged = onContentChanged
    }

    var contentHTMLBinding: Binding<String>
    var titleBinding: Binding<String?>?
    var titlePlaceholder: String?
    var fontSize: CGFloat
    var headingFontSize: CGFloat
    var isEditing: Binding<Bool>?
    var onContentChanged: ((String) -> Void)?
    var backgroundColor: ColorDefinition?

    public func makeUIView(context _: Context) -> MemriTextEditorWrapper_UIKit {
        MemriTextEditorWrapper_UIKit(
            MemriTextEditor_UIKit(initialContentHTML: contentHTMLBinding.wrappedValue,
                                  titleBinding: titleBinding,
                                  titlePlaceholder: titlePlaceholder,
                                  fontSize: fontSize,
                                  headingFontSize: headingFontSize,
                                  backgroundColor: backgroundColor)
        )
    }

    public func updateUIView(_ wrapper: MemriTextEditorWrapper_UIKit, context _: Context) {
        wrapper.textEditor.titleBinding = titleBinding
        wrapper.textEditor.onTextChanged = { attribString in
            let htmlString = attribString.toHTML()
            self.contentHTMLBinding.wrappedValue = htmlString ?? ""
            self.onContentChanged?(htmlString ?? "")
        }
        wrapper.textEditor.fontSize = fontSize
        wrapper.textEditor.isEditingBinding = isEditing
    }
}
