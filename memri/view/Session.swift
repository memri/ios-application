//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation
import Combine


public class Sessions: ObservableObject, Decodable {

    @Published var currentSessionIndex: Int = 0
    @Published var sessions: [Session] = []
    
    var cancellables:[AnyCancellable]? = nil
    
    
//    private enum CodingKeys: String, CodingKey {
//        case sessions, currentSessionIndex
//    }
    
    var currentSession: Session {
        if sessions.count > 0 {
            return sessions[currentSessionIndex]
        }
        else {
            return Session()
        }
    }
    
    init(_ sessions: [Session] = [Session()], currentSessionIndex: Int = 0){
        self.sessions = sessions
        self.currentSessionIndex = currentSessionIndex
        self.cancellables=[]
        self.postInit()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            sessions = try decoder.decodeIfPresent("sessions") ?? sessions
        }
        
        self.postInit()
    }
    
    public func postInit(){
        self.cancellables = []
        for session in sessions{
            self.cancellables?.append(session.objectWillChange.sink { (_) in
                print("session \(session) was changed")
                self.objectWillChange.send()
            })
        }
    }
    
    /**
     *
     */
    public func setCurrentSession(_ session:Session) throws -> Void {
        let index = sessions.firstIndex(of: session) ?? -1
        if (index > 0) { throw "Should never happen" } // Should never happen
        
        currentSessionIndex = index
    }

    /**
     * Find a session using text
     */
    public func findSession(_ query:String) -> Void {}

    /**
     * Clear all sessions and create a new one
     */
    public func clear() -> Void {}
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
        let jsonData = try jsonDataFromFile(file, ext)
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: jsonData)
        return sessions
    }
    
    public class func fromJSONString(_ json: String) throws -> Sessions {
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: Data(json.utf8))
        return sessions
    }
}

public class Session: ObservableObject, Decodable, Equatable {
    var id: String
    
    @Published var currentViewIndex: Int = 0
    @Published var views: [SessionView] = [SessionView()]
    
    var cancellables: [AnyCancellable]?=nil
    
//    private enum CodingKeys: String, CodingKey {
//        case sessionViews, currentSessionViewIndex
//    }
    
    public var currentView: SessionView {
        if currentViewIndex >= 0 {
            return views[currentViewIndex]
        } else{
            return views[0]
        }
    }
    
    init(_ currentViewIndex: Int = 0, views: [SessionView]=[SessionView()]){
        self.id = UUID().uuidString
        self.currentViewIndex = currentViewIndex
        self.views = views
        self.postInit()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            id = try decoder.decodeIfPresent("id") ?? id
            currentViewIndex = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex
            views = try decoder.decodeIfPresent("views") ?? views
        }
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
    
    public func postInit(){
        for sessionView in views{
            cancellables?.append(sessionView.objectWillChange.sink { (_) in
                            self.objectWillChange.send()
            })
        }
    }

    public static func == (lt: Session, rt: Session) -> Bool {
        return lt.id == rt.id
    }
}
