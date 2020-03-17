//
//  PShapes.swift
//  memri
//
//  Created by Jess Taylor on 3/14/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

//
// Draw a full width horizontal line vertically centered in the frame
//
public let horizontalLineFrameHeight: CGFloat = 10.0
public struct HorizontalLine: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: horizontalLineFrameHeight / 2.0))
        path.addLine(to: CGPoint(x: rect.width, y: horizontalLineFrameHeight / 2.0))
        return path
    }
}
