//
//  SettingsView.swift
//  memri
//
//  Created by Ruben Daniels on 4/16/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingsPane: View {
    @EnvironmentObject var context: MemriContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    private func getBinding<T:Decodable>(_ path:String) -> Binding<T> {
        return Binding<T>(
            get: { () -> T in
                // TODO: Error handling
                if let x:T = self.context.settings.get(path) {
                    return x
                }
                else {
                    errorHistory.warn("Could not get setting \(path)")
                    
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

    //.keyboardType(.numberPad)
    var body: some View {
        NavigationView {
            Form {
//                Section(header: Text("General")) {
//                    DatePicker(selection: getBinding("/user/formatting/date"), in: ...Date(), displayedComponents: .date) {
//                        Text("Date Format")
//                    }
//
//                    Picker(selection: $citySelected, label: Text("Choose a city:")) {
//                        ForEach(0 ..< Self.cities.count) {
//                            Text(Self.cities[$0])
//                        }
//                    }
//                    if addOwnCity {
//                        TextField("Enter your own city" ,text: $ownCity)
//                    }
//                }
                NavigationLink(destination: Form {
                    Section(
                        header: Text("Pod Connection"),
                        footer: Text("Never give out these details to anyone")
                            .font(.system(size: 11, weight: .regular))
                    ) {
                        VStack {
                            HStack {
                                Text("Host:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("Host", text: getBinding("/user/pod/host"))
                            }
                            HStack {
                                Text("Username:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("Username", text: getBinding("/user/pod/username"))
                            }
                            HStack {
                                Text("Password:")
                                    .frame(width: 100, alignment: .leading)
                                SecureField("Password", text: getBinding("/user/pod/password"))
                            }
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
                    }
                }) {
                    Text("User Interface")
                }
                
                NavigationLink(destination: Form {
                    Section(header: Text("Internationalization")) {
                        TextField("Date Format", text: getBinding("/user/formatting/date"))
                    }
                }) {
                    Text("Internationalization")
                }
                
                NavigationLink(destination: Form {
                    Section(
                        header: Text("Debug")
                    ) {
                        Toggle(isOn: getBinding("/device/debug/autoShowErrorConsole")) {
                            Text("Automatically pop up the debug console")
                        }
                    }
                }) {
                    Text("Debug")
                }
            }
            .navigationBarItems(leading:
                Button(action:{ self.presentationMode.wrappedValue.dismiss()}) {
                    Text("close")
                })
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
        }
    }
}

struct DetailsView: View {
    var body: some View {
        Text("hello")
    }
}
