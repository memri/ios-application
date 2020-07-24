//
// CVUPropertyResolver.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct CVUPropertyResolver {
    var properties: [String: Any?] = [:]

    var color: ColorDefinition? {
        if let colorDef = properties["color"] as? ColorDefinition {
            return colorDef
        }
        else if let colorHex = properties["color"] as? String {
            return ColorDefinition.hex(colorHex)
        }
        return nil
    }

    var font: FontDefinition {
        guard let fontProperty = properties["font"] else { return FontDefinition() }
        if let value = fontProperty as? [Any] {
            if let name = value[safe: 0] as? String, let size = value[safe: 1] as? CGFloat {
                return FontDefinition(
                    name: name,
                    size: size,
                    weight: value[safe: 2] as? Font.Weight
                )
            }
            else if let size = value[safe: 0] as? CGFloat {
                return FontDefinition(size: size, weight: value[safe: 1] as? Font.Weight)
            }
        }
        else if let size = fontProperty as? CGFloat {
            return FontDefinition(size: size)
        }
        else if let weight = fontProperty as? Font.Weight {
            return FontDefinition(weight: weight)
        }
        return FontDefinition()
    }

    var lineLimit: Int? {
        properties["lineLimit"] as? Int
    }

    var fitContent: Bool {
        switch properties["resizable"] as? String {
        case "fill": return false
        case "fit": return true
        default: return true
        }
    }
}

enum ColorDefinition {
    case hex(String)
    case system(UIColor)

    var color: Color {
        switch self {
        case let .hex(hex):
            return Color(hex: hex)
        case let .system(color):
            return Color(color)
        }
    }

    var uiColor: UIColor {
        switch self {
        case let .hex(hex):
            return UIColor(hex: hex)
        case let .system(color):
            return color
        }
    }
}

struct FontDefinition {
    var name: String?
    var size: CGFloat?
    var weight: Font.Weight?
    var italic: Bool = false

    var font: Font {
        #warning("IMPLEMENT ME")
        return Font.system(.body)
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
