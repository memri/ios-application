//
//  SetupWizard.swift
//  memri
//
//  Created by Ruben Daniels on 7/26/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct SetupWizard: View {
    @EnvironmentObject var context: MemriContext

    @State private var host: String = "http://localhost:3030"
    @State private var privateKey: String = ""
    @State private var publicKey: String = ""
    @State private var databaseKey: String = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                if !context.installer.isInstalled && !context.installer.debugMode {

                    Section(
                        header: Text("Connect to a pod")
                    ) {
                        NavigationLink(destination: Form {
                            Section(
                                header: Text("Pod Connection"),
                                footer: Text("Never give out these details to anyone")
                                    .font(.system(size: 11, weight: .regular))
                            ) {
                                HStack {
                                    Text("Host:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $host)
                                }
                            }
                            Button(action: {
                                if self.host != "" {
                                    self.showingAlert = true
                                }
                            }) {
                                Text("Authenticate")
                            }
                            .alert(isPresented:$showingAlert) {
                                Alert (
                                    title: Text("Clear Database"),
                                    message: Text("This will delete access to all previous data on this device and load the default database to connect to a new pod. Are you sure? There is no undo!"),
                                    primaryButton: .destructive(Text("Delete")
                                    ) {
                                        self.context.installer.installLocalAuthForNewPod(
                                            self.context,
                                            areYouSure: true,
                                            host: self.host
                                        ) { error in
                                            if let error = error {
                                                debugHistory.error("\(error)") // TODO: show this to the user
                                            }
                                        }
                                    }, secondaryButton: .cancel())
                            }
                        }) {
                            Text("Connect to a new pod")
                        }
                        NavigationLink(destination: Form {
                            Section(
                                header: Text("Pod Connection"),
                                footer: Text("Never give out these details to anyone")
                                    .font(.system(size: 11, weight: .regular))
                            ) {
                                HStack {
                                    Text("Host:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $host)
                                }
                                HStack {
                                    Text("Private Key:")
                                        .frame(width: 100, alignment: .leading)
                                    SecureField("Private Key:", text: $privateKey)
                                }
                                HStack {
                                    Text("Public Key:")
                                        .frame(width: 100, alignment: .leading)
                                    SecureField("Public Key:", text: $publicKey)
                                }
                                HStack {
                                    Text("Database Key:")
                                        .frame(width: 100, alignment: .leading)
                                    SecureField("Database Key:", text: $databaseKey)
                                }
                            }
                            Button(action: {
                                if self.host != "" {
                                    self.showingAlert = true
                                }
                            }) {
                                Text("Authenticate")
                            }
                            .alert(isPresented:$showingAlert) {
                                Alert (
                                    title: Text("Clear Database"),
                                    message: Text("This will delete access to all previous data on this device and load a fresh copy of your data from your pod. Are you sure? There is no undo!"),
                                    primaryButton: .destructive(Text("Delete")
                                    ) {
                                        self.context.installer.installLocalAuthForExistingPod(
                                            self.context,
                                            areYouSure: true,
                                            host: self.host,
                                            privateKey: self.privateKey,
                                            publicKey: self.publicKey,
                                            dbKey: self.databaseKey
                                        ) { error in
                                            error.map { debugHistory.error("\($0)") } // TODO: show this to the user
                                        }
                                    }, secondaryButton: .cancel())
                            }
                        }) {
                            Text("Connect to an existing pod")
                        }
                    }
                    Section(
                        header: Text("Or use Memri locally")
                    ) {
                        Button(action: {
                            self.context.installer.installLocalAuthForLocalInstallation(self.context, areYouSure: true) { error in
                                error.map { debugHistory.error("\($0)") } // TODO: show this to the user
                            }
                        }) {
                            Text("Use memri without a pod")
                        }
                        Button(action: {
                            self.context.installer.installDemoDatabase(self.context) { _,_  in
                                self.context.settings.set("user/pod/host", "")
                                self.context.installer.ready(self.context)
                            }
                        }) {
                            Text("Play around with the DEMO database")
                        }
//                        Button(action: {
//                            fatalError()
//                        }) {
//                            Text("Simulate a hard crash")
//                        }
                    }
                }
                if context.installer.debugMode {
                    Text("Recovery Wizard")
                        .font(.system(size: 22, weight: .bold))

                    Section(
                        header: Text("Memri crashed last time. What would you like to do?")
                    ) {
                        Button(action: {
                            self.context.installer.continueAsNormal(self.context)
                        }) {
                            Text("Continue as normal")
                        }
                        Button(action: {
                            self.context.installer.clearDatabase(self.context) { error in
                                debugHistory.error("\(error ?? "")") // TODO: show this to the user
                            }
                        }) {
                            Text("Delete the local database and start over")
                        }
                        if context.installer.isInstalled {
                            Button(action: {
                                self.context.installer.clearSessions(self.context) { error in
                                    debugHistory.error("\(error ?? "")") // TODO: show this to the user
                                }
                            }) {
                                Text("Clear the session history (to recover from an issue)")
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Setup Wizard"))
        }
    }
}
