//
//  collection.swift
//  memri
//
//  Created by Ruben Daniels on 5/18/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
