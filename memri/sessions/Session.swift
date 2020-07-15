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
        get { parsed["currentViewIndex"] ?? 0 }
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
    
    /// TBD
    var views: [CascadingView]
//        Results<SessionView>? {
//        edges("view")?.sorted(byKeyPath: "sequence").items(type:SessionView.self)
//    }
    
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

    init() {

        // Fetch views and parse them
        
    }

	public func setCurrentView(_ view: SessionView) throws {
		guard let views = views else { return }

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
