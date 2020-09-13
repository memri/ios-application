//
//  EmailHeaderView.swift
//  memri
//
//  Created by Toby Brennan on 30/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct EmailHeaderView: View {
    var senderName: String
    var recipientList: String?
    var dateString: String?
    var color: CVUColor?
    
    var senderInitials: String {
        senderName.split(separator: Character(" ")).prefix(2).compactMap{$0.first.map(String.init)?.capitalized}.joined()
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(color?.color ?? .blue)
                .overlay(
                    Text(senderInitials)
                        .foregroundColor(.white)
            )
                .frame(height: 50)
                .aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(senderName)
                    Spacer()
                    dateString.map {
                        Text($0)
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.caption)
                    }
                }
                HStack {
                    recipientList.map {
                        Text($0)
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.caption)
                    }
                    Spacer()
                    //                    Button(action: {}) {
                    //                        Image(systemName: "ellipsis.circle")
                    //                    }
                }
            }
        }
    }
}
