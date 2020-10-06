//
//  CVUFont.swift
//  memri
//
//  Created by Toby Brennan on 5/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct CVUFont {
    var name: String?
    var size: CGFloat?
    var weight: Font.Weight?
    var italic: Bool = false
    
    var font: Font {
        Font(uiFont)
    }
    
    var uiFont: UIFont {
        let font = UIFont.systemFont(
            ofSize: size ?? UIFont.systemFontSize,
            weight: weight?.uiKit ?? .regular
        )
        let fontWithTraits = font.withTraits(traits: italic ? .traitItalic : [])
        return fontWithTraits
    }
}

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor
            .withSymbolicTraits(fontDescriptor.symbolicTraits.union(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

extension Font.Weight {
    init(_ string: String) {
        switch string {
        case "black": self = .black
        case "bold": self = .bold
        case "heavy": self = .heavy
        case "light": self = .light
        case "medium": self = .medium
        case "regular": self = .regular
        case "semibold": self = .semibold
        case "thin": self = .thin
        case "ultraLight": self = .ultraLight
        default: self = .regular
        }
    }
    var uiKit: UIFont.Weight {
        switch self {
        case .black: return .black
        case .bold: return .bold
        case .heavy: return .heavy
        case .light: return .light
        case .medium: return .medium
        case .regular: return .regular
        case .semibold: return .semibold
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        default: return .regular
        }
    }
}
