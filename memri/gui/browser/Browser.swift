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

	var activeRenderer: AnyView {
		allRenderers?.allViews[context.currentView?.activeRenderer ?? ""] ?? AnyView(Spacer())
	}

	var body: some View {
		ZStack {
			VStack(alignment: .center, spacing: 0) {
				TopNavigation()
					.background(Color(.systemBackground))
				activeRenderer
					.fullHeight().layoutPriority(1)
				Search()
				if self.context.currentSession?.showFilterPanel ?? false {
					FilterPanel()
				}
			}

			ContextPane()
		}
	}
}

struct Browser_Previews: PreviewProvider {
	static var previews: some View {
		Browser().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
