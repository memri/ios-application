//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

private var register:Void = {
    Renderers.register(
        name: "richTextEditor",
        title: "Default",
        order: 0,
        icon: "pencil",
        view: AnyView(MapRendererView()),
        renderConfigType: CascadingRichTextEditorConfig.self,
        canDisplayResults: { items -> Bool in
            items.count > 0 && items.count == 1 && items[0] is Note
        }
    )
}()

class CascadingRichTextEditorConfig: CascadingRenderConfig {
    var type: String? = "richTextEditor"
}

struct _RichTextEditor: UIViewRepresentable {
    @ObservedObject public var dataItem: DataItem

    class Coordinator: NSObject, UITextViewDelegate {
        var control: _RichTextEditor

        init(_ control: _RichTextEditor) {
            self.control = control
        }
        
        func getRtfString(_ attributedText: NSAttributedString) -> String{
            let rtfOptions = [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtf]
            let rtfString: String
            do {
                let rtfData = try attributedText.data(from: NSRange(location: 0, length: attributedText.length),
                                                                documentAttributes: rtfOptions)
                
                rtfString = String(decoding: rtfData, as: UTF8.self)
            }
            catch {
                print("Cannot read rtfString from attributedText: \(attributedText)")
                rtfString = ""
            }
            return rtfString
        }
        
        func textViewDidChange(_ textView: UITextView) {
            control.dataItem.set("content", textView.attributedText.string)
            control.dataItem.set("rtfContent", getRtfString(textView.attributedText))
            
        }
    }
    
    func emptyAttributedContent() -> String{
        let escapedContent = self.dataItem.getString("content").replacingOccurrences(of: "\n", with: "\\n")
        let attributedContent = """
        {
        "text": "\(escapedContent)",
        "attributes": []
        }
        """
        return attributedContent
    }
    

    func makeUIView(context: Context) -> UITextView {

        // NOT SURE WHY THIS IS NEEDED, doesnt seem to do anything
        // It seems to be neede to allow the toolbar to fit in the textview
        let bounds = CGRect(x: 0, y: 0, width: 0, height: 600)
        
        let textView = LEOTextView(frame: bounds,
                                   textContainer: NSTextContainer())
                
        if let rtfContent = self.dataItem["rtfContent"] as? String{
            textView.setAttributedTextFromRtf(rtfContent)
        }else{
            textView.setAttributeTextWithJSONString(emptyAttributedContent())
        }
        
        textView.isScrollEnabled = true
        textView.contentInset = UIEdgeInsets(top: 5,left: 5, bottom: 5, right: 5)
        textView.delegate = context.coordinator
        _ = textView.enableToolbar()
        
        return textView
        
        
//        let view = UITextView()
//        view.isScrollEnabled = true
//        view.isEditable = true
//        view.isUserInteractionEnabled = true
//        view.contentInset = UIEdgeInsets(top: 5,left: 10, bottom: 5, right: 5)
//        view.delegate = context.coordinator
//        view.text = self.dataItem.getString("content")
//        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
    func makeCoordinator() -> _RichTextEditor.Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

}

struct RichTextRendererView: View {
    @EnvironmentObject var main: Main
    
    var renderConfig: CascadingRichTextEditorConfig
        = CascadingRichTextEditorConfig([], ViewArguments())

    var body: some View {
        let binding = Binding(
            // NOTE: Allowed for unwrapping
            get: { self.main.cascadingView.resultSet.singletonItem!.getString("title") },
            set: { self.main.cascadingView.resultSet.singletonItem!.set("title", $0) }
        )
        
        return VStack{
            if main.cascadingView.resultSet.singletonItem != nil {
                TextField("Daily Note", text: binding)
                    .padding(.horizontal, 10)
                    .padding(.top, 20)
                    .font(.headline)
                    .foregroundColor(.gray)
                    
                _RichTextEditor(dataItem: main.cascadingView.resultSet.singletonItem!)
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
