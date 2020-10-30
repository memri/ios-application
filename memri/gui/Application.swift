//
// Application.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

var memri_shouldUseLargeScreenLayout: Bool {
    #if targetEnvironment(macCatalyst)
        return true
    #else
        return false
    #endif
}

struct Application: View {
    @EnvironmentObject var context: MemriContext
    
    var body: some View {
        VStack(spacing: 0) {
            if self.context.installer.isInstalled && !self.context.installer.debugMode {
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
            else {
                SetupWizard()
            }
        }
        .background(Color(.systemBackground))
//        .colorScheme(.light) // Force light color scheme for now, until we add better dark-mode support
    }
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        let context = try! RootContext(name: "").mockBoot()
        return Application().environmentObject(context)
    }
}
