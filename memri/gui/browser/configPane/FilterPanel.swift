//
// FilterPanel.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct FilterPanel: View {
    @EnvironmentObject var context: MemriContext

    var clipShape: some Shape {
        RoundedCornerRectangle(radius: 20, corners: [.topLeft, .topRight])
    }
    
    var body: some View {
            HStack(alignment: .top, spacing: 0) {
                RendererSelectionPanel()
				Divider()
				ConfigPanel()
            }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipShape(clipShape)
                .background(clipShape.fill(Color(.systemBackground)).shadow(radius: 10).edgesIgnoringSafeArea([.bottom]))
                
    }
}




struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
