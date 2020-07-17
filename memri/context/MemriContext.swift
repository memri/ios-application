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

public class MemriContext: ObservableObject {
	public var name: String = ""
    
    @Published public var sessions: Sessions
    
	/// The current session that is active in the application
    public var currentSession: Session? {
        sessions.currentSession
    }

    public var currentView: CascadingView? {
        sessions.currentSession?.currentView
    }

	public var views: Views

	public var settings: Settings

	public var installer: Installer

	public var podAPI: PodAPI

	public var indexerAPI: IndexerAPI

	public var cache: Cache

	public var realm: Realm

	public var navigation: MainNavigation

	public var renderers: Renderers

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

	var closeStack = [Binding<PresentationMode>]() // A stack of bindings for the display state of presented popups
    public func addToStack(_ isPresentedBinding: Binding<PresentationMode>) {
        closeStack.append(isPresentedBinding)
    }
    public func closeLastInStack() {
        if let lastVisibleIndex = closeStack.lastIndex(where: { $0.wrappedValue.isPresented }) {
            closeStack[lastVisibleIndex].wrappedValue.dismiss()
            closeStack = Array(closeStack.prefix(upTo: lastVisibleIndex))
        }
    }

	private var scheduled: Bool = false
	private var scheduledComputeView: Bool = false

	func scheduleUIUpdate(immediate: Bool = false, _ check: ((_ context: MemriContext) -> Bool)? = nil) { // Update UI
		let outcome = {
			// Reset scheduled
			self.scheduled = false

			// Update UI
			self.objectWillChange.send()
		}
		if immediate {
			// Do this straight away, usually for the sake of correct animation
			outcome()
			return
		}

		if let check = check {
			guard check(self) else { return }
		}
		// Don't schedule when we are already scheduled
		guard !scheduled else { return }
		// Prevent multiple calls to the dispatch queue
		scheduled = true

		// Schedule update
		DispatchQueue.main.async {
			outcome()
		}
	}

	func scheduleCascadingViewUpdate(immediate: Bool = false) {
		let outcome = {
			// Reset scheduled
			self.scheduledComputeView = false

			// Update UI
            do { try self.currentSession?.setCurrentView() }
			catch {
				// TODO: User error handling
				// TODO: Error Handling
				debugHistory.error("Could not update CascadingView: \(error)")
			}
		}
		if immediate {
			// Do this straight away, usually for the sake of correct animation
			outcome()
			return
		}
		// Don't schedule when we are already scheduled
		if !scheduledComputeView {
			// Prevent multiple calls to the dispatch queue
			scheduledComputeView = true

			// Schedule update
			DispatchQueue.main.async {
				outcome()
			}
		}
	}

	public func getPropertyValue(_ name: String) -> Any {
		let type: Mirror = Mirror(reflecting: self)

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

				scheduleUIUpdate(immediate: true)
			} else {
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

	init(
		name: String,
		podAPI: PodAPI,
		cache: Cache,
		realm: Realm,
		settings: Settings,
		installer: Installer,
		sessions: Sessions,
		views: Views,
		navigation: MainNavigation,
		renderers: Renderers,
		indexerAPI: IndexerAPI
	) {
		self.name = name
		self.podAPI = podAPI
		self.cache = cache
		self.realm = realm
		self.settings = settings
		self.installer = installer
		self.sessions = sessions
		self.views = views
		self.navigation = navigation
		self.renderers = renderers
		self.indexerAPI = indexerAPI

		// TODO: FIX
		self.currentView?.context = self
		self.indexerAPI.context = self
	}
}

public class SubContext: MemriContext {
	let parent: MemriContext

	init(name: String, _ context: MemriContext, _ state: CVUStateDefinition?) throws {
		let views = Views(context.realm)

		parent = context

		super.init(
			name: name,
			podAPI: context.podAPI,
			cache: context.cache,
			realm: context.realm,
			settings: context.settings,
			installer: context.installer,
			sessions: try Sessions(state),
			views: views,
			navigation: context.navigation,
			renderers: context.renderers,
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
    
    #warning("@Toby how can we tell when the sub context is done and how can we clear it?")
    var subContexts = [SubContext]()

	// TODO: Refactor: Should installer be moved to rootmain?

	init(name: String, key: String) throws {
		let podAPI = PodAPI(key)
		let cache = try Cache(podAPI)
		let realm = cache.realm
        let views = Views(realm)

		globalCache = cache // TODO: remove this and fix edges

		MapHelper.shared.realm = realm // TODO: How to access realm in a better way?
        
        let sessionState = try Cache.createItem(
            CVUStateDefinition.self,
            values: ["uid": try Cache.getDeviceID()]
        )

		super.init(
			name: name,
			podAPI: podAPI,
			cache: cache,
			realm: realm,
			settings: Settings(realm),
			installer: Installer(realm),
			sessions: try Sessions(sessionState),
			views: views,
			navigation: MainNavigation(realm),
			renderers: Renderers(),
			indexerAPI: IndexerAPI()
		)

		currentView?.context = self

		let takeScreenShot = { () -> Void in
			// Make sure to record a screenshot prior to session switching
			self.currentSession?.takeScreenShot() // Optimize by only doing this when a property in session/view/dataitem has changed
		}

		// TODO: Refactor: This is a mess. Create a nice API, possible using property wrappers
		aliases = [
			"showSessionSwitcher": Alias(key: "device/gui/showSessionSwitcher", type: "bool", on: takeScreenShot),
			"showNavigation": Alias(key: "device/gui/showNavigation", type: "bool", on: takeScreenShot),
		]

		cache.scheduleUIUpdate = { [weak self] in self?.scheduleUIUpdate($0) }
		navigation.scheduleUIUpdate = { [weak self] in self?.scheduleUIUpdate($0) }

		// Make settings global so it can be reached everywhere
		globalSettings = settings
	}

    public func createSubContext(_ state: CVUStateDefinition? = nil) throws -> MemriContext {
		let subContext = try SubContext(name: "Proxy", self, state)
        subContexts.append(subContext)
        return subContext
	}

    public func boot(_ callback:(() -> Void)? = nil) throws {
		// Make sure memri is installed properly
		try installer.installIfNeeded(self) {
			#if targetEnvironment(simulator)
				// Reload for easy adjusting
				self.views.context = self
				try self.views.install()
			#endif

			// Load views configuration
			try self.views.load(self) {
                
                try sessions.load(self)
                
				// Update view when sessions changes
				self.cancellable = self.sessions.objectWillChange.sink { _ in
					self.scheduleUIUpdate()
				}

				// Load current view
                self.currentSession?.setCurrentView()
//                try self.cascadingView?.load()()
                
                callback?()
			}
		}
	}

	public func mockBoot() -> MemriContext {
		do {
			try boot()
			return self
		} catch { print(error) }

		return self
	}
}
