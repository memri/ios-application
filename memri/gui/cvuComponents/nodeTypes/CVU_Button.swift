//
// CVU_Button.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct CVU_Button: View {
    var nodeResolver: UINodeResolver
    var context: MemriContext

    var body: some View {
        Button(action: {
            if let press: Action = self.nodeResolver.resolve("press") {
                self.context.executeAction(
                    press,
                    with: self.nodeResolver.item,
                    using: self.nodeResolver.viewArguments
                )
            }
        }) {
            self.nodeResolver.childrenInForEach
        }
        .buttonStyle(Style())
    }

    struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration
                .label
                .shadow(radius: configuration.isPressed ? 4 : 0)
        }
    }
}
