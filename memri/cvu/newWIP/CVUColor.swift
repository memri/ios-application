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
