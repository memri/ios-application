//
//  Browser.swift
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
        let currentView = self.context.currentView ?? CascadingView()
        
		return ZStack {
            if self.context.currentView == nil {
                Text("Loading...")
            }
            else {
                VStack(alignment: .center, spacing: 0) {
                    if currentView.showToolbar && !currentView.fullscreen {
                        TopNavigation()
                            .background(Color(.systemBackground))
                    }
                    
                    activeRenderer
                        .fullHeight().layoutPriority(1)
                    
                    if currentView.showSearchbar && !currentView.fullscreen {
                        Search()
                        if self.context.currentSession?.showFilterPanel ?? false {
                            FilterPanel()
                        }
                    }
                }

                if currentView.contextPane.isSet() {
                    ContextPane()
                }
            }
		}
	}
}

struct Browser_Previews: PreviewProvider {
	static var previews: some View {
		Browser().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
