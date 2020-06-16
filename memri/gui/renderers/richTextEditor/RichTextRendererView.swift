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

struct _RichTextEditor: UIViewRepresentable {
    @EnvironmentObject var main: Main
    @ObservedObject public var dataItem: DataItem
    
    let filterText: Binding<String>

    class Coordinator: NSObject, UITextViewDelegate {
        var control: _RichTextEditor

        init(_ control: _RichTextEditor) {
            self.control = control
        }
        
        func getRtfString(_ attributedText: NSAttributedString) -> String{
            let rtfOptions = [NSAttributedString.DocumentAttributeKey.documentType :
                              NSAttributedString.DocumentType.rtf]
            let rtfData = try! attributedText.data(from: NSRange(location: 0,
                                                                 length: attributedText.length),
                                                                 documentAttributes: rtfOptions)
            
            let rtfString = String(decoding: rtfData, as: UTF8.self)
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
                
        if let rtfContent = self.dataItem["rtfContent"]{
            textView.setAttributedTextFromRtf(rtfContent as! String)
        }else{
            textView.setAttributeTextWithJSONString(emptyAttributedContent())
        }
        
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
        
        if main.computedView.filterText != ""{
            search(LEOTextView)
        }else{
            self.main.computedView.searchMatchText = ""
        }
        
        // TODO: This is currently necessary to trigger a UI update *when the filterText
        // **Becomes** empty or safeAddAtributes is not called*, I have no idea why
        LEOTextView.nck_textStorage.safeAddAttributes([.foregroundColor: UIColor.black],
                                                      range: NSMakeRange(0, 1))
    }
    
    
    func search(_ textView: LEOTextView){
        let regex = try! NSRegularExpression(pattern: main.computedView.filterText,
                                             options: .caseInsensitive)
        let searchString = textView.nck_textStorage.currentString.string

        let searchRange = NSRange(location: 0, length: searchString.utf16.count)
        let matches = regex.matches(in: searchString,range: searchRange) as [NSTextCheckingResult]
        
        self.main.computedView.searchMatchText = "(" + String(matches.count) + ") matches"
        
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
        let binding = Binding(
            get: { self.main.computedView.resultSet.singletonItem!.getString("title") },
            set: { self.main.computedView.resultSet.singletonItem!.set("title", $0) }
        )
        
        return VStack{
            if main.computedView.resultSet.singletonItem != nil {
                TextField("Daily Note", text: binding)
                    .padding(.horizontal, 10)
                    .padding(.top, 20)
                    .font(.headline)
                    .foregroundColor(.gray)
                    
                _RichTextEditor(dataItem: main.computedView.resultSet.singletonItem!,
                                filterText: $main.computedView.filterText)
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
