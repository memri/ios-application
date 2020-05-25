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

public class Session: DataItem {
 
    override var genericType:String { "Session" }
 
    @objc dynamic var name: String = ""
 
    @objc dynamic var currentViewIndex: Int = 0
 
    let views = RealmSwift.List<SessionView>() // @Published
 
    @objc dynamic var showFilterPanel:Bool = false
 
    @objc dynamic var showContextPane:Bool = false
 
    @objc dynamic var editMode:Bool = false
 
    @objc dynamic var screenshot:File? = nil
    
 
    var isEditMode: EditMode {
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
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    
    var backButton: Action? {
        if self.currentViewIndex > 0 {
            return Action("back")
        }
        else {
            return nil
        }
    }
    
    public var currentView: SessionView {
        return views.count > 0 ? views[currentViewIndex] : SessionView()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentViewIndex = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex
            showFilterPanel = try decoder.decodeIfPresent("showFilterPanel") ?? showFilterPanel
            showContextPane = try decoder.decodeIfPresent("showContextPane") ?? showContextPane
            editMode = try decoder.decodeIfPresent("editMode") ?? editMode
            
            decodeIntoList(decoder, "views", self.views)
            
            try super.superDecode(from: decoder)
        }
        
//        self.postInit()
    }
    
    required init() {
        super.init()
        
        self.postInit()
    }
    
    public func postInit(){
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
    
    private func decorate(_ view:SessionView) {
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
            
            // NOTE: Allowed force unwrapping
            do {
                try self.screenshot!.write(uiImage)
            }
            catch let error {
                print(error)
            }
        }
        else {
            print("No view available")
        }
    }
    
    public class func fromCVUDefinition(_ def:CVUParsedSessionDefinition) -> Session {
        let views = (def["viewDefinitions"] as? [CVUParsedViewDefinition] ?? [])
            .map { SessionView.fromCVUDefinition($0) }
        
        return Session(value: [
            "selector": def.selector ?? "[session]",
            "name": def["name"] as? String ?? "",
            "currentViewIndex": def["currentViewIndex"] as? Int ?? 0,
            "showFilterPanel": def["showFilterPanel"] as? Bool ?? false,
            "showContextPane": def["showContextPane"] as? Bool ?? false,
            "editMode": def["editMode"] as? Bool ?? false,
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
        return lt.uid == rt.uid
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

    func takeScreenShot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)

        drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        // NOTE: Allowed force unwrap
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
