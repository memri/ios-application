//
//  ProgressBarView.swift
//  memri
//
//  Created by Toby Brennan on 22/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ProgressBarView: View {
	var progressFraction: Double
	var frontColor: Color = .blue
	var backColor: Color = Color(.systemFill)
	var strokeColor: Color = Color(.secondarySystemFill)
	
	var bodyShape: some InsettableShape {
		RoundedRectangle(cornerRadius: 6, style: .continuous)
	}
	var body: some View {
		GeometryReader { geom in
			ZStack(alignment: .leading) {
				self.backColor
				if progressFraction > 0 {
					bodyShape
						.fill(self.frontColor)
						.frame(width: geom.size.width * CGFloat(progressFraction))
						.animation(.default, value: progressFraction)
				}
				bodyShape.strokeBorder(strokeColor, lineWidth: 1)
			}
			.clipShape(bodyShape)
		}
		.frame(height: 20)
	}
}

struct ProgressBarView_Previews: PreviewProvider {
	static var previews: some View {
		ProgressBarView(progressFraction: 0.5)
	}
}
