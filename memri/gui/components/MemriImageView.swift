//
//  MemriImageView.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct MemriImageView: UIViewRepresentable {
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
