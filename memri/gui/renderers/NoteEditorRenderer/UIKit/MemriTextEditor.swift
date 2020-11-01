//
//  TextEditorView.swift
//  RichTextEditor
//
//  Created by Toby Brennan on 22/6/20.
//  Copyright © 2020 ApptekStudios. All rights reserved.
//

import Foundation
import SwiftUI

struct MemriTextEditor: UIViewRepresentable {
    var model: () -> MemriTextEditorModel
    var onModelUpdate: (MemriTextEditorModel) -> Void
    var imageSelectionHandler: MemriTextEditorImageSelectionHandler?
    var fileHandler: MemriTextEditorFileHandler?
    var searchTerm: String?
    var isEditing: Binding<Bool>?
    
    func makeUIView(context: Context) -> MemriTextEditor_UIKitWrapper {
        let view = MemriTextEditor_UIKit(initialModel: model())
        view.onModelUpdate = onModelUpdate
        view.imageSelectionHandler = imageSelectionHandler
        view.fileHandler.fileHandler = fileHandler
        view.searchTerm = searchTerm?.nilIfBlankOrSingleLine
        return MemriTextEditor_UIKitWrapper(view)
    }
    
    func updateUIView(_ wrapper: MemriTextEditor_UIKitWrapper, context: Context) {
        wrapper.textEditor.onModelUpdate = onModelUpdate
        wrapper.textEditor.searchTerm = searchTerm?.nilIfBlankOrSingleLine
        wrapper.textEditor.isEditingBinding = isEditing
    }
}
