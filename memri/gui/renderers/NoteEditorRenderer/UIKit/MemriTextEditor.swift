//
// MemriTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct MemriTextEditor: UIViewRepresentable {
    var model: () -> MemriTextEditorModel
    var onModelUpdate: (MemriTextEditorModel) -> Void
    var imageSelectionHandler: MemriTextEditorImageSelectionHandler?
    var fileHandler: MemriTextEditorFileHandler?
    var searchTerm: String?
    var isEditing: Binding<Bool>?

    func makeUIView(context: Context) -> MemriTextEditor_UIKit {
        let view = MemriTextEditor_UIKit(initialModel: model())
        view.onModelUpdate = onModelUpdate
        view.imageSelectionHandler = imageSelectionHandler
        view.fileSchemeHandler?.fileHandler = fileHandler
        view.searchTerm = searchTerm?.nilIfBlankOrSingleLine
        return view
    }

    func updateUIView(_ textEditor: MemriTextEditor_UIKit, context: Context) {
        textEditor.onModelUpdate = onModelUpdate
        textEditor.searchTerm = searchTerm?.nilIfBlankOrSingleLine
        textEditor.isEditingBinding = isEditing
    }
}
