//
//  CVUImage.swift
//  memri
//
//  Created by Toby Brennan on 5/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI


enum CVU_SizingMode: String {
    case fill
    case fit
}

struct CVU_Image: View {
    var nodeResolver: UINodeResolver
    
 
    var body: some View {
        if let imageURI = nodeResolver.fileURI(for: "image"),
            let image = FileStorageController.getImage(fromFileForUUID: imageURI)
        {
            MemriImageView(image: image, fitContent: nodeResolver.sizingMode == .fit)
                .if(nodeResolver.sizingMode == .fit) {
                    $0.aspectRatio(image.aspectRatio, contentMode: .fit)
            }
        } else if let iconName = nodeResolver.string(for: "systemName") {
            Image(systemName: iconName)
                .renderingMode(.template)
        } else {
            Image(systemName: "questionmark")
                .renderingMode(.template)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}
