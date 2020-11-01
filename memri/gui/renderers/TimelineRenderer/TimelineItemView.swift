//
// TimelineItemView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct TimelineItemView: View {
    var icon = Image(systemName: "paperplane")
    var title: String = "Hello world"
    var subtitle: String? = nil
    var cornerRadius: CGFloat = 5

    var backgroundColor = Color(.systemGreen)
    var foregroundColor: Color {
        Color.white
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .lastTextBaseline) {
                icon
                Text(title)
                    .bold()
                    .lineLimit(1)
            }
            .font(.headline)
            subtitle.map {
                Text($0)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(5)
        .foregroundColor(foregroundColor)
        .background(backgroundColor)
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
