//
// FilterPanel.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct FilterPanel: View {
    @EnvironmentObject var context: MemriContext

    var body: some View {
            HStack(alignment: .top, spacing: 0) {
                RendererSelectionPanel()
				Divider()
				ConfigPanel()
					.frame(width: 200)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: 240)
            .background(Color(hex: "#eee"))
    }
}




struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
