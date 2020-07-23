//
// SubView.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct SubView: View {
    @EnvironmentObject var context: MemriContext

    var proxyMain: MemriContext?
    var toolbar: Bool = true
    var searchbar: Bool = true
    var showCloseButton: Bool = false

    public init(
        context: MemriContext,
        viewName: String,
        item: Item? = nil,
        viewArguments: ViewArguments = ViewArguments(nil)
    ) {
        do {
            let args = try viewArguments.resolve(item)

            showCloseButton = args.get("showCloseButton") ?? showCloseButton

            guard let context = context as? RootContext else {
                throw "Exception: Too much nesting"
            }

            do {
                guard let stored = context.views.fetchDefinitions(name: viewName).first else {
                    throw "Could not fetch view by name: \(viewName)"
                }

                let state = try context.views.getViewStateDefinition(from: stored)
                proxyMain = try context.createSubContext()
                try proxyMain?.currentSession?.setCurrentView(state, args)
            }
            catch {
                // TODO: Refactor error handling
                throw "Cannot update view \(self): \(error)"
            }
        }
        catch {
            // TODO: Refactor: error handling
            debugHistory.error("Error: cannot init subview: \(error)")
        }
    }

    public init(
        context: MemriContext,
        view state: CVUStateDefinition,
        item: Item? = nil,
        viewArguments: ViewArguments = ViewArguments(nil)
    ) {
        do {
            let args = try viewArguments.resolve(item)

            showCloseButton = args.get("showCloseButton") ?? showCloseButton

            guard let context = context as? RootContext else {
                throw "Exception: Too much nesting"
            }

            proxyMain = try context.createSubContext()
            try proxyMain?.currentSession?.setCurrentView(state, args)
        }
        catch {
            // TODO: Refactor error handling
            debugHistory.error("Cannot init subview, failed to update view: \(error)")
        }
    }

    public var body: some View {
        Browser(inSubView: true, showCloseButton: showCloseButton)
            .fullHeight()
            // NOTE: Allowed force unwrap
            .environmentObject(self.proxyMain!)
    }
}
