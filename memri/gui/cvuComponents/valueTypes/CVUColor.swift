//
//  CVUColor.swift
//  memri
//
//  Created by Toby Brennan on 5/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public enum CVUColor {
    case hex(String)
    case system(UIColor)
    case named(String)
    
    var color: Color {
        switch self {
        case let .hex(hex):
            return Color(hex: hex)
        case let .system(color):
            return Color(color)
        case let .named(name):
            return CVUDefaultNamedColor(rawValue: name)?.color ?? Color.primary
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case let .hex(hex):
            return UIColor(hex: hex)
        case let .system(color):
            return color
        case let .named(name):
            return CVUDefaultNamedColor(rawValue: name)?.uiColor ?? UIColor.label
        }
    }
    
    static func hasNamed(_ name: String) -> Bool {
        CVUDefaultNamedColor(rawValue: name) != nil
    }
}


enum CVUDefaultNamedColor: String {
    case primary
    case secondary
    case tertiary
    case background
    case secondaryBackground
    case tertiaryBackground
    case red
    case orange
    case yellow
    case green
    case blue
    
    var uiColor: UIColor {
        switch self {
        case .primary:
            return UIColor.label
        case .secondary:
            return UIColor.secondaryLabel
        case .tertiary:
            return UIColor.tertiaryLabel
        case .background:
            return UIColor.systemBackground
        case .secondaryBackground:
            return UIColor.secondarySystemBackground
        case .tertiaryBackground:
            return UIColor.tertiarySystemBackground
        case .red:
            return UIColor.systemRed
        case .orange:
            return UIColor.systemOrange
        case .yellow:
            return UIColor.systemYellow
        case .green:
            return UIColor.systemGreen
        case .blue:
            return UIColor.systemBlue
        }
    }
    
    var color: Color {
        Color(uiColor)
    }
}
