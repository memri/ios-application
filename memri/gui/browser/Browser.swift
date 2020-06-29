//
//  ContentView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import SwiftUI

struct Browser: View {
	@EnvironmentObject var context: MemriContext

	var body: some View {
		ZStack {
			VStack(alignment: .center, spacing: 0) {
				TopNavigation()
					.background(Color(.systemBackground))
				allRenderers?.allViews[self.context.cascadingView.activeRenderer]
					.fullHeight().layoutPriority(1)
				Search()
				if self.context.currentSession.showFilterPanel {
					FilterPanel()
				}
			}

			ContextPane()
		}
	}
}

struct Browser_Previews: PreviewProvider {
	static var previews: some View {
		Browser().environmentObject(RootContext(name: "", key: "").mockBoot())
	}
}
