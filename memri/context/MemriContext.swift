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
	/// The current session that is active in the application
	@Published public var currentSession: Session = Session()

	@Published public var cascadingView: CascadingView

	@Published public var sessions: Sessions

	public var views: Views

	public var settings: Settings

	public var installer: Installer

	public var podAPI: PodAPI

	public var indexerAPI: IndexerAPI

	public var cache: Cache

	public var realm: Realm

	public var navigation: MainNavigation

	public var renderers: Renderers

	public var items: [DataItem] {
		get {
			cascadingView.resultSet.items
		}
		set {
			// Do nothing
			print("THIS SHOULD NEVER BE PRINTED2")
		}
	}

	public var item: DataItem? {
		get {
			cascadingView.resultSet.singletonItem
		}
		set {
			// Do nothing
			print("THIS SHOULD NEVER BE PRINTED")
		}
	}

	public var closeStack = [() -> Void]() // A stack of close actions of global popups

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
			do { try self.updateCascadingView() }
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

	public func updateCascadingView() throws {
		maybeLogUpdate()

		// Fetch datasource if not yet parsed yet
		let currentView = sessions.currentView
		if currentView.datasource == nil {
			if let parsedDef = try views.parseDefinition(currentView.viewDefinition) {
				if let ds = parsedDef["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
					realmWriteIfAvailable(realm) {
						// TODO: this is at the wrong moment. Should be done after cascading

						currentView.datasource =
							try Datasource.fromCVUDefinition(ds, currentView.viewArguments)
					}
				} else {
					throw "Exception: Missing datasource in session view"
				}
			} else {
				throw "Exception: Unable to parse view definition"
			}
		}

		if let datasource = currentView.datasource {
			// Fetch the resultset associated with the current view
			let resultSet = cache.getResultSet(datasource)

			// If we can guess the type of the result based on the query, let's compute the view
			if resultSet.determinedType != nil {
				if self is RootContext { // if type(of: self) == RootMain.self {
					debugHistory.info("Computing view "
						+ (currentView.name ?? currentView.viewDefinition?.selector ?? ""))
				}

				do {
					// Calculate cascaded view
					let cascadingView = try views.createCascadingView() // TODO: handle errors better

					// Update current session
					currentSession = sessions.currentSession // TODO: filter to a single property

					// Set the newly cascading view
					self.cascadingView = cascadingView

					// Load data in the resultset of the computed view
					try self.cascadingView.resultSet.load { error in
						if let error = error {
							// TODO: Refactor: Log warning to user
							print("Error: could not load result: \(error)")
						} else {
							maybeLogRead()

							// Update the UI
							scheduleUIUpdate()
						}
					}
				} catch {
					// TODO: Error handling
					// TODO: User Error handling
					debugHistory.error("\(error)")
				}

				// Update the UI
				scheduleUIUpdate()
			}
			// Otherwise let's execute the query first
			else {
				// Updating the data in the resultset of the session view
				try resultSet.load { error in

					// Only update when data was retrieved successfully
					if let error = error {
						// TODO: Error handling
						print("Error: could not load result: \(error)")
					} else {
						// Update the current view based on the new info
						scheduleUIUpdate() // TODO: shouldn't this be setCurrentView??
					}
				}
			}
		} else {
			throw "Exception: Missing datasource in session view"
		}
	}

	private func maybeLogRead() {
		if let item = cascadingView.resultSet.singletonItem {
			realmWriteIfAvailable(realm) {
				self.realm.add(AuditItem(action: "read", appliesTo: [item]))
			}
		}
	}

	private func maybeLogUpdate() {
		if cascadingView.context == nil { return }

		let syncState = cascadingView.resultSet.singletonItem?.syncState
		if let syncState = syncState, syncState.changedInThisSession {
			let fields = syncState.updatedFields
			realmWriteIfAvailable(realm) {
				// TODO: serialize
				if let item = self.cascadingView.resultSet.singletonItem {
					do {
						self.realm.add(AuditItem(
							contents: try serialize(AnyCodable(Array(fields))),
							action: "update",
							appliesTo: [item]
						))
						syncState.changedInThisSession = false
					} catch {
						print(error)
						debugHistory.error("\(error)")
					}
				} else {
					print("Could not log update, no Item found")
				}
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
		cascadingView: CascadingView,
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
		self.cascadingView = cascadingView
		self.navigation = navigation
		self.renderers = renderers
		self.indexerAPI = indexerAPI

		// TODO: FIX
		self.cascadingView.context = self
		self.indexerAPI.context = self
	}
}

public class SubContext: MemriContext {
	let parent: MemriContext

	init(name: String, _ context: MemriContext, _ session: Session) {
		let views = Views(context.realm)

		parent = context

		super.init(
			name: name,
			podAPI: context.podAPI,
			cache: context.cache,
			realm: context.realm,
			settings: context.settings,
			installer: context.installer,
			sessions: Sessions(context.realm),
			views: views,
			cascadingView: context.cascadingView,
			navigation: context.navigation,
			renderers: context.renderers,
			indexerAPI: context.indexerAPI
		)

		closeStack = context.closeStack

		views.context = self

		// For now sessions is unmanaged. TODO: Refactor: we may want to change this.
		sessions.sessions.append(session)
		sessions.currentSessionIndex = 0
	}
}

/// Represents the entire application user interface. One can imagine in the future there being multiple applications, each aimed at a
///  different way to represent the data. For instance an application that is focussed on voice-first instead of gui-first.
public class RootContext: MemriContext {
	private var cancellable: AnyCancellable?

	// TODO: Refactor: Should installer be moved to rootmain?

	init(name: String, key: String) {
		let podAPI = PodAPI(key)
		let cache = Cache(podAPI)
		let realm = cache.realm

		globalCache = cache // TODO: remove this and fix edges

		MapHelper.shared.realm = realm // TODO: How to access realm in a better way?

		super.init(
			name: name,
			podAPI: podAPI,
			cache: cache,
			realm: realm,
			settings: Settings(realm),
			installer: Installer(realm),
			sessions: Sessions(realm),
			views: Views(realm),
			cascadingView: CascadingView(SessionView(), []),
			navigation: MainNavigation(realm),
			renderers: Renderers(),
			indexerAPI: IndexerAPI()
		)

		cascadingView.context = self

		let takeScreenShot = {
			// Make sure to record a screenshot prior to session switching
			self.currentSession.takeScreenShot() // Optimize by only doing this when a property in session/view/dataitem has changed
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

	public func createSubContext(_ session: Session) -> MemriContext {
		SubContext(name: "Proxy", self, session)
	}

	public func boot() throws {
		// Make sure memri is installed properly
		try installer.installIfNeeded(self) {
			// Load settings
			try self.settings.load {
				// Load NavigationCache (from cache and/or api)
				try self.navigation.load {
					#if targetEnvironment(simulator)
						// Reload for easy adjusting
						self.views.context = self
						try self.views.install()
					#endif

					// Load views configuration
					try self.views.load(self) {
						// Load sessions configuration
						try self.sessions.load(realm, cache) {
							// Update view when sessions changes
							self.cancellable = self.sessions.objectWillChange.sink { _ in
								self.scheduleUIUpdate()
							}

							self.currentSession.access()
							self.currentSession.currentView.access()

							// Load current view
							try self.updateCascadingView()
						}
					}
				}
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
