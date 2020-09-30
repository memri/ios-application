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

    var activeRendererController: RendererController? {
        self.context.currentRendererController
    }
    
    @State var isSearchActive: Bool = false
    
    var showFilterPanel: Bool {
        get {
            self.context.currentSession?.showFilterPanel ?? false
        }
        nonmutating set {
            self.context.currentSession?.showFilterPanel = newValue
            self.context.scheduleUIUpdate(updateWithAnimation: true)
        }
    }
    
    @GestureState var filterPanelGestureOffset: CGFloat = .zero

    var body: some View {
        let currentView = self.context.currentView ?? CascadableView()

        return ZStack(alignment: .bottom) {
            if self.context.currentView == nil {
                Text("Loading...")
                .padding()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .center, spacing: 0) {
                    if currentView.showToolbar && !currentView.fullscreen {
                        TopNavigation(inSubView: inSubView, showCloseButton: showCloseButton)
                            .background(Color(.systemBackground))
                    }
                    ZStack {
                        VStack(alignment: .center, spacing: 0) {
                            if activeRendererController != nil {
                                activeRendererController.map { activeRendererController in
                                    activeRendererController.makeView()
                                        .fullHeight().layoutPriority(1)
                                        .background((currentView.fullscreen ? Color.black : Color.clear)
                                            .edgesIgnoringSafeArea(.all))
                                }
                            } else {
                                Text("No active renderer").padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            
                            if currentView.showBottomBar {
                                ContextualBottomBar()
                                
                                if !currentView.fullscreen {
                                    BottomBarView(onSearchPressed: {
                                        self.isSearchActive = true
                                    })
                                    .zIndex(8)
                                }
                            }
                        }
                        if showFilterPanel && currentView.showBottomBar {
                            Color.black.opacity(0.15)
                                .onTapGesture {
                                self.showFilterPanel = false
                            }
                            .gesture(DragGesture().updating($filterPanelGestureOffset) { (value, state, _) in
                                state = max(0, value.translation.height)
                            }.onEnded({ (value) in
                                if value.predictedEndTranslation.height > 20 {
                                    self.showFilterPanel = false
                                }
                            }))
                        }
                    }
                    
                }
                SearchView(isActive: $isSearchActive)
                
                if showFilterPanel {
                    VStack {
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 40, height: 5)
                            .frame(maxWidth: .infinity)
                            .frame(height: 15)
                        FilterPanel()
                    }
                    .offset(y: filterPanelGestureOffset)
                    .transition(.move(edge: .bottom))
                    .zIndex(9)
                }
                
                if currentView.contextPane.isSet() {
                    ContextPane()
                    .zIndex(15)
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
