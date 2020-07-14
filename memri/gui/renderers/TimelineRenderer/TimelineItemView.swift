//
//  TimelineItemView.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 28/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI

struct TimelineItemView: View {
    var icon: Image = Image(systemName: "paperplane")
    var title: String = "Hello world"
    var subtitle: String? = nil
    var cornerRadius: CGFloat = 5
    var highlighted: Bool = false
    var backgroundColor: Color = Color(.systemGreen)
    var foregroundColor: Color {
        Color.white
//        backgroundColor.contrast
    }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                icon
                Text(title)
            }
            subtitle.map {
                Text($0)
                    .font(.caption)
					.lineLimit(2)
            }
        }
        .padding(5)
        .foregroundColor(foregroundColor)
        .background(backgroundColor.brightness(highlighted ? -0.2 : 0))
        .mask(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
}

struct TimelineItemView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineItemView()
    }
}

extension UIColor {
    var contrast: Color {
        let ciColor = CIColor(color: self)
        // Perceptive luminance
        let luminance = (ciColor.red * 0.299 + ciColor.green * 0.587 + ciColor.blue * 0.114)
        return luminance < 0.6 ? .white : .black
      }
}
