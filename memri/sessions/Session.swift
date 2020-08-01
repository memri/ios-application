//
// Session.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

public final class Session: Equatable, Subscriptable {
    /// The name of the item.
    var name: String? {
        get { parsed?["name"] as? String }
        set(value) { setState("name", value) }
    }

    /// TBD
    var currentViewIndex: Int {
        get { Int(parsed?["currentViewIndex"] as? Double ?? 0) }
        set(value) { setState("currentViewIndex", Double(value)) }
    }

    /// TBD
    var editMode: Bool {
        get { parsed?["editMode"] as? Bool ?? false }
        set(value) { setState("editMode", value) }
    }

    /// TBD
    var showContextPane: Bool {
        get { parsed?["showContextPane"] as? Bool ?? false }
        set(value) { setState("showContextPane", value) }
    }

    /// TBD
    var showFilterPanel: Bool {
        get { parsed?["showFilterPanel"] as? Bool ?? false }
        set(value) { setState("showFilterPanel", value) }
    }

    /// TBD
    var screenshot: File? {
        get {
            state?.edge("screenshot")?.item(type: File.self)
        }
        set(value) {
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

    var uid: Int?
    var parsed: CVUParsedSessionDefinition?
    var state: CVUStateDefinition? {
        DatabaseController.current { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: self.uid)
        }
    }

    /// TBD
    var views = [CascadableView]()
    /// TBD
    var sessions: Sessions?
    var context: MemriContext?

    private var cancellables: [AnyCancellable] = []
    private var lastViewIndex: Int = -1

    var swiftUIEditMode: EditMode {
        get {
            if editMode { return .active }
            else { return .inactive }
        }
        set(value) {
            if value == .active { editMode = true }
            else { editMode = false }
        }
    }

    var hasHistory: Bool {
        currentViewIndex > 0
    }

    public var currentView: CascadableView? {
        views[safe: currentViewIndex]
    }

    init(_ state: CVUStateDefinition?, _ sessions: Sessions) throws {
        self.sessions = sessions
        context = sessions.context

        if let state = state {
            guard let uid = state.uid.value else {
                throw "CVU state object is unmanaged"
            }

            self.uid = uid

            guard let p = try context?.views.parseDefinition(state) as? CVUParsedSessionDefinition
            else {
                throw "Unable to parse state definition"
            }

            parsed = p

            // Check if there are views in the db
            if
                let storedViewStates = state
                .edges("view")?
                .sorted(byKeyPath: "sequence")
                .items(type: CVUStateDefinition.self),
                storedViewStates.count > 0 {
                for viewState in storedViewStates {
                    views.append(try CascadableView(viewState, self))
                }
            }
            // Or if the views are encoded in the definition
            else if
                let parsedViews = parsed?["viewDefinitions"] as? [CVUParsedViewDefinition],
                parsedViews.count > 0 {
                try DatabaseController.tryCurrent(write:true) { _ in
                    for parsed in parsedViews {
                        let viewState = try CVUStateDefinition.fromCVUParsedDefinition(parsed)
                        _ = try state.link(viewState, type: "view", sequence: .last)
                        self.views.append(try CascadableView(viewState, self))
                    }
                }

                parsed?.parsed?.removeValue(forKey: "viewDefinitions")
            }
            else {
                throw "CVU state definition is missing views"
            }
        }
        else {
            // Do nothing and expect a call to setCurrentView later
        }
    }

    subscript(propName: String) -> Any? {
        get {
            switch propName {
            case "name": return name
            case "editMode": return editMode
            case "showContextPane": return showContextPane
            case "showFilterPanel": return showFilterPanel
            case "screenshot": return screenshot
            default: return nil
            }
        }
        set(value) {
            switch propName {
            case "name": name = value as? String
            case "editMode": editMode = value as? Bool ?? false
            case "showContextPane": showContextPane = value as? Bool ?? false
            case "showFilterPanel": showFilterPanel = value as? Bool ?? false
            case "screenshot": screenshot = value as? File
            default:
                // Do nothing
                debugHistory.warn("Unable to set property: \(propName)")
                return
            }
        }
    }

    private func setState(_ name: String, _ value: Any?) {
        if parsed == nil { parsed = CVUParsedSessionDefinition() }
        parsed?[name] = value
        schedulePersist()
    }

    func schedulePersist() {
        sessions?.schedulePersist()
    }

    public func persist() throws {
        DatabaseController.current(write:true) { realm in
            var state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: self.uid)
            if state == nil {
                debugHistory.warn("Could not find stored session CVU. Creating a new one.")

                state = try Cache.createItem(CVUStateDefinition.self, values: [:])

                guard let uid = state?.uid.value else {
                    throw "Exception: could not create state definition"
                }

                self.uid = uid
            }

            state?.set("definition", self.parsed?.toCVUString(0, "    "))

            if let stateViewEdges = state?.edges("view")?.sorted(byKeyPath: "sequence") {
                var i = 0
                for edge in stateViewEdges {
                    #warning("Hard crash when index out of range. Notify developer")
                    if edge.targetItemID.value == self.views[safe: i]?.uid {
                        i += 1
                        continue
                    }
                    else {
                        break
                    }
                }
                if i < stateViewEdges.count {
                    for j in stride(from: stateViewEdges.count - 1, through: i, by: -1) {
                        try state?.unlink(stateViewEdges[j])
                    }
                }
            }

            for view in self.views {
                try view.persist()

                if let s = view.state {
                    _ = try state?.link(s, type: "view", sequence: .last, overwrite: false)
                }
                else {
                    debugHistory.warn("Unable to store view. Missing state CVU")
                }
            }
        }
    }

