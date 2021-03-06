//
// CVU_Shape.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

enum CVU_Shape {
    struct Circle: View {
        var nodeResolver: UINodeResolver
        var body: some View {
            SwiftUI.Circle().fill(nodeResolver.color()?.color ?? .clear)
        }
    }

    struct Rectangle: View {
        var nodeResolver: UINodeResolver
        var body: some View {
            SwiftUI.RoundedRectangle(cornerRadius: nodeResolver.cornerRadius)
                .fill(nodeResolver.color()?.color ?? .clear)
        }
    }
}
