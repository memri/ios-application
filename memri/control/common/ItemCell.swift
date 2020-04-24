//
//  wrappingHStack.swift
//  memri
//
//  Created by Ruben Daniels on 4/17/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public struct ItemCell: View {
    @EnvironmentObject var main: Main
    
    let item: DataItem
    let rendererNames: [String]
    let viewOverride: String? = nil
    let variables: [String: () -> Any]? = nil
    
    public var body: some View {
        try! main.views.renderItemCell(item, rendererNames, viewOverride, variables)
    }
}
