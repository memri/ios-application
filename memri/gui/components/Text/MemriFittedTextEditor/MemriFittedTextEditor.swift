//
// MemriFittedTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

// Intended for use in message composer. Will self-adjust size as needed
public struct MemriFittedTextEditor: View {
    var contentBinding: Binding<String?>
    var placeholder: String?
    
    var fontSize: CGFloat = 18
    var backgroundColor: ColorDefinition?
    var isEditing: Binding<Bool>?
    
    
    @State private var preferredHeight: CGFloat = 0


    var displayHeight: CGFloat {
        let minHeight: CGFloat = 30
        let maxHeight: CGFloat = 150

        return min(max(minHeight, preferredHeight), maxHeight)
    }

    public var body: some View {
        MemriFittedTextEditor_Inner(textContent: contentBinding.wrappedValue,
                                    fontSize: fontSize,
                                    isEditing: isEditing,
                                    preferredHeight: $preferredHeight,
                                    onTextChanged: { newText in
                                        DispatchQueue.main.async {
                                            self.contentBinding.wrappedValue = newText
                                        }
        })
            .background(placeholderView)
            .background(backgroundColor?.color ?? Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .frame(height: displayHeight)
    }
    
    @ViewBuilder
    var placeholderView: some View {
        if contentBinding.wrappedValue?.nilIfBlankOrSingleLine == nil {
            placeholder.map {
                Text($0)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
            }
        }
    }
}


public struct MemriFittedTextEditor_Inner: UIViewRepresentable {
    init(
        textContent: String? = nil,
        fontSize: CGFloat = 18,
        isEditing: Binding<Bool>? = nil,
        preferredHeight: Binding<CGFloat>? = nil,
        onTextChanged: ((String) -> Void)? = nil
    ) {
        self.textContent = textContent
        self.fontSize = fontSize
        self.isEditing = isEditing
        self.preferredHeight = preferredHeight
        self.onTextChanged = onTextChanged
    }
    
    var textContent: String?
    var fontSize: CGFloat
    var isEditing: Binding<Bool>?
    var preferredHeight: Binding<CGFloat>?
    var onTextChanged: ((String) -> Void)?
    
    public func makeUIView(context _: Context) -> MemriFittedTextEditorWrapper_UIKit {
        MemriFittedTextEditorWrapper_UIKit(
            MemriFittedTextEditor_UIKit(textContent: textContent,
                                  fontSize: fontSize,
                                  backgroundColor: ColorDefinition.system(.clear))
        )
    }
    
    public func updateUIView(_ wrapper: MemriFittedTextEditorWrapper_UIKit, context _: Context) {
        wrapper.textEditor.updateTextIfNotEditing(textContent)
        wrapper.textEditor.preferredHeightBinding = preferredHeight
        wrapper.textEditor.onTextChanged = onTextChanged
        wrapper.textEditor.fontSize = fontSize
        wrapper.textEditor.isEditingBinding = isEditing
    }
}
