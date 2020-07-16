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

public final class Session {
    /// The name of the item.
    var name:String? {
        get { parsed["name"] }
        set (value) { parsed["name"] = value }
    }
    /// TBD
    var currentViewIndex:Int {
        get { parsed["currentViewIndex"] as? Int ?? 0 }
        set (value) { parsed["currentViewIndex"] = value }
    }
    /// TBD
    var editMode:Bool {
        get { parsed["editMode"] ?? false }
        set (value) { parsed["editMode"] = value }
    }
    /// TBD
    var showContextPane:Bool {
        get { parsed["showContextPane"] ?? false }
        set (value) { parsed["showContextPane"] = value }
    }
    /// TBD
    var showFilterPanel:Bool  {
        get { parsed["showFilterPanel"] ?? false }
        set (value) { parsed["showFilterPanel"] = value }
    }

    /// TBD
    var screenshot: File? {
        withRealm { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
                .edge("screenshot")?.target(type:File.self)
        }
    }

    var uid: Int
    var parsed: CVUParsedSessionDefinition
    var stored: CVUStoredDefinition? {
        try withRealm { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        } as? CVUStoredDefinition
    }
    
    /// TBD
    var views: [CascadingView]
    
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

    init(_ state: CVUStateDefinition) {
        uid = state.uid.value
        
        // Fetch views and parse them
        
        //
        //        edges("session")?.sorted(byKeyPath: "sequence").items(type:Session.self)
        //
        //        var parsed = try context.views.parseDefinition(stored)
        //
        //        if parsed is CVUParsedSessionDefinition {
        //            if let list = parsed?["views"] as? [CVUParsedViewDefinition] { parsed = list.first }
        //        }
        //
        //
        //        let state = try CVUStateDefinition.fromCVUStoredDefinition(stored)
        //        let view = try CascadingView(state, proxyMain)
        //        view.set("viewArguments", args)
        //
        //
        //        _ = try session.link(view, type: "view")
        //
        //        sessions?.setCurrentSession(session)
        
    }
    
    public func persist() throws {
        _ = try withRealm { realm in
            var stored = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if stored == nil {
                stored = try Cache.createItem(CVUStateDefinition.self, values: [:])
                
                guard let uid = stored?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                self.uid = uid
                
                // TODO Warn??
            }
            
            stored?.set("definition", parsed.toCVUString(0, "    "))
                
                // TODO views
    //            if let screenshot = def["screenshot"] as? File {
    //                session.set("screenshot", screenshot)
    //            }
            
            for view in views {
                try view.persist()
                
                if let s = view.stored {
                    _ = try stored?.link(s, type: "view", sequence: .last, overwrite: false)
                }
                else {
                    debugHistory.warn("Unable to store view. Missing stored CVU")
                }
            }
        }
    }
    
//    private func maybeLogRead() throws {
//        if let item = cascadingView?.resultSet.singletonItem {
//            let auditItem = try Cache.createItem(AuditItem.self, values: ["action": "read"])
//            _ = try item.link(auditItem, type: "changelog")
//        }
//    }
//
//    private func maybeLogUpdate() throws {
//        if cascadingView?.context == nil { return }
//
//        let syncState = cascadingView?.resultSet.singletonItem?.syncState
//        if let syncState = syncState, syncState.changedInThisSession {
//            let fields = syncState.updatedFields
//            // TODO: serialize
//            if let item = cascadingView?.resultSet.singletonItem {
//                let auditItem = try Cache.createItem(AuditItem.self, values: [
//                    "contents": try serialize(AnyCodable(Array(fields))),
//                    "action": "update",
//                ])
//                _ = try item.link(auditItem, type: "changelog")
//                realmWriteIfAvailable(realm) { syncState.changedInThisSession = false }
//            } else {
//                print("Could not log update, no Item found")
//            }
//        }
//    }

