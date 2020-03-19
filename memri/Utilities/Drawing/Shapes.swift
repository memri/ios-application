//
//  PShapes.swift
//  memri
//
//  Created by Jess Taylor on 3/14/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

public struct HorizontalLine: Shape {

    let horizontalLineFrameHeight: CGFloat = 10.0

    //
    // Draw a full width horizontal line vertically centered in the frame
    //
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: horizontalLineFrameHeight / 2.0))
        path.addLine(to: CGPoint(x: rect.width, y: horizontalLineFrameHeight / 2.0))
        return path
    }
    
    //
    // Adorn a horizontal line with a color and line with
    //
    public func adornedHorizontalLine(lineWidth: CGFloat = 1.5) -> some View {
        let path = HorizontalLine()
        let strokedView = path.stroke(Color.gray, lineWidth: lineWidth)
        return strokedView.frame(height: horizontalLineFrameHeight)
    }
}
