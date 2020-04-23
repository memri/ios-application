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
    let item: DataItem
    let rendererNames: [String]
    let viewOverride: String? = nil
    
    public var body: some View {
        // If there is a view override, find it, otherwise
            // Find the first cascaded renderer for the type
        // Use it to render the item here
    }
}
