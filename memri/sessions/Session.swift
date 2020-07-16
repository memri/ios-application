//
//  Session.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

public final class Session : Equatable {
    /// The name of the item.
    var name:String? {
        get { parsed["name"] as? String }
        set (value) { setState("name", value) }
    }
    /// TBD
    var currentViewIndex:Int {
        get { parsed["currentViewIndex"] as? Int ?? 0 }
        set (value) { setState("currentViewIndex", value) }
    }
    /// TBD
    var editMode:Bool {
        get { parsed["editMode"] as? Bool ?? false }
        set (value) { setState("editMode", value) }
    }
    /// TBD
    var showContextPane:Bool {
        get { parsed["showContextPane"] as? Bool ?? false }
        set (value) { setState("showContextPane", value) }
    }
    /// TBD
    var showFilterPanel:Bool  {
        get { parsed["showFilterPanel"] as? Bool ?? false }
        set (value) { setState("showFilterPanel", value) }
    }

    /// TBD
    var screenshot: File? {
        get {
            state?.edge("screenshot")?.item(type: File.self)
        }
        set (value) {
            if let file = value {
                do { _ = try state?.link(file, type: "screenshot", distinct: true) }
                catch {
                    debugHistory.error("Unable to store screenshot: \(error)")
                }
            }
            else {
                // Remove file: not implemented
                print("NOT IMPLEMENTED")
            }
        }
    }

    var uid: Int
    var parsed: CVUParsedSessionDefinition
    var state: CVUStateDefinition? {
        withReadRealm { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        } as? CVUStateDefinition
    }
    
    /// TBD
    var views = [CascadingView]()
    /// TBD
    var sessions: Sessions?
    var context: MemriContext?
    
	private var cancellables: [AnyCancellable] = []

	var swiftUIEditMode: EditMode {
		get {
			if editMode { return .active }
			else { return .inactive }
		}
		set(value) {
            if value == .active { self.editMode = true }
            else { self.editMode = false }
		}
	}

	var hasHistory: Bool {
		currentViewIndex > 0
	}

	public var currentView: CascadingView? {
        views[safe: currentViewIndex]
	}

    init(_ state: CVUStateDefinition, _ sessions:Sessions) throws {
        guard let uid = state.uid.value else {
            throw "CVU state object is unmanaged"
        }
        
        self.uid = uid
        self.sessions = sessions
        self.context = sessions.context
        
        guard let p = try context?.views.parseDefinition(state) as? CVUParsedSessionDefinition else {
            throw "Unable to parse state definition"
        }
        
        try withReadRealmThrows { realm in
            self.parsed = p
            
            // Either the views are encoded in the definition
            if
                let parsedViews = self.parsed["viewDefinitions"] as? [CVUParsedViewDefinition],
                parsedViews.count > 0
            {
                for parsed in parsedViews {
                    let view = try CVUStateDefinition.fromCVUParsedDefinition(parsed)
                    _ = try state.link(view, type: "view")
                }
            }
            // Or they are in the database linked as edges
            else {
                guard let storedViewStates = state.edges("view")?
                    .sorted(byKeyPath: "sequence").items(type: CVUStateDefinition.self) else {
                        throw "No views found. Aborting" // TODO should this initialize a default view?
                }
                
                for viewState in storedViewStates {
                    views.append(try CascadingView(viewState, self))
                }
                
                try setCurrentView()
            }
       }
    }
    
    private func setState(_ name:String, _ value: Any?) {
        parsed[name] = value
        schedulePersist()
    }
    
    func schedulePersist() {
        sessions?.schedulePersist()
    }
    
    #warning("Move to separate thread")
    public func persist() throws {
        try withWriteRealmThrows { realm in
            var state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if state == nil {
                debugHistory.warn("Could not find stored CVU. Creating a new one.")
                
                state = try Cache.createItem(CVUStateDefinition.self, values: [:])
                
                guard let uid = state?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                self.uid = uid
            }
            
            state?.set("definition", parsed.toCVUString(0, "    "))
            
            if let stateViewEdges = state?.edges("view")?.sorted(byKeyPath: "sequence") {
                var i = 0
                for edge in stateViewEdges {
                    if edge.targetItemID.value == views[i].uid {
                        i += 1
                        continue
                    }
                    else {
                        break
                    }
                }
                if i < stateViewEdges.count {
                    for j in stride(from: stateViewEdges.count, through: i, by: -1) {
                        try state?.unlink(stateViewEdges[j])
                    }
                }
            }
            
            for view in views {
                try view.persist()
                
                if let s = view.state {
                    _ = try state?.link(s, type: "view", sequence: .last, overwrite: false)
                }
                else {
                    debugHistory.warn("Unable to store view. Missing stored CVU")
                }
            }
        }
    }

    public func setCurrentView (
        _ state: CVUStateDefinition? = nil,
        _ viewArguments: ViewArguments? = nil
    ) throws {
		guard let storedView = state ?? self.currentView?.state else {
            throw "Exception: Unable fetch stored CVU state"
        }
        
        // If the session already exists, we simply update the session index
        if let index = views.firstIndex(where: { view in view.uid == storedView.uid.value }) {
            currentViewIndex = index
        }
        // Otherwise lets create a new session
        else {
            // Remove all items after the current index
            views.removeSubrange(currentViewIndex...)
            
            // Add session to list
            views.append(try CascadingView(storedView, self))
            currentViewIndex = views.count - 1
        }
        
        if sessions?.currentSession != self {
            try sessions?.setCurrentSession(self.state)
        }
		
        storedView.accessed()
        
        #warning("Merge with existing viewArguments on view")
        //.merging(dict, uniquingKeysWith: { _, new in new }) as [String: Any?])
        if let args = viewArguments {
            currentView?.viewArguments = args
        }
        
        try currentView?.load { error in
            if error == nil, let item = currentView?.singleton {
                item.accessed()
            }
        }
        
        // turn off editMode when navigating
        if editMode { editMode = false }

        // hide filterpanel if view doesnt have a button to open it
        if showFilterPanel {
            if currentView?.filterButtons.first(where: { $0.name == .toggleFilterPanel }) != nil {
                showFilterPanel = false
            }
        }
        
        schedulePersist()
    }

	public func takeScreenShot() {
		if let view = UIApplication.shared.windows[0].rootViewController?.view {
			if let uiImage = view.takeScreenShot() {
                
                #warning("Test this")
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        if self.screenshot == nil {
                            let file = try Cache.createItem(File.self,
                                values: ["uri": File.generateFilePath()]
                            )
                            self.screenshot = file
                        }

                        try self.screenshot?.write(uiImage)
                    } catch {
                        debugHistory.error("Unable to write screenshot: \(error)")
                    }
                }

				return
			}
		}

		debugHistory.error("Unable to create screenshot")
	}

	public static func == (lt: Session, rt: Session) -> Bool {
		lt.uid == rt.uid
	}
}

extension UIView {
	func takeScreenShot() -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
		drawHierarchy(in: bounds, afterScreenUpdates: true)

		if let image = UIGraphicsGetImageFromCurrentImageContext() {
			UIGraphicsEndImageContext()
			return image
		}

		return nil
	}
}
