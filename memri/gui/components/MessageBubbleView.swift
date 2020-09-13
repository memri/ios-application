//
//  MessageBubbleView.swift
//  memri
//
//  Created by Toby Brennan on 31/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct MessageBubbleView: View {
    var timestamp: Date?
    var sender: String?
    var content: String
    var outgoing: Bool
    var font: CVUFont?
    
    var dateFormatter: DateFormatter {
        // TODO: If there is a user setting for a *short* date format, we should use that
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .short
        format.doesRelativeDateFormatting = true
        return format
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if !outgoing {
                    sender?.nilIfBlank.map {
                        Text($0)
                            .lineLimit(1)
                            .font(Font.body.bold())
                    }
                }
                timestamp.map {
                    Text(dateFormatter.string(from: $0))
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                MemriSmartTextView(string: content, detectLinks: true,
                                   font: font ?? CVUFont(size: 18),
                                   color: outgoing ? CVUColor.system(.white) : CVUColor.system(.label),
                                   maxLines: nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.all, 10)
                    .background(
                        outgoing ? Color.blue : Color(.secondarySystemBackground)
                )
                    .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
        .padding(outgoing ? .leading : .trailing, 20)
    }
}

//struct MessageBubbleView_Previews: PreviewProvider {
//    static var previews: some View {
//        MessageBubbleView()
//    }
//}
