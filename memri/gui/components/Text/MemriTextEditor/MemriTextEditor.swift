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
    var model: MemriTextEditorModel = MemriTextEditorModel(title: "Demo note",
                                                 body: "<p><strong>Hi there,</strong></p><p>Let’s explore the <u>new</u> text editor.</p><p></p><ul> <li><p>This is a list</p></li> <li><p>You can press return to make a new item</p>  <ul>   <li><p>Indented item</p></li>   <li><p><s>Something else</s></p></li>  </ul></li></ul><p></p><p>Or an ordered list:</p><ol> <li><p>Milk</p></li> <li><p>Eggs</p></li> <li><p>Flour</p>  <ol>   <li><p>Self-raising</p></li>   <li><p>Plain</p></li>  </ol></li></ol><p></p><p>It also supports code blocks:</p><pre><code>def some_function(argument):    return \"Automatic code highlighting!\"</code></pre><p></p><p><strong>Memri:</strong> truly yours</p><p></p><p></p>")
    var onModelUpdate: (MemriTextEditorModel) -> Void
    var fileHandler: MemriTextEditorFileHandler?
    var searchTerm: String?
    var isEditing: Binding<Bool>?
    
    func makeUIView(context: Context) -> MemriTextEditor_UIKitWrapper {
        let view = MemriTextEditor_UIKit(initialModel: model)
        view.onModelUpdate = onModelUpdate
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
