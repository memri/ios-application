//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct _RichTextEditor: UIViewRepresentable {
    @ObservedObject public var dataItem: DataItem

    class Coordinator: NSObject, UITextViewDelegate {
        var control: _RichTextEditor

        init(_ control: _RichTextEditor) {
            self.control = control
        }
        func textViewDidChange(_ textView: UITextView) {
            control.dataItem.set("content", textView.text ?? "")
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.contentInset = UIEdgeInsets(top: 5,left: 10, bottom: 5, right: 5)
        view.delegate = context.coordinator
        view.text = self.dataItem.getString("content")
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
    func makeCoordinator() -> _RichTextEditor.Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

}

struct RichTextRenderer: Renderer {
    //wrapper
    var renderConfig: RenderConfig=RenderConfig()
    @EnvironmentObject var main: Main

    var body: some View {
        return VStack{
                _RichTextEditor(dataItem: main.currentView.searchResult.data[0])
        }
    }
}

struct RichTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
