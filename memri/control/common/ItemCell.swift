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
    let variables: [String: () -> Any]
//    let viewOverride: String // TODO Refactor: implement viewoverride
    
    public var body: some View {
        try! main.views.renderItemCell(item, rendererNames, nil, variables)
    }
}
