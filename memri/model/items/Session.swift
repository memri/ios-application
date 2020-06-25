//
//  Session.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class Session: SchemaSession {
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    
    required init() {
        super.init()
       
        self.postInit()
    }
    
    func postInit(){
        if realm != nil {
            for view in views{
                decorate(view)
            }
            
            rlmTokens.append(self.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
    }
    
    func decorate(_ view:SessionView) {
        // Set the .session property on views for easy querying
        if view.session == nil { realmWriteIfAvailable(realm) { view.session = self } }
        
        // Observe and process changes for UI updates
        if realm != nil {
            // TODO Refactor: What is the impact of this not happening in subviews
            //                The impact is that for instance clicking on the showFilterPanel button
            //                is not working. The UI won't update. Perhaps we need to implement
            //                our own pub/sub structure. More thought is needed.
            
            rlmTokens.append(view.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
    }

    var isEditMode: Bool {
        get {
            editMode
        }
        set {
            realmWriteIfAvailable(self.realm) {
                self.editMode = newValue
            }
        }
    }
 
    var swiftUIEditMode: EditMode {
        get {
            if editMode { return .active }
            else { return .inactive }
        }
        set (value) {
            realmWriteIfAvailable(self.realm) {
                if value == .active { self.editMode = true }
                else { self.editMode = false }
            }
        }
    }
    
    var hasHistory: Bool {
        self.currentViewIndex > 0
    }
    
    public var currentView: SessionView {
        return views.count > 0 ? views[currentViewIndex] : SessionView()
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public func setCurrentView(_ view:SessionView) {
        if let index = views.firstIndex(of: view) {
            realmWriteIfAvailable(realm) {
                currentViewIndex = index
            }
        }
        else {
            realmWriteIfAvailable(realm) {
                // Remove all items after the current index
                views.removeSubrange((currentViewIndex + 1)...)
                
                // Add the view to the session
                views.append(view)
                
                // Update the index pointer
                currentViewIndex = views.count - 1
            }
            
            decorate(view)
        }
    }
    
    public func takeScreenShot(){
        if let view = UIApplication.shared.windows[0].rootViewController?.view {
            let uiImage = view.takeScreenShot()
            
            if self.screenshot == nil {
                let doIt = { self.screenshot = File(value: ["uri": File.generateFilePath()]) }
                
                realmWriteIfAvailable(realm) {
                    doIt()
                }
            }
            
            do {
                try self.screenshot?.write(uiImage)
            }
            catch let error {
                print(error)
            }
        }
        else {
            print("No view available")
        }
    }
    
    public class func fromCVUDefinition(_ def:CVUParsedSessionDefinition) throws -> Session {
        let views = try (def["viewDefinitions"] as? [CVUParsedViewDefinition] ?? [])
            .map { try SessionView.fromCVUDefinition(parsed: $0) }
        
        return Session(value: [
            "selector": (def.selector ?? "[session]") as Any,
            "name": (def["name"] as? String ?? "") as Any,
            "currentViewIndex": Int(def["currentViewIndex"] as? Double ?? 0),
            "showFilterPanel": (def["showFilterPanel"] as? Bool ?? false) as Any,
            "showContextPane": (def["showContextPane"] as? Bool ?? false) as Any,
            "editMode": (def["editMode"] as? Bool ?? false) as Any,
            "screenshot": def["screenshot"] as? File as Any,
            "views": views
        ])
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Session {
        let jsonData = try jsonDataFromFile(file, ext)
        let session:Session = try MemriJSONDecoder.decode(Session.self, from: jsonData)
        return session
    }
    
    public class func fromJSONString(_ json: String) throws -> Session {
        let session:Session = try MemriJSONDecoder.decode(Session.self, from: Data(json.utf8))
        return session
    }

    public static func == (lt: Session, rt: Session) -> Bool {
        return lt.memriID == rt.memriID
    }
}

//extension UIView {
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
//}
//
//extension View {
//    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
//        let window = UIWindow(frame: CGRect(origin: origin, size: size))
//        let hosting = UIHostingController(rootView: self)
//        hosting.view.frame = window.frame
//        window.addSubview(hosting.view)
//        window.makeKeyAndVisible()
//        return hosting.view.renderedImage
//    }
//}

//func image(with view: UIView) -> UIImage? {
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
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return image
        }
        
        return nil
    }
}
