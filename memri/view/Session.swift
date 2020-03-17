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
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
        let jsonData = try jsonDataFromFile(file, ext)
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: jsonData)
        return sessions
    }
    
    public class func fromJSONString(_ json: String) throws -> Sessions {
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: Data(json.utf8))
        return sessions
    }

//    public func setCurrentSession(_ session:Session) -> Void {}
}

public class Session: ObservableObject, Decodable  {
    
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
        self.currentViewIndex = currentViewIndex
        self.views = views
        self.postInit()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        currentViewIndex = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex
        views = try decoder.decodeIfPresent("views") ?? views
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

            case "exampleUnpack":
                let (_, _) = (params[0].value, params[1].value) as! (String, Int)
                break
            default:
                print("UNDEFINED ACTION, NOT EXECUTING")
            }
        }
    }
    
    func back(){
        print(currentViewIndex)
        if currentViewIndex == 0 {
            print("returning")
            self.objectWillChange.send()
            return
        }else{
            currentViewIndex -= 1
            self.objectWillChange.send()
        }
        print(currentViewIndex)
        print(self.currentView.rendererName)
    }
    
    func changeRenderer(rendererName: String){
        self.currentView.rendererName = rendererName
        self.objectWillChange.send()
    }
    
    // TODO
    func add(dataItem: DataItem){
        
//        let n = self.currentSessionView.searchResult.data.count + 100
//        let dataItem = DataItem.fromUid(uid: "0x0\(n)")
//
//        dataItem.properties=["title": "new note", "content": ""]
        
        self.currentView.searchResult.data.append(dataItem)
        
        let sr = SearchResult()
        let sv = SessionView()
        
        sr.data = [dataItem]
        sv.searchResult=sr
        sv.rendererName = "richTextEditor"
        sv.title="new note"
        sv.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        
        self.openView(sv)
    }
    
    func openView(_ view:SessionView){
        self.views = self.views[0...self.currentViewIndex] +  [view]
        self.currentViewIndex += 1
        
        cancellables?.append(view.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        })
    }
    
    func openView(_ dataItem:DataItem){
        let view = SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                rendererName: "richTextEditor")
    
        self.views = self.views[0...self.currentViewIndex] + [view]
        self.currentViewIndex += 1
        
        cancellables?.append(view.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        })
    }
    
}
