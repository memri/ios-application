//
// MemriContext.swift
// Copyright © 2020 memri. All rights reserved.

import AnyCodable
import Combine
import Foundation
import RealmSwift
import SwiftUI

/*
 Notes on documentation

 We use the following documentation keywords
 - bug
 - Remark
 - Requires
 - See also
 - warning

 Also remember, when using markdown in your documentation
 - Use backticks for code
 */

// TODO: Remove this and find a solution for Edges
var globalCache: Cache?

protocol Subscriptable {
    subscript(propName: String) -> Any? { get set }
}

public class MemriContext: ObservableObject, Subscriptable {
    public var name: String = ""

    @Published public var sessions: Sessions

    /// The current session that is active in the application
    public var currentSession: Session? {
        sessions.currentSession
    }

    public var currentView: CascadableView? {
        sessions.currentSession?.currentView
    }

    public var currentRendererController: RendererController?

    public var views: Views

    public var settings: Settings

    public var installer: Installer

    public var podAPI: PodAPI

    public var indexerAPI: IndexerAPI

    public var cache: Cache

    public var navigation: MainNavigation

    public var items: [Item] {
        get {
            currentView?.resultSet.items ?? []
        }
        set {
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED2")
        }
    }

    public var item: Item? {
        get {
            currentView?.resultSet.singletonItem
        }
        set {
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED")
        }
    }

    var closeStack =
        [Binding<PresentationMode>]() // A stack of bindings for the display state of presented popups
    public func addToStack(_ isPresentedBinding: Binding<PresentationMode>) {
        closeStack.append(isPresentedBinding)
    }

    public func closeLastInStack() {
        if let lastVisibleIndex = closeStack.lastIndex(where: { $0.wrappedValue.isPresented }) {
            closeStack[lastVisibleIndex].wrappedValue.dismiss()
            closeStack = Array(closeStack.prefix(upTo: lastVisibleIndex))
        }
    }

    private var uiUpdateSubject = PassthroughSubject<Void, Never>()
    private var uiUpdateCancellable: AnyCancellable?

    private var cascadableViewUpdateSubject = PassthroughSubject<Void, Never>()
    private var cascadableViewUpdateCancellable: AnyCancellable?

    func scheduleUIUpdate(
        updateWithAnimation: Bool = false,
        _ check: ((_ context: MemriContext) -> Bool)? = nil
    ) { // Update UI
        if updateWithAnimation {
            DispatchQueue.main.async {
                withAnimation {
                    self.objectWillChange.send()
                    self.currentRendererController?.update()
                }
            }
            return
        }

        if let check = check {
            guard check(self) else { return }
        }

        // Queue an update
        uiUpdateSubject.send()
    }

    func scheduleCascadableViewUpdate(immediate: Bool = false) {
        if immediate {
            // Do this straight away, usually for the sake of correct animation
            do { try currentSession?.setCurrentView() }
            catch {
                // TODO: User error handling
                // TODO: Error Handling
                debugHistory.error("Could not update CascadableView: \(error)")
            }
            return
        }
        else {
            cascadableViewUpdateSubject.send()
        }
    }

    public func getPropertyValue(_ name: String) -> Any {
        let type = Mirror(reflecting: self)

        for child in type.children {
            if child.label == name || child.label == "_" + name {
                return child.value
            }
        }

        return ""
    }

    struct Alias {
        var key: String
        var type: String
        var on: (() -> Void)?
        var off: (() -> Void)?
    }

    var aliases: [String: Alias] = [:]

    subscript(propName: String) -> Any? {
        get {
            if let alias = aliases[propName] {
                switch alias.type {
                case "bool":
                    let value: Bool? = settings.get(alias.key)
                    return value ?? false
                case "string":
                    let value: String? = settings.get(alias.key)
                    return value ?? ""
                case "int":
                    let value: Int? = settings.get(alias.key)
                    return value ?? 0
                case "double":
                    let value: Double? = settings.get(alias.key)
                    return value ?? 0
                default:
                    return nil
                }
            }

            return nil
        }
        set(newValue) {
            if let alias = aliases[propName] {
                settings.set(alias.key, AnyCodable(newValue))

                if let x = newValue as? Bool { x ? alias.on?() : alias.off?() }

                let shouldAnimate = (propName == "showNavigation")

                scheduleUIUpdate(updateWithAnimation: shouldAnimate)
            }
            else {
                print("Cannot set property \(propName), does not exist on context")
            }
        }
    }

    public var showSessionSwitcher: Bool {
        get { self["showSessionSwitcher"] as? Bool == true }
        set(value) { self["showSessionSwitcher"] = value }
    }

