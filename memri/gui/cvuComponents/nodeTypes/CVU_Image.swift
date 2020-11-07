//
// CVU_Image.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

enum CVU_SizingMode: String {
    case fill
    case fit
}

struct CVU_Image: View {
    var nodeResolver: UINodeResolver

    var fileImageURL: URL? {
        guard let imageURI = nodeResolver.fileURI(for: "image")
        else { return nil }
        return FileStorageController.getURLForFile(withUUID: imageURI)
    }

    var bundleImage: UIImage? {
        guard let imageName = nodeResolver.string(for: "bundleImage"),
              let image = UIImage(named: imageName)
        else {
            return nil
        }
        return image
    }

    @ViewBuilder
    var body: some View {
        if let imageURL = fileImageURL {
            
            MemriImageView(imageURL: imageURL, fitContent: nodeResolver.sizingMode == .fit)
                .if(nodeResolver.sizingMode == .fit) {
                    $0.aspectRatio(MemriImageView.getAspectRatio(of: imageURL) ?? 1, contentMode: .fit)
                }
        }
        else if let bundleImage = bundleImage {
            Image(uiImage: bundleImage)
                .resizable()
                .if(nodeResolver.sizingMode == .fit) { $0.aspectRatio(contentMode: .fit) }
        }
        else if let iconName = nodeResolver.string(for: "systemName") {
            Image(systemName: iconName)
                .renderingMode(.template)
                .if(nodeResolver.bool(for: "resizable", defaultValue: false)) { $0.resizable() }
                .if(nodeResolver.sizingMode == .fit) { $0.aspectRatio(contentMode: .fit) }
        }
        else {
            Image(systemName: "questionmark")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)
        }
    }
}
