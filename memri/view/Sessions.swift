//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class Sessions: DataItem {
 
    override var genericType:String { "sessions" }
 
    @objc dynamic var currentSessionIndex: Int = 0
 
    let sessions = RealmSwift.List<Session>()
 
    var currentSession: Session {
        return sessions.count > 0 ? sessions[currentSessionIndex] : Session()
    }
 
    var currentView: SessionView {
        return currentSession.currentView
    }
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
            decodeIntoList(decoder, "sessions", self.sessions)
            
            try! super.superDecode(from:decoder)
        }
        
        self.postInit()
    }
    
    public convenience init(_ realm:Realm) {
        self.init()
        
        fetchUID(realm)
        
        self.postInit()
    }
    
    required init() {
        super.init()
    }
    
    private func postInit(){
        for session in sessions {
            decorate(session)
            session.postInit()
        }
    }
    
    private func decorate(_ session:Session) {
        if realm != nil {
            rlmTokens.append(session.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
    }
    
    private func fetchUID(_ realm:Realm){
        // When the uid is not yet set
        if self.uid.contains("0xNEW") {
            
            // Fetch device name
            let setting = realm.objects(Setting.self).filter("key = 'device/name'").first
            if let setting = setting {
                
                // Set it as the uid
                self.uid = unserialize(setting.json)
            }
        }
    }
    
    public func setCurrentSession(_ session:Session) {
        try! realm!.write {
            
            if let index = sessions.firstIndex(of: session) {
                sessions.remove(at: index)
            }
            
            // Add session to array
            sessions.append(session)
            
            // Update the index pointer
            currentSessionIndex = sessions.count - 1
        }
        
        decorate(session)
    }
    
 
    public func load(_ realm:Realm, _ ch:Cache, _ callback: () -> Void) throws {
        
        // Determine self.uid
        fetchUID(realm)
        
        if self.uid == "" {
            print("Error: installation has been corrupted")
            uid = "unknown"
        }
        
        // Activate this session to make sure its stored in realm
        if let fromCache = realm.object(ofType: Sessions.self, forPrimaryKey: self.uid) {
            // Sync with the cached version
            try! self.merge(fromCache)
            
            // Turn myself in a managed object by realm
            try! realm.write { realm.add(self, update: .modified) }
            
            // Add listeners to all session objects
            postInit()
            
            // Notify Main of any changes
            rlmTokens.append(self.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
        else {
            throw "Exception: Could not initialize sessions"
        }

        // Done
        callback()
    }
    
 
    public func install(_ realm:Realm) {
        // Load default sessions from the package
        let defaultSessions:Sessions = try! Sessions.fromJSONFile("default_sessions")
        
        fetchUID(realm)
        
        // Force same primary key
        defaultSessions.uid = self.uid
        
        // Store session
        try! realm.write {
            realm.add(defaultSessions, update: .modified)
        }
    }
    
    public func merge(_ sessions:Sessions) throws {
        func doMerge() {
            let properties = self.objectSchema.properties
            for prop in properties {
                if prop.name == "sessions" {
                    self.sessions.append(objectsIn: sessions.sessions)
                }
                else {
                    self[prop.name] = sessions[prop.name]
                }
            }
        }

        if let realm = realm { try! realm.write { doMerge() } }
        else { doMerge() }
    }
    
    /// Find a session using text
    public func findSession(_ query:String) -> Void {}

    /// Clear all sessions and create a new one
    public func clear() -> Void {}
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
        let jsonData = try jsonDataFromFile(file, ext)
        let sessions:Sessions = try MemriJSONDecoder.decode(Sessions.self, from: jsonData)
        return sessions
    }
    
    public class func fromJSONString(_ json: String) throws -> Sessions {
        let sessions:Sessions = try MemriJSONDecoder.decode(Sessions.self, from: Data(json.utf8))
        return sessions
    }
}

public class Session: DataItem {
 
    override var genericType:String { "session" }
 
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
    
    var backButton: ActionDescription? {
        if self.currentViewIndex > 0 {
            return ActionDescription(actionName: .back)
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
            
            try! super.superDecode(from: decoder)
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
        if view.session == nil {
            realmWriteIfAvailable(realm) { view.session = self }
        }
        
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
        let view = UIApplication.shared.windows[0].rootViewController?.view
        let uiImage = view!.takeScreenShot()
        
        if self.screenshot == nil {
            let doIt = { self.screenshot = File(value: ["uri": File.generateFilePath()]) }
            
            if realm!.isInWriteTransaction { doIt() }
            else { try! realm!.write { doIt() } }
        }
        
        do {
            try self.screenshot!.write(uiImage)
        }
        catch let error {
            print(error)
        }
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

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
