//
// MemriImageView.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct MemriImageView: View {
    var imageURI: String?
    var fitContent: Bool = true
    var forceAspect: Bool = false

    var image: UIImage? {
        imageURI.flatMap { FileStorageController.getImage(fromFileForUUID: $0) }
    }

    @ViewBuilder
    var body: some View {
        image.map { image in
            MemriImageView_Internal(image: image, fitContent: fitContent)
                .if(forceAspect) {
                    $0.aspectRatio(image.aspectRatio, contentMode: .fit)
                }
        }
        if image == nil {
            Image(systemName: "questionmark")
                .renderingMode(.template)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}

private struct MemriImageView_Internal: UIViewRepresentable {
    var image: UIImage
    var fitContent: Bool = true

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = fitContent ? .scaleAspectFit : .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        if imageView.image != image {
            imageView.image = image
        }
        imageView.contentMode = fitContent ? .scaleAspectFit : .scaleAspectFill
    }
}
