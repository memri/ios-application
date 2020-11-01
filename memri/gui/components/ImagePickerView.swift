//
// ImagePickerView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    var onCompletion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        switch sourceType {
        case .camera:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
            }
            else {
                picker.sourceType = .photoLibrary
            }
        default:
            picker.sourceType = sourceType
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let uiImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)

            parent.onCompletion(uiImage)

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
