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

    @Published var currentSessionIndex: Int=0
    @Published var sessions: [Session]=[]
    
    var cancellables:[AnyCancellable]?=nil
    
    
//    private enum CodingKeys: String, CodingKey {
//        case sessions, currentSessionIndex
//    }
    
    var currentSession: Session {
        if sessions.count > 0{
            return sessions[currentSessionIndex]
        }else{
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
        currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
        sessions = try decoder.decodeIfPresent("sessions") ?? sessions
        self.postInit()
    }
    
    public func postInit(){
        self.cancellables=[]
        for session in sessions{
            self.cancellables?.append(session.objectWillChange.sink { (_) in
                print("session \(session) was changed")
                self.objectWillChange.send()
            })
        }
    }
    
    func openView(_ view:SessionView){
        self.currentSession.openView(view)
        self.objectWillChange.send()
    }

    public func findSession(_ query:String) -> Void {}
    // Find a session using text

    public func clear() -> Void {}
    //  Clear all sessions and create a new one
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Sessions {
        var jsonData = try jsonDataFromFile(file, ext)
        let sessions: Sessions = try! JSONDecoder().decode(Sessions.self, from: jsonData)
        return sessions
    }

//    public func setCurrentSession(_ session:Session) -> Void {}
}




public class Session: ObservableObject, Decodable  {
    
    @Published var currentSessionViewIndex: Int = 0
    @Published var sessionViews: [SessionView] = [SessionView()]
    
    var cancellables: [AnyCancellable]?=nil
    
//    private enum CodingKeys: String, CodingKey {
//        case sessionViews, currentSessionViewIndex
//    }
    
//    var actions: [String: ]
    
    
    public var currentSessionView: SessionView {
        if currentSessionViewIndex >= 0 {
            return sessionViews[currentSessionViewIndex]
        } else{
            return sessionViews[0]
        }
    }
    
    init(_ currentSessionViewIndex: Int = 0, sessionViews: [SessionView]=[SessionView()]){
        self.currentSessionViewIndex = currentSessionViewIndex
        self.sessionViews = sessionViews
        self.postInit()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        currentSessionViewIndex = try decoder.decodeIfPresent("currentSessionViewIndex") ?? currentSessionViewIndex
        sessionViews = try decoder.decodeIfPresent("sessionViews") ?? sessionViews
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
    
    public func postInit(){
        for sessionView in sessionViews{
            cancellables?.append(sessionView.objectWillChange.sink { (_) in
                            self.objectWillChange.send()
            })
        }
    }
    
    func executeAction(action: ActionDescription?, dataItem: DataItem? = nil){
        if let action = action{
            let params = action.actionArgs
            
            switch action.actionName {
            case "back":
                back()
            case "add":
                let param0 = params[0].value as! DataItem
                add(dataItem: param0)
            case "openView":
                if let dataItem = dataItem{
                    openView(dataItem)
                }else{
                    let param0 = params[0].value as! SessionView
                    openView(param0)
                }
            case "toggleEdit":
                toggleEditMode()
            case "exampleUnpack":
                let (_, _) = (params[0].value, params[1].value) as! (String, Int)
                break
            default:
                print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
            }
        }else{
            print("No action defined")
        }
    }
    
    
    func back(){
        print(currentSessionViewIndex)
        if currentSessionViewIndex == 0 {
            print("returning")
            self.objectWillChange.send()
            return
        }else{
            currentSessionViewIndex -= 1
            self.objectWillChange.send()
        }
        print(currentSessionViewIndex)
        print(self.currentSessionView.rendererName)
    }
    
    func changeRenderer(rendererName: String){
        self.currentSessionView.rendererName = rendererName
        self.objectWillChange.send()
    }
    
    func add(dataItem: DataItem){
        
//        let n = self.currentSessionView.searchResult.data.count + 100
//        let dataItem = DataItem.fromUid(uid: "0x0\(n)")
//
//        dataItem.properties=["title": "new note", "content": ""]
        
        
        self.currentSessionView.searchResult.data.append(dataItem)
        let sr = SearchResult()
        let sv = SessionView()
        sr.data = [dataItem]
        sv.searchResult=sr
        sv.rendererName = "richTextEditor"
        sv.title="new note"
        sv.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        self.openView(sv)
    }
    
    func toggleEditMode(){
        //currently handled in browser
    }
    
    func openView(_ view:SessionView){
        self.sessionViews = self.sessionViews[0...self.currentSessionViewIndex] +  [view]
        self.currentSessionViewIndex += 1
        
        cancellables?.append(view.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        })
    }
    func openView(_ dataItem:DataItem){
        var view = SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                rendererName: "richTextEditor")
    
        self.sessionViews = self.sessionViews[0...self.currentSessionViewIndex] +  [view]
        self.currentSessionViewIndex += 1
        
        cancellables?.append(view.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        })
    }
    
}