    public var showNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in self?.showNavigation ?? false },
            set: { [weak self] in self?.showNavigation = $0 }
        )
    }

    public var showNavigation: Bool {
        get { self["showNavigation"] as? Bool == true }
        set(value) { self["showNavigation"] = value }
    }

    public func getSelection() -> [Item] {
        currentView?.userState.get("selection") ?? []
    }

    public func setSelection(_ selection: [Item]) {
        currentView?.userState.set("selection", selection)
        scheduleUIUpdate()
    }

    public var editMode: Bool {
        get { currentSession?.editMode ?? false }
        set {
            currentSession?.editMode = newValue
            scheduleUIUpdate()
        }
    }
    
    var allItemsSelected: Bool {
        getSelection().count >= items.count
    }

    var selectedIndicesBinding: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: {
                Set(self.getSelection().compactMap { self.items.firstIndex(of: $0) })
            },
            set: {
                self.setSelection($0.compactMap { self.items[safe: $0] })
            }
        )
    }

    init(
        name: String,
        podAPI: PodAPI,
        cache: Cache,
        settings: Settings,
        installer: Installer,
        sessions: Sessions,
        views: Views,
        navigation: MainNavigation,
        indexerAPI: IndexerAPI
    ) {
        self.name = name
        self.podAPI = podAPI
        self.cache = cache
        self.settings = settings
        self.installer = installer
        self.sessions = sessions
        self.views = views
        self.navigation = navigation
        self.indexerAPI = indexerAPI

        // TODO: FIX
        currentView?.context = self
        self.indexerAPI.context = self

        // Setup update publishers
        uiUpdateCancellable = uiUpdateSubject
            .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
                self?.currentRendererController?.update()
            }

        // Setup update publishers
        cascadableViewUpdateCancellable = cascadableViewUpdateSubject
            .throttle(for: .milliseconds(500), scheduler: RunLoop.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                try? self?.currentSession?.setCurrentView()
            }
    }
}

public class SubContext: MemriContext {
    let parent: MemriContext

    init(name: String, _ context: MemriContext, _ state: CVUStateDefinition?) throws {
        let views = Views()

        parent = context

        super.init(
            name: name,
            podAPI: context.podAPI,
            cache: context.cache,
            settings: context.settings,
            installer: context.installer,
            sessions: try Sessions(state),
            views: views,
            navigation: context.navigation,
            indexerAPI: context.indexerAPI
        )

        closeStack = context.closeStack

        views.context = self

        try sessions.load(self)
    }
}

/// Represents the entire application user interface. One can imagine in the future there being multiple applications, each aimed at a
///  different way to represent the data. For instance an application that is focussed on voice-first instead of gui-first.
public class RootContext: MemriContext {
    private var cancellable: AnyCancellable?

    var subContexts = [SubContext]()

    // TODO: Refactor: Should installer be moved to rootmain?

    init(name: String) throws {
        let podAPI = PodAPI()
        let cache = try Cache(podAPI)
        let views = Views()

        globalCache = cache // TODO: remove this and fix edges

        super.init(
            name: name,
            podAPI: podAPI,
            cache: cache,
            settings: Settings(),
            installer: Installer(),
            sessions: try Sessions(isDefault: true),
            views: views,
            navigation: MainNavigation(),
            indexerAPI: IndexerAPI()
        )

        currentView?.context = self

        // TODO: Refactor: This is a mess. Create a nice API, possible using property wrappers
        // Optimize by only doing this when a property in session/view/dataitem has changed
        aliases = [
            "showSessionSwitcher": Alias(
                key: "device/gui/showSessionSwitcher",
                type: "bool",
                on: { self.currentSession?.takeScreenShot(immediate: true) }
            ),
            "showNavigation": Alias(
                key: "device/gui/showNavigation",
                type: "bool",
                on: { self.currentSession?.takeScreenShot() }
            ),
        ]

        cache.scheduleUIUpdate = { [weak self] in self?.scheduleUIUpdate($0) }
        navigation.scheduleUIUpdate = { [weak self] in self?.scheduleUIUpdate($0) }
    }

    public func createSubContext(_ state: CVUStateDefinition? = nil) throws -> MemriContext {
        let subContext = try SubContext(name: "Proxy", self, state)
        subContexts.append(subContext)
        return subContext
    }

    public func boot(isTesting: Bool = false, _ callback: @escaping (Error?) -> Void) {
        func doBoot() {
            do {
                // Load views configuration
                try views.load(self)

                // Stop here is we're testing
                if isTesting {
                    callback(nil)
                    return
                }

                // Load session
                try sessions.load(self)

                // Update view when sessions changes
                cancellable = sessions.objectWillChange.sink { _ in
                    self.scheduleUIUpdate()
                }

                // Load current view
                try currentSession?.setCurrentView()

                // Start syncing
                cache.sync.load()

                callback(nil)
            }
            catch {
                callback(error)
            }
        }

        if !isTesting {
            DatabaseController.clean { error in
                DispatchQueue.main.async {
                    if let error = error {
                        callback(error)
                        return
                    }

                    #if targetEnvironment(simulator)
                        // Reload for easy adjusting
                        self.views.context = self

                        self.views.install { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    callback(error)
                                    return
                                }

                                doBoot()
                            }
                        }
                    #else
                        doBoot()
                    #endif
                }
            }
        }
        else {
            doBoot()
        }
    }

    public func mockBoot() -> MemriContext {
        boot { _ in }
        return self
    }
}
