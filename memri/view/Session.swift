import Foundation
import Combine


class ActionDescription: Codable {
    var icon: String
    var title: String
    var actionName: String
    // TODO: Make serializeble
//    var actionArgs: [Any]
    
//    init(icon: String, title: String, actionName: String, actionArgs: [Any]){
    init(icon: String, title: String, actionName: String){

        self.icon=icon
        self.title=title
        self.actionName=actionName
//        self.actionArgs=actionArgs
    }
}

class RenderConfig: Codable{
    var name: String
    var icon: String
    var category: String
    var items: [ActionDescription]
    var options1: [ActionDescription]
    var options2: [ActionDescription]
    
    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription]){
        self.name=name
        self.icon=icon
        self.category=category
        self.items=items
        self.options1=options1
        self.options2=options2
    }
}


class ListConfig: RenderConfig {
    var cascadeOrder: [String]
    var slideLeftActions: [ActionDescription]
    var slideRightActions: [ActionDescription]
    var type: String
    var browse: String
    var sortProperty: String
    var sortAscending: Int
    var itemRenderer: String
    var longPress: ActionDescription

    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription], cascadeOrder: [String], slideLeftActions: [ActionDescription],
         slideRightActions: [ActionDescription], type: String, browse: String, sortProperty: String,
         sortAscending: Int, itemRenderer: String, longPress: ActionDescription){
        self.cascadeOrder=cascadeOrder
        self.slideLeftActions=slideLeftActions
        self.slideRightActions=slideRightActions
        self.type=type
        self.browse=browse
        self.sortProperty=sortProperty
        self.sortAscending=sortAscending
        self.itemRenderer=itemRenderer
        self.longPress=longPress
        super.init(name: name, icon: icon, category: category, items: items, options1: options1, options2: options2)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}


public class Sessions: ObservableObject, Codable {

    @Published var currentSessionIndex: Int
    @Published var sessions: [Session]
    
    var cancellables: [AnyCancellable]?=nil
    
    private enum CodingKeys: String, CodingKey {
        case sessions, currentSessionIndex
    }
    
    var currentSession: Session {
            return sessions[currentSessionIndex]
    }
    
    init(_ sessions: [Session], currentSessionIndex: Int = 0){
        self.sessions = sessions
        self.currentSessionIndex = currentSessionIndex
        self.cancellables=[]
        
        for session in sessions{
            cancellables?.append(session.objectWillChange.sink { (_) in
                            self.objectWillChange.send()
            })
        }
    }

    public func findSession(_ query:String) -> Void {}
    // Find a session using text

    public func clear() -> Void {}
    //  Clear all sessions and create a new one

//    public func setCurrentSession(_ session:Session) -> Void {}
}




class Session: ObservableObject, Codable  {
    
    @Published var currentSessionViewIndex: Int
    @Published var sessionViews: [SessionView] = []
    
    public var currentSessionView: SessionView {
        if currentSessionViewIndex >= 0 {
            return sessionViews[currentSessionViewIndex]
        } else{
            return sessionViews[0]
        }
    }
    
    init(_ currentView: SessionView ){
        self.sessionViews = [currentView]
        self.currentSessionViewIndex = 0
    }

    func back(){
        if currentSessionViewIndex == 0 {
            return
        }else{
            currentSessionViewIndex -= 1
        }
    }
    
    func openView(_ view:SessionView){
        self.sessionViews = self.sessionViews[0...self.currentSessionViewIndex] +  [view]
        self.currentSessionViewIndex += 1
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
}

class SessionView: ObservableObject, Codable{

    public var searchResult: SearchResult
    @Published public var title: String
    @Published var rendererName: String = "List"
    var subtitle: String
    var selection: [String]
    var renderConfigs: [String: RenderConfig]
    var editButtons: [ActionDescription]
    var filterButtons: [ActionDescription]
    var actionItems: [ActionDescription]
    var navigateItems: [ActionDescription]
    var contextButtons: [ActionDescription]
    var icon: String
    var showLabels: Bool
    var contextMode: Bool
    var filterMode: Bool
    var editMode: Bool
    var browsingMode: Bool
    
    init(rendererName: String = "List", searchResult: SearchResult=SearchResult(query: ""), title:String="",
         subtitle:String = "", renderName:String="", selection: [String] = [], renderConfigs: [String: RenderConfig]=[:], editButtons: [ActionDescription]=[],
         filterButtons: [ActionDescription]=[], actionItems: [ActionDescription]=[], navigateItems: [ActionDescription]=[],
         contextButtons: [ActionDescription]=[], icon: String="", showLabels: Bool=false, contextMode: Bool=false, filterMode: Bool=false, editMode: Bool=false,
         browsingMode: Bool=true){
        self.rendererName=rendererName
        self.searchResult=searchResult
        self.title=title
        self.subtitle=subtitle
        self.selection=selection
        self.renderConfigs=renderConfigs
        self.editButtons=editButtons
        self.filterButtons=filterButtons
        self.actionItems=actionItems
        self.navigateItems=navigateItems
        self.contextButtons=contextButtons
        self.icon=icon
        self.showLabels=showLabels
        self.contextMode=contextMode
        self.filterMode=filterMode
        self.editMode=editMode
        self.browsingMode=browsingMode
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
}


