//
// MemriImageView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct MemriImageView: UIViewRepresentable {
    var imageURL: URL
    var fitContent: Bool = true
 
    func makeUIView(context: Context) -> MemriImageView_UIKit {
        let imageView = MemriImageView_UIKit()
        imageView.localURL = imageURL
        imageView.contentMode = fitContent ? .scaleAspectFit : .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }

    func updateUIView(_ imageView: MemriImageView_UIKit, context: Context) {
        imageView.localURL = imageURL
        imageView.contentMode = fitContent ? .scaleAspectFit : .scaleAspectFill
    }
    
    static func getDimensions(of url: URL) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
              let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as String] as! CFNumber?,
              let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as String] as! CFNumber?
        else {
            return nil
        }
        var width: CGFloat = 0, height: CGFloat = 0
        CFNumberGetValue(pixelWidth, .cgFloatType, &width)
        CFNumberGetValue(pixelHeight, .cgFloatType, &height)
        return CGSize(width: width, height: height)
    }
    
    static func getAspectRatio(of url: URL) -> CGFloat? {
        guard let dimensions = getDimensions(of: url),
              dimensions.width != 0,
              dimensions.height != 0
        else { return nil }
        return dimensions.width / dimensions.height
    }
}

import Combine
class MemriImageView_UIKit: UIImageView {
    var localURL: URL? {
        didSet {
            loadFromLocalURL(localURL)
        }
    }
    private var loadedURL: URL?
    private var loadedSize: CGFloat = .zero
    private var loadingCancellable: AnyCancellable?
    
    private var largestDimension: CGFloat {
        max(self.bounds.width, self.bounds.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        loadFromLocalURL(localURL)
    }
    
    private func loadFromLocalURL(_ url: URL?) {
        guard let url = url else {
            loadingCancellable?.cancel()
            loadingCancellable = nil
            image = nil
            return
        }
        let desiredSize = self.largestDimension * UIScreen.main.nativeScale
        
        // Only update if we need
        guard desiredSize != 0, localURL != loadedURL || desiredSize > loadedSize else { return }
        loadedSize = desiredSize
        loadingCancellable = Future<UIImage?, Never> { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                let options: [NSString:Any] = [kCGImageSourceThumbnailMaxPixelSize:desiredSize,
                                               kCGImageSourceCreateThumbnailFromImageAlways:true]
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
                else {
                    promise(.success(nil))
                    return
                }
                let uiImage = UIImage(cgImage: scaledImage)
                promise(.success(uiImage))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (image) in
            let wasBlank = self?.image == nil
            self?.image = image
            if wasBlank {
                self?.alpha = 0
                UIView.animate(withDuration: 0.1) {
                    self?.alpha = 1
                }
            }
        }
    }
}
