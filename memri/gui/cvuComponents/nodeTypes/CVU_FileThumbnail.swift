//
// CVU_Image.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct CVU_FileThumbnail: View {
    var nodeResolver: UINodeResolver

    var fileURL: URL? {
        guard let fileURI = nodeResolver.fileURI(for: "file")
        else { return nil }
        return FileStorageController.getURLForFile(withUUID: fileURI)
    }
    
    var dimensions: CGSize {
        CGSize(width: max(30, nodeResolver.cgFloat(for: "width") ?? 100),
            height: max(30, nodeResolver.cgFloat(for: "width") ?? 100))
    }

    @ViewBuilder
    var body: some View {
        if let fileURL = fileURL {
            MemriFileThumbnailView(fileURL: fileURL, thumbnailDimensions: dimensions)
        } else {
            Image(systemName: "questionmark")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)
        }
    }
}
