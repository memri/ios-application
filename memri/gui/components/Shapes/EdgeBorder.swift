//
//  EdgeBorder.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct EdgeBorder: Shape {
    var width: CGFloat
    var edge: SwiftUI.Edge
    
    func path(in rect: CGRect) -> Path {
        var x: CGFloat {
            switch edge {
            case .top, .bottom, .leading: return rect.minX
            case .trailing: return rect.maxX - width
            }
        }
        
        var y: CGFloat {
            switch edge {
            case .top, .leading, .trailing: return rect.minY
            case .bottom: return rect.maxY - width
            }
        }
        
        var w: CGFloat {
            switch edge {
            case .top, .bottom: return rect.width
            case .leading, .trailing: return width
            }
        }
        
        var h: CGFloat {
            switch edge {
            case .top, .bottom: return width
            case .leading, .trailing: return rect.height
            }
        }
        
        return Path(CGRect(x: x, y: y, width: w, height: h))
    }
}
