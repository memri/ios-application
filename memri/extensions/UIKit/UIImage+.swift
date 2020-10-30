//
// UIImage+.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import UIKit

extension UIImage {
    var aspectRatio: CGFloat {
        let imageSize = size
        guard imageSize.height > 0 else { return 1 }
        return imageSize.width / imageSize.height
    }
}
