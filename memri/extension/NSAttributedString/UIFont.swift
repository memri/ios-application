//
//  UIFont.swift
//  memri
//
//  Created by Koen van der Veen on 12/05/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {

    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {

        // create a new font descriptor with the given traits
        guard let fd = fontDescriptor.withSymbolicTraits(traits) else {
            // the given traits couldn't be applied, return self
            return self
        }

        // return a new font with the created font descriptor
        return UIFont(descriptor: fd, size: pointSize)
    }

    func italics() -> UIFont {
        return withTraits(.traitItalic)
    }

    func bold() -> UIFont {
        return withTraits(.traitBold)
    }

    func boldItalics() -> UIFont {
        return withTraits([ .traitBold, .traitItalic ])
    }
}
