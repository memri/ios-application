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

struct RichTextRendererView: View {
    @EnvironmentObject var main: Main
    
    //wrapper
    var renderConfig: RenderConfig = RenderConfig()

    var body: some View {
        return VStack{
            if main.computedView.resultSet.exampleItem != nil {
                _RichTextEditor(dataItem: main.computedView.resultSet.exampleItem!)
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
