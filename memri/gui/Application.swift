//
// Application.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

extension View {
    func fullHeight(alignment: Alignment = .topLeading) -> some View {
        frame(minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0, maxHeight: .infinity,
              alignment: alignment)
    }

    func fullWidth(alignment: Alignment = .topLeading) -> some View {
        frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
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
        }
        .background(Color(.systemBackground))
        .colorScheme(.light) // Force light color scheme for now, until we add better dark-mode support
    }
}

struct Application_Previews: PreviewProvider {
    static var previews: some View {
        let context = try! RootContext(name: "").mockBoot()
        return Application().environmentObject(context)
    }
}
