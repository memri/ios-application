//
//  Shapes.swift
//  memri
//
//  Created by Jess Taylor on 3/14/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

public struct HorizontalLine: Shape {
	//
	// Draw a default full width horizontal line vertically centered in the provided CGRect
	//
	public func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: 0.0, y: rect.height / 2.0))
		path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2.0))
		return path
	}

	//
	// Return a stylized horizontal line with a custom color and linewidth
	// (Set the frame.height equal to the linewidth)
	//
	public func styleHorizontalLine(lineColor: Color = Color.gray, lineWidth: CGFloat = 1.5) -> some View {
		let path = HorizontalLine()
		let strokedView = path.stroke(lineColor, lineWidth: lineWidth)
		return strokedView.frame(height: lineWidth)
	}
}
