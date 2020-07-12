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

public class Session: SchemaSession {
	private var rlmTokens: [NotificationToken] = []
	private var cancellables: [AnyCancellable] = []

	required init() {
		super.init()

		postInit()
	}

	func postInit() {
		if realm != nil, let views = views {
			for view in views {
				decorate(view)
			}

			rlmTokens.append(observe { objectChange in
				if case .change = objectChange {
					#warning("Modify this to support Combine properly")
//					self.objectWillChange.send()
				}
            })
		}
	}

	func decorate(_ view: SessionView) {
		// Set the .session property on views for easy querying
		if view.session == nil { realmWrite(realm) { view.set("session", self) } }

		// Observe and process changes for UI updates
		if realm != nil {
			// TODO: Refactor: What is the impact of this not happening in subviews
			//                The impact is that for instance clicking on the showFilterPanel button
			//                is not working. The UI won't update. Perhaps we need to implement
			//                our own pub/sub structure. More thought is needed.

			rlmTokens.append(view.observe { objectChange in
				if case .change = objectChange {
					#warning("Modify this to support Combine properly")
//					self.objectWillChange.send()
				}
            })
		}
	}

	var isEditMode: Bool {
		get {
			editMode
		}
		set {
			realmWrite(realm) {
				self.editMode = newValue
			}
		}
	}

	var swiftUIEditMode: EditMode {
		get {
			if editMode { return .active }
			else { return .inactive }
		}
		set(value) {
			realmWrite(realm) {
				if value == .active { self.editMode = true }
				else { self.editMode = false }
			}
		}
	}

	var hasHistory: Bool {
		currentViewIndex > 0
	}

	public var currentView: SessionView? {
		views?[currentViewIndex]
	}

	//    deinit {
	//        if let realm = self.realm {
	//            try! realm.write {
	//                realm.delete(self)
	//            }
	//        }
	//    }

	public func setCurrentView(_ view: SessionView) throws {
		guard let views = views else { return }

		realmWrite(realm) {
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

		decorate(view)
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

	public class func fromCVUDefinition(_ def: CVUParsedSessionDefinition) throws -> Session {
		let views = try (def["viewDefinitions"] as? [CVUParsedViewDefinition] ?? [])
			.map { try SessionView.fromCVUDefinition(parsed: $0) }

        let values:[String:Any?] = [
            "selector": (def.selector ?? "[session]"),
            "name": (def["name"] as? String ?? ""),
            "currentViewIndex": Int(def["currentViewIndex"] as? Double ?? 0),
            "showFilterPanel": (def["showFilterPanel"] as? Bool ?? false),
            "showContextPane": (def["showContextPane"] as? Bool ?? false),
            "editMode": (def["editMode"] as? Bool ?? false),
        ]
        
		let session = try Cache.createItem(Session.self, values: values)

		if let screenshot = def["screenshot"] as? File {
			session.set("screenshot", screenshot)
		}
		if views.count > 0 {
			for view in views {
				_ = try session.link(view, type: "view")
			}
		}

		return session
	}

	public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Session {
		let jsonData = try jsonDataFromFile(file, ext)
		let session: Session = try MemriJSONDecoder.decode(Session.self, from: jsonData)
		return session
	}

	public class func fromJSONString(_ json: String) throws -> Session {
		let session: Session = try MemriJSONDecoder.decode(Session.self, from: Data(json.utf8))
		return session
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
