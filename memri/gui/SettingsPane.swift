//
// SettingsPane.swift
// Copyright © 2020 memri. All rights reserved.

import AnyCodable
import Foundation
import SwiftUI

struct SettingsPane: View {
    @EnvironmentObject var context: MemriContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    private func getBinding<T: Decodable>(_ path: String) -> Binding<T> {
        Binding<T>(
            get: { () -> T in
                // TODO: Error handling
                if let x: T = self.context.settings.get(path) {
                    return x
                }
                else {
                    debugHistory.warn("Could not get setting \(path)")

                    if T.self == String.self { return "" as! T }
                    if T.self == Double.self { return 0 as! T }
                    if T.self == Int.self { return 0 as! T }
                    if T.self == Bool.self { return false as! T }
                }

                return 0 as! T // Should never get here
            },
            set: {
                self.context.settings.set(path, AnyCodable($0))
            }
        )
    }

    // .keyboardType(.numberPad)
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: Form {
                    Section(
                        header: Text("Pod Connection"),
                        footer: Text("Never give out these details to anyone")
                            .font(.system(size: 11, weight: .regular))
                    ) {
                        HStack {
                            Text("Host:")
                                .frame(width: 100, alignment: .leading)
                            MemriTextField(value: getBinding("/user/pod/host") as Binding<String>)
                        }
                        HStack {
                            Button(action: {
                                if let datasource = self.context.currentView?.datasource
                                    .flattened()
                                {
                                    self.context.cache.sync.clearSyncCache()
                                    self.context.cache.sync.syncQuery(datasource)
                                }
                            }) {
                                Text("Connect")
                            }
                        }
                    }
                    Section(
                        header: Text("Syncing")
                    ) {
                        Toggle(isOn: getBinding("/device/upload/cellular")) {
                            Text("Enable upload of images while on cellular")
                        }
                    }
                }) {
                    Text("Pod Connection")
                }

                NavigationLink(destination: Form {
                    Section(
                        header: Text("User Interface"),
                        footer: Text("Show 'xx time ago' in place of dates less than 36 hours ago")
                            .font(.system(size: 11, weight: .regular))
                    ) {
                        Toggle(isOn: getBinding("/user/general/gui/showEditButton")) {
                            Text("Always show edit button")
                        }
                        Toggle(isOn: getBinding("/user/general/gui/showDateAgo")) {
                            Text("Enable time ago")
                        }
                        //						#if !targetEnvironment(macCatalyst)
                        //							// Only supported on iOS
                        //							Toggle(isOn: getBinding("/user/general/gui/useMapBox")) {
                        //								Text("Use MapBox (OpenStreetMap) instead of Apple Maps")
                        //							}
                        //						#endif
                    }
                }) {
                    Text("User Interface")
                }

                NavigationLink(destination: Form {
                    Section(
                        header: Text("Sensors")
                    ) {
                        Toggle(isOn: getBinding("/device/sensors/location/track")) {
                            Text("Track and store location")
                        }
                    }
                }) {
                    Text("Sensors")
                }

                NavigationLink(destination: Form {
                    Section(header: Text("Internationalization")) {
                        MemriTextField(
                            value: getBinding("/user/formatting/date") as Binding<String>
                        )
                    }
                }) {
                    Text("Internationalization")
                }

                NavigationLink(destination: Form {
                    Section(
                        header: Text("Debug Settings")
                    ) {
                        Toggle(isOn: getBinding("/device/debug/autoShowErrorConsole")) {
                            Text("Automatically pop up the debug console on errors")
                        }
                        Toggle(isOn: getBinding("/device/debug/autoReloadCVU")) {
                            Text("Automatically reload CVU when it changes")
                        }
                    }

                    Section(
                        header: Text("Debug Actions")
                    ) {
                        HStack {
                            Button(action: {
                                self.context.cache.sync.schedule()
                            }) {
                                Text("Sync To Pod")
                            }
                        }
                    }
                }) {
                    Text("Debug")
                }
            }
            .navigationBarItems(leading:
                Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                    Text("Close")
                })
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
        }
    }
}
