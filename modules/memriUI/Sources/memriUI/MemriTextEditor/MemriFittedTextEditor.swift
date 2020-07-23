//
// MemriFittedTextEditor.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

// Intended for use in message composer. Will self-adjust size as needed
public struct MemriFittedTextEditor: View {
    @State var preferredHeight: CGFloat = 0

    public init() {}

    var displayHeight: CGFloat {
        let minHeight: CGFloat = 30
        let maxHeight: CGFloat = 100

        return min(max(minHeight, preferredHeight), maxHeight)
    }

    public var body: some View {
        MemriTextEditor(preferredHeight: $preferredHeight)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .frame(height: displayHeight)
    }
}