    public func setCurrentView(
        _ state: CVUStateDefinition? = nil,
        _ viewArguments: ViewArguments? = nil
    ) throws {
        guard let storedView = state ?? currentView?.state else {
            throw "Exception: Unable to fetch stored CVU state for view"
        }

        var nextIndex: Int

        // If the session already exists, we simply update the session index
        if let index = views.firstIndex(where: { view in view.uid == storedView.uid.value }) {
            nextIndex = index
        }
        // Otherwise lets create a new session
        else {
            if currentViewIndex + 1 < views.count {
                // Remove all items after the current index
                views.removeSubrange((currentViewIndex + 1)...)
            }

            // Add session to list
            views.append(try CascadableView(storedView, self))
            nextIndex = views.count - 1
        }

        let isReload = lastViewIndex == nextIndex && sessions?.currentSession == self
        lastViewIndex = nextIndex

        if !isReload { storedView.accessed() }

        let nextView = views[nextIndex]
        _ = nextView.viewArguments?.deepMerge(viewArguments)

        try nextView.load { error in
            if !isReload, error == nil, let item = nextView.resultSet.singletonItem {
                item.accessed()
            }
        }

        if sessions?.currentSession != self {
            try sessions?.setCurrentSession(self.state)
        }

        currentViewIndex = nextIndex

        if !isReload {
            // turn off editMode when navigating
            if editMode { editMode = false }

            // hide filterpanel if view doesnt have a button to open it
            if showFilterPanel {
                if currentView?.filterButtons
                    .first(where: { $0.name == .toggleFilterPanel }) == nil {
                    showFilterPanel = false
                }
            }

            schedulePersist()
        }

        // Update the UI
        currentView?.context?.scheduleUIUpdate()
    }

    public func takeScreenShot(immediate: Bool = false) {
        if let view = UIApplication.shared.windows[0].rootViewController?.view {
            if let uiImage = view.takeScreenShot() {
                func doIt() {
                    do {
                        if screenshot == nil {
                            let file = try Cache.createItem(File.self)
                            screenshot = file
                        }

                        try screenshot?.write(uiImage)
                    }
                    catch {
                        debugHistory.error("Unable to write screenshot: \(error)")
                    }
                }

                if immediate { doIt() }
                else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        doIt()
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
