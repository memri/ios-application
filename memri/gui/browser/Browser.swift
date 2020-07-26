//
// Browser.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

struct Browser: View {
    @EnvironmentObject var context: MemriContext

    let inSubView: Bool
    let showCloseButton: Bool

    init() {
        inSubView = false
        showCloseButton = false
    }

    init(inSubView: Bool, showCloseButton: Bool) {
        self.inSubView = inSubView
        self.showCloseButton = showCloseButton
    }

    var activeRenderer: AnyView {
        allRenderers?.allViews[context.currentView?.activeRenderer ?? ""] ?? AnyView(Spacer())
    }

    var body: some View {
        let currentView = self.context.currentView ?? CascadableView()

        return ZStack {
            if self.context.currentView == nil {
                Text("Loading...")
            }
            else {
                VStack(alignment: .center, spacing: 0) {
                    if currentView.showToolbar && !currentView.fullscreen {
                        TopNavigation(inSubView: inSubView, showCloseButton: showCloseButton)
                            .background(Color(.systemBackground))
                    }

                    activeRenderer
                        .fullHeight().layoutPriority(1)
                        .background((currentView.fullscreen ? Color.black : Color.clear)
                            .edgesIgnoringSafeArea(.all))

                    ContextualBottomBar()

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
        Browser().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
