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

let registerRichText = {
    Renderers.register(
        name: "richTextEditor",
        title: "Default",
        order: 0,
        icon: "pencil",
        view: AnyView(RichTextRendererView()),
        renderConfigType: CascadingRichTextEditorConfig.self,
        canDisplayResults: { items -> Bool in
            items.count > 0 && items.count == 1 && items[0] is Note
        }
    )
}

class CascadingRichTextEditorConfig: CascadingRenderConfig {
    var type: String? = "richTextEditor"
}

struct _RichTextEditor: UIViewRepresentable {
    @EnvironmentObject var context: MemriContext
    @ObservedObject public var dataItem: DataItem
    
    let filterText: Binding<String>

    class Coordinator: NSObject, UITextViewDelegate {
        var control: _RichTextEditor

        init(_ control: _RichTextEditor) {
            self.control = control
        }
        
        func getHTMLString(_ attributedText: NSAttributedString) -> String{
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
            control.dataItem.set("content", textView.attributedText.toHTML())
            control.dataItem.set("textContent", textView.attributedText.string)
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
        
        textView.setAttributedString(self.dataItem["content"] as? String,
                                     self.dataItem["textContent"] as? String)
        
        
        textView.isScrollEnabled = true
        textView.contentInset = UIEdgeInsets(top: 5,left: 5, bottom: 5, right: 5)
        textView.delegate = context.coordinator
        _ = textView.enableToolbar()
        
        return textView
    }
    
    func removeAllHighlighting(_ leoView: inout LEOTextView){
        let fullTextRange = NSMakeRange(0, leoView.nck_textStorage.currentString.length)
        leoView.nck_textStorage.currentString.removeAttribute(.backgroundColor,
                                                                  range: fullTextRange)
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        
        var LEOTextView = textView as! LEOTextView
        // TODO: we should probably only do this when the filterText changed
        removeAllHighlighting(&LEOTextView)
        
        if self.context.cascadingView.filterText != ""{
            search(LEOTextView)
        }
        else{
            self.context.cascadingView.searchMatchText = ""
        }
        
        // TODO: This is currently necessary to trigger a UI update *when the filterText
        // **Becomes** empty or safeAddAtributes is not called*, I have no idea why
        LEOTextView.nck_textStorage.safeAddAttributes([.foregroundColor: UIColor.black],
                                                      range: NSMakeRange(0, 1))
    }
    
    
    func search(_ textView: LEOTextView){
        do {
            let regex = try NSRegularExpression(pattern: context.cascadingView.filterText,
                                                options: .caseInsensitive)
        
            let searchString = textView.nck_textStorage.currentString.string
            let searchRange = NSRange(location: 0, length: searchString.utf16.count)
            let matches = regex.matches(in: searchString,range: searchRange) as [NSTextCheckingResult]
            
            self.context.cascadingView.searchMatchText = "(" + String(matches.count) + ") matches"
            
            // TODO: set cursor to new position: this is probably challenging as it has to defocus from
            // the searcharea. We could do something like this
    //        if let newPosition = textView.position(from: matches[0], offset: 0) {
    //           textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
    //        }
                    
            for match in matches {
                textView.nck_textStorage.safeAddAttributes([.backgroundColor: UIColor.systemGray3],
                                                              range: match.range)
            }
        }
        catch let error {
            debugHistory.warn("Regex error: \(error)")
            return
        }
    }
    func makeCoordinator() -> _RichTextEditor.Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

}

struct RichTextRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var renderConfig: CascadingRichTextEditorConfig
        = CascadingRichTextEditorConfig([], ViewArguments())

    var body: some View {
        let dataItem = self.context.cascadingView.resultSet.singletonItem
        let binding = Binding(
            get: { dataItem?.getString("title") ?? "" },
            set: {
                dataItem?.set("title", $0)
            }
        )
        
        return VStack{
            if context.cascadingView.resultSet.singletonItem != nil {
                TextField("Daily Note", text: binding)
                    .padding(.horizontal, 10)
                    .padding(.top, 20)
                    .font(.headline)
                    .foregroundColor(.gray)
                    
                _RichTextEditor(dataItem: dataItem!,
                                filterText: $context.cascadingView.filterText)
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
