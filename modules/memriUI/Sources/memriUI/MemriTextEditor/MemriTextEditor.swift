//
//  File.swift
//  
//
//

import Foundation
import SwiftUI

public struct MemriTextEditor: UIViewRepresentable {
    var initialContentHTML: String?
    var preferredHeight: Binding<CGFloat>?
    var onTextChanged: ((NSAttributedString) -> Void)?
    var defaultFontSize: CGFloat = 18
    var isEditing: Binding<Bool>?
    
    public init(initialContentHTML: String? = nil, isEditing: Binding<Bool>? = nil, preferredHeight: Binding<CGFloat>? = nil, onTextChanged: ((NSAttributedString) -> Void)? = nil) {
        self.initialContentHTML = initialContentHTML
        self.isEditing = isEditing
        self.preferredHeight = preferredHeight
        self.onTextChanged = onTextChanged
    }
    
    public func makeUIView(context: Context) -> MemriTextEditorWrapper_UIKit {
        MemriTextEditorWrapper_UIKit(
            MemriTextEditor_UIKit(initialContentHTML: initialContentHTML)
        )
    }
    
    
    public func updateUIView(_ wrapper: MemriTextEditorWrapper_UIKit, context: Context) {
        wrapper.textEditor.preferredHeightBinding = preferredHeight
        wrapper.textEditor.onTextChanged = onTextChanged
        wrapper.textEditor.defaultFontSize = defaultFontSize
        wrapper.textEditor.isEditingBinding = isEditing
    }
}
