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
    
    
    var fontSize: CGFloat { nodeResolver.cgFloat(for:"fontSize") ?? 18 }
    var titleHint: String? { nodeResolver.string(for: "titleHint")?.nilIfBlank }
    var titleFontSize: CGFloat { nodeResolver.cgFloat(for:"titleFontSize") ?? 24 }
    
    var titleBinding: Binding<String?>? {
        nodeResolver.binding(for: "title")
    }
    
    var contentBinding: Binding<String> {
        nodeResolver.binding(for: "content", defaultValue: "")
    }
    
    var body: some View {
        MemriTextEditor(contentHTMLBinding: contentBinding,
                        titleBinding: titleBinding,
                        titlePlaceholder: titleHint,
                        fontSize: fontSize,
                        headingFontSize: titleFontSize,
                        backgroundColor: nil,
                        isEditing: editModeBinding)
    }
    
}
