//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI


struct TextView: UIViewRepresentable {
    @ObservedObject public var dataItem: DataItem

    class Coordinator: NSObject, UITextViewDelegate {
        var control: TextView

        init(_ control: TextView) {
            self.control = control
        }
        func textViewDidChange(_ textView: UITextView) {
            control.dataItem.properties["content"] = textView.text
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.contentInset = UIEdgeInsets(top: 5,left: 10, bottom: 5, right: 5)
        view.delegate = context.coordinator
        view.text = self.dataItem.properties["content"]
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
    func makeCoordinator() -> TextView.Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

}

struct TextEdit_Previews: PreviewProvider {
    static var previews: some View {
        TextView(dataItem: DataItem(uid: "0x01"))
    }
}
