//
//  File.swift
//  
//
//

import Foundation
import SwiftUI

public struct MemriTextEditor: UIViewRepresentable {
    var initialContent: NSAttributedString
    var preferredHeight: Binding<CGFloat>?
    var onTextChanged: ((NSAttributedString) -> Void)?
    
    public init(initialContent: NSAttributedString = .init(), preferredHeight: Binding<CGFloat>? = nil, onTextChanged: ((NSAttributedString) -> Void)? = nil) {
        self.initialContent = initialContent
        self.preferredHeight = preferredHeight
        self.onTextChanged = onTextChanged
    }
    
    public func makeUIView(context: Context) -> MemriTextEditor_UIKit {
        MemriTextEditor_UIKit(initialContent: initialContent)
    }
    
    
    public func updateUIView(_ textEditor: MemriTextEditor_UIKit, context: Context) {
        textEditor.preferredHeightBinding = preferredHeight
        textEditor.onTextChanged = onTextChanged
    }
}
