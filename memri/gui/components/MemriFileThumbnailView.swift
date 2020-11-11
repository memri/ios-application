//
//  MemriFileThumbnailView.swift
//  memri
//
//  Created by T Brennan on 11/11/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine
import QuickLookThumbnailing

struct MemriFileThumbnailView: UIViewRepresentable {
    var fileURL: URL?
    var thumbnailDimensions: CGSize = .init(width: 80, height: 80)
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        context.coordinator.imageView = imageView
        context.coordinator.fileURL = fileURL
        context.coordinator.thumbSize = thumbnailDimensions
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        context.coordinator.fileURL = fileURL
    }
    
    class Coordinator {
        var imageView: UIImageView?
        
        var thumbSize: CGSize = .init(width: 80, height: 80)
        var fileURL: URL? {
            didSet {
                if fileURL != oldValue {
                    generateThumbnail()
                }
            }
        }
        private var thumbnailRequest: QLThumbnailGenerator.Request?
        private var thumbnailCancellable: AnyCancellable?
        
        func generateThumbnail() {
            guard let fileURL = fileURL else {
                thumbnailRequest.map { QLThumbnailGenerator.shared.cancel($0) }
                thumbnailCancellable?.cancel()
                thumbnailRequest = nil
                thumbnailCancellable = nil
                return
            }
            let scale = UIScreen.main.scale
            let request = QLThumbnailGenerator.Request(fileAt: fileURL,
                                                       size: thumbSize,
                                                       scale: scale,
                                                       representationTypes: .all)
            
            let generator = QLThumbnailGenerator.shared
            thumbnailRequest = request
            let thumbnailSubject = PassthroughSubject<UIImage?, Never>()
            
            thumbnailCancellable = thumbnailSubject
                .receive(on: DispatchQueue.main)
                .sink { image in
                    UIView.animate(withDuration: 0.2) {
                        self.imageView?.image = image
                    }
                }
            
            generator.generateRepresentations(for: request) { (thumbnail, type, error) in
                thumbnailSubject.send(thumbnail?.uiImage)
            }
        }
    }
}

struct MemriFileThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        MemriFileThumbnailView()
    }
}
