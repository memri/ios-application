//
// ContextPaneBackground.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct ContextPaneBackground: View {
    @EnvironmentObject var context: MemriContext

    var body: some View {
        Color.gray
    }
}

struct BackgroundPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneBackground()
    }
}
