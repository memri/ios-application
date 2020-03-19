//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct RichTextEditor: UIViewRepresentable {
    @ObservedObject public var dataItem: DataItem

    class Coordinator: NSObject, UITextViewDelegate {
        var control: RichTextEditor

        init(_ control: RichTextEditor) {
            self.control = control
        }
        func textViewDidChange(_ textView: UITextView) {
            control.dataItem.properties["content"] = AnyCodable(textView.text)
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.contentInset = UIEdgeInsets(top: 5,left: 10, bottom: 5, right: 5)
        view.delegate = context.coordinator
        view.text = ((self.dataItem.properties["content"]?.value ?? "") as! String)
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
    func makeCoordinator() -> RichTextEditor.Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

}

struct RichTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        RichTextEditor(dataItem: DataItem.fromUid(uid: "0x01"))
    }
}
