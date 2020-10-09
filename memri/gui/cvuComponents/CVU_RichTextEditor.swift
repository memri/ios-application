//
//  CVU_Text.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_RichTextEditor: View {
    var nodeResolver: UINodeResolver
    var editModeBinding: Binding<Bool>
    var searchTerm: String?
    
    
    var titleBinding: Binding<String?>? {
        nodeResolver.binding(for: "title")
    }
    
    var contentBinding: Binding<String> {
        nodeResolver.binding(for: "content", defaultValue: "")
    }
    
    var itemID: Int?
    
    var body: some View {
        MemriTextEditor(model: MemriTextEditorModel(title: titleBinding?.wrappedValue, body: contentBinding.wrappedValue),
                        onModelUpdate: { (model) in
                            titleBinding?.wrappedValue = model.title
                            contentBinding.wrappedValue = model.body
                        },
                        fileHandler: itemID.map { MemriNotesFileHandler(noteID: $0) },
                        searchTerm: searchTerm,
                        isEditing: editModeBinding
        )
    }
    
}
