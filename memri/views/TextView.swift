//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI


struct TextView: UIViewRepresentable {
    @ObservedObject public var note: Note

    class Coordinator: NSObject, UITextViewDelegate {
        var control: TextView

        init(_ control: TextView) {
            self.control = control
        }
        func textViewDidChange(_ textView: UITextView) {
            control.note.text = textView.text
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.contentInset = UIEdgeInsets(top: 5,left: 10, bottom: 5, right: 5)
        view.delegate = context.coordinator
        view.text = self.note.text
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
        TextView(note: DataStore().data[0])
    }
}