	public func setCurrentView(_ view: CascadingView? = nil) throws {
		guard let views = views else { return }
        
        // when view is not set (called during init) we (re)load the current view

		realmWriteIfAvailable(realm) {
			if let index = views.firstIndex(of: view) {
				currentViewIndex = index
			} else {
				// Remove all items after the current index
				if let list = edges("view")?.sorted(byKeyPath: "sequence") {
					for i in stride(from: list.count - 1, to: currentViewIndex, by: -1) {
						try self.unlink(list[i])
					}
				}

				// Add the view to the session
				if let edge = try self.link(view, type: "view", order: .last),
					let index = edges("view")?.index(of: edge) {
					// Update the index pointer
					currentViewIndex = index
				} else {
					throw "Could not set current view"
				}
			}
		}
        
        /*
         
             try context?.maybeLogUpdate()
         
             guard let cascadingView = sessions?.currentView else {
                 throw "Exception: currentView is not set"
             }
         
             // Update current session
             currentSession = sessions?.currentSession // TODO: filter to a single property

             // Set accessed date to now
             view.access()

             // Recompute view
             try context.updateCascadingView() // scheduleCascadingViewUpdate()
         
            cascadingView.load { error in
                try cascadingView.context?.maybeLogRead()
            }
         
         self.currentSession?.access()
         self.currentSession?.currentView?.access()
            
         */

		decorate(view)
	}
    
    #warning("Merge with setCurrentView above")
    public func createCascadingView(_ sessionView: SessionView? = nil) throws -> CascadingView {
        guard let context = self.context else {
            throw "Exception: MemriContext is not defined in views"
        }

        var cascadingView: CascadingView
        if let viewFromSession = sessionView ?? context.sessions?.currentSession?.currentView {
            cascadingView = try CascadingView.fromSessionView(viewFromSession, in: context)
        } else {
            throw "Unable to find currentView"
        }

        // TODO: REFACTOR: move these to a better place (context??)

        // turn off editMode when navigating
        if context.sessions?.currentSession?.editMode == true {
            realmWriteIfAvailable(realm) {
                context.sessions?.currentSession?.editMode = false
            }
        }

        // hide filterpanel if view doesnt have a button to open it
        if context.sessions?.currentSession?.showFilterPanel ?? false {
            if cascadingView.filterButtons.filter({ $0.name == .toggleFilterPanel }).count == 0 {
                realmWriteIfAvailable(realm) {
                    context.sessions?.currentSession?.showFilterPanel = false
                }
            }
        }

        return cascadingView
    }

	public func takeScreenShot() {
		if let view = UIApplication.shared.windows[0].rootViewController?.view {
			if let uiImage = view.takeScreenShot() {
				do {
					if screenshot == nil {
						let file = try Cache.createItem(File.self,
														values: ["uri": File.generateFilePath()])
						set("screenshot", file)
					}

					if let screenshot = screenshot {
						try screenshot.write(uiImage)
					}
				} catch {
					debugHistory.error("Unable to write screenshot: \(error)")
				}

				return
			}
		}

		debugHistory.error("Unable to create screenshot")
	}

	public static func == (lt: Session, rt: Session) -> Bool {
		lt.uid.value == rt.uid.value
	}
}

// extension UIView {
//    var renderedImage: UIImage {
//        // rect of capure
//        let rect = self.bounds
//        // create the context of bitmap
//        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
//        let context: CGContext = UIGraphicsGetCurrentContext()!
//        self.layer.render(in: context)
//        // get a image from current context bitmap
//        let capturedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return capturedImage
//    }
// }
//
// extension View {
//    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
//        let window = UIWindow(frame: CGRect(origin: origin, size: size))
//        let hosting = UIHostingController(rootView: self)
//        hosting.view.frame = window.frame
//        window.addSubview(hosting.view)
//        window.makeKeyAndVisible()
//        return hosting.view.renderedImage
//    }
// }

// func image(with view: UIView) -> UIImage? {
//
//       UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
//
//       defer { UIGraphicsEndImageContext() }
//
//       if let context = UIGraphicsGetCurrentContext() {
//
//           view.layer.render(in: context)
//
//           if let image = UIGraphicsGetImageFromCurrentImageContext() {
//
//
//
//               return image
//
//           }
//
//
//
//           return nil
//
//       }
//
//       return nil
//
//   }

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
