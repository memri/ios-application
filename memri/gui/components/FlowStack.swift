//
// FlowStack.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import Foundation
import SwiftUI

public struct FlowStack<Data: RandomAccessCollection, Content: View>: View
    where Data.Element: Identifiable, Data.Element: Hashable, Data.Index == Int
{
    init(
        data: Data,
        spacing: CGPoint = .zero,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    let data: Data
    let spacing: CGPoint
    let alignment: HorizontalAlignment
    let content: (_ item: Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            InnerView(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }

    // This implementation is by Frederico @ https://fivestars.blog/swiftui/flexible-swiftui.html
    struct InnerView: View {
        let availableWidth: CGFloat
        let data: Data
        let spacing: CGPoint
        let alignment: HorizontalAlignment
        let content: (Data.Element) -> Content
        @State var elementsSize: [Data.Element: CGSize] = [:]

        var body: some View {
            VStack(alignment: alignment, spacing: spacing.y) {
                ForEach(computeRows(), id: \.self) { rowElements in
                    HStack(spacing: spacing.x) {
                        ForEach(rowElements, id: \.self) { element in
                            content(element)
                                .fixedSize()
                                .readSize { size in
                                    elementsSize[element] = size
                                }
                        }
                    }
                }
            }
            .frame(maxWidth: availableWidth)
        }

        func computeRows() -> [[Data.Element]] {
            var rows: [[Data.Element]] = [[]]
            var currentRow = 0
            var remainingWidth = availableWidth

            for element in data {
                let elementSize = elementsSize[
                    element,
                    default: CGSize(width: availableWidth, height: 1)
                ]

                if remainingWidth - (elementSize.width + spacing.x) >= 0 {
                    rows[currentRow].append(element)
                }
                else {
                    currentRow = currentRow + 1
                    rows.append([element])
                    remainingWidth = availableWidth
                }

                remainingWidth = remainingWidth - (elementSize.width + spacing.x)
            }

            return rows
        }
    }
}
