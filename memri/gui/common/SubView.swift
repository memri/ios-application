//
//  SubView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

// TODO: Refactor: optimize this for performance
public struct SubView: View {
	@EnvironmentObject var context: MemriContext

	var proxyMain: MemriContext?
	var toolbar: Bool = true
	var searchbar: Bool = true
	var showCloseButton: Bool = false

	// There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
	// By only duplicating that line and setting session later, but I am too lazy to do that.
	// TODO: Refactor
	public init(context: MemriContext, viewName: String, dataItem: Item? = nil,
				viewArguments: ViewArguments?) {
		do {
            let args = try ViewArguments(viewArguments, item: dataItem)
            args.set(".", dataItem)

			toolbar = args.get("toolbar") ?? toolbar
			searchbar = args.get("searchbar") ?? searchbar
			showCloseButton = args.get("showCloseButton") ?? showCloseButton

			guard let context = context as? RootContext else {
				throw "Exception: Too much nesting"
			}

            do {
                guard let stored = context.views.fetchDefinitions(name: viewName).first else {
                    throw "Could not fetch view by name: \(viewName)"
                }
                
                var state:CVUStateDefinition = try CVUStateDefinition.fromCVUStoredDefinition(stored)
                if stored.type == "sessions" {
                    
                }
                else if stored.type == "session" {
                    
                }
                else stored.type == "view" {
                    
                }
                
                proxyMain = try context.createSubContext(state)
                try proxyMain?.currentSession?.setCurrentView(nil, args)
            }
			catch {
				// TODO: Refactor error handling
				throw "Cannot update CascadingView \(self): \(error)"
			}
		} catch {
			// TODO: Refactor: error handling
			debugHistory.error("Error: cannot init subview: \(error)")
		}
	}

	public init(context: MemriContext, view state: CVUStateDefinition, dataItem: Item? = nil,
				viewArguments: ViewArguments?) {
		do {
			let args = try ViewArguments(viewArguments, item: dataItem)

			toolbar = args.get("toolbar") ?? toolbar
			searchbar = args.get("searchbar") ?? searchbar
			showCloseButton = args.get("showCloseButton") ?? showCloseButton

			guard let context = context as? RootContext else {
				throw "Exception: Too much nesting"
			}
            
            proxyMain = try context.createSubContext(state)
            args.set(".", dataItem)
            proxyMain?.cascadingView.set("viewArguments", args)
            try proxyMain?.updateCascadingView()
		} catch {
			// TODO: Refactor error handling
			debugHistory.error("Error: cannot init subview, failed to update CascadingView: \(error)")
		}
	}

	// TODO: refactor: consider inserting Browser here and adding variables instead
	public var body: some View {
		//        ZStack {
		VStack(alignment: .center, spacing: 0) {
			if self.toolbar {
				TopNavigation(inSubView: true, showCloseButton: showCloseButton)
			}
			allRenderers?.allViews[self.proxyMain?.currentView?.activeRenderer ?? "list"]
				.fullHeight()

			if self.searchbar {
				Search()
			}
		}
		.fullHeight()
		// NOTE: Allowed force unwrap
		.environmentObject(self.proxyMain!)

		//            ContextPane()
		//        }
	}
}
