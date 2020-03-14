//
//  PShapes.swift
//  memri
//
//  Created by Jess Taylor on 3/14/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

//
// Draw a horizontal line
//
public let lineDividerFrameHeight: CGFloat = 10.0
public struct LineDivider: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: lineDividerFrameHeight / 2.0))
        path.addLine(to: CGPoint(x: rect.width, y: lineDividerFrameHeight / 2.0))
        return path
    }
}
