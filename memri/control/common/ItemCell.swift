//
//  ItemCell.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public struct ItemCell: View {
    @EnvironmentObject var main: Main
    
    let item: DataItem
    let rendererNames: [String]
    let arguments: ViewArguments
//    let viewOverride: String // TODO Refactor: implement viewoverride
    
    public var body: some View {
        main.views.renderItemCell(with: item, search: rendererNames, use: arguments)
    }
}
