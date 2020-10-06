//
// ItemCell.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct ItemCell: View {
    @EnvironmentObject var context: MemriContext

    let item: Item?
    let rendererNames: [String]
    let arguments: ViewArguments

    public var body: some View {
        context.views.renderItemCell(with: item, search: rendererNames, use: arguments)
    }
}
