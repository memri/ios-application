//
//  ContentView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

extension View {
    func fullHeight() -> some View {
        self.frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0, maxHeight: .infinity,
                   alignment: Alignment.topLeading)
    }
    
    func fullWidth() -> some View{
        return self.frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.topLeading)
    }
}


var memri_shouldUseLargeScreenLayout: Bool {
    #if targetEnvironment(macCatalyst)
    return true
    #else
    return UIDevice.current.userInterfaceIdiom == .pad
    #endif
}

struct Application: View {
    @EnvironmentObject var context: MemriContext
    
    var body: some View {
        ScreenSizer {
            VStack(spacing: 0) {
            NavigationWrapper(isVisible: self.context.showNavigationBinding) {
                if self.context.showSessionSwitcher {
                    SessionSwitcher()
                        .ignoreSafeAreaOnMac()
                }
                else {
                    Browser()
                        .ignoreSafeAreaOnMac()
                }
            }
                DebugConsole()
            }
        }
        .background(Color(.systemBackground))
        .colorScheme(.light) // Force light color scheme for now, until we add better dark-mode support
    }
    
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        let context = RootContext(name: "", key: "").mockBoot()
        return Application().environmentObject(context)
    }
}
