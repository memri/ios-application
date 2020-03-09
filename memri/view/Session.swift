import Foundation
import Combine


public class ActionDescription: Codable {
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


public class Sessions: ObservableObject, Decodable {

    @Published var currentSessionIndex: Int=0
    @Published var sessions: [Session]=[]
    
    
    var cancellables: [AnyCancellable]?=nil
    
//    private enum CodingKeys: String, CodingKey {
//        case sessions, currentSessionIndex
//    }
    
    var currentSession: Session {
            return sessions[currentSessionIndex]
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
    
    func back(){
        print(currentSessionViewIndex)
        if currentSessionViewIndex == 0 {
            print("returning")
            return
        }else{
            currentSessionViewIndex -= 1
            self.objectWillChange.send()
        }
        print(currentSessionViewIndex)
        print(self.currentSessionView.rendererName)

    }
    
    func openView(_ view:SessionView){
        self.sessionViews = self.sessionViews[0...self.currentSessionViewIndex] +  [view]
        self.currentSessionViewIndex += 1
        
        cancellables?.append(view.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        })
        
        
    }
    
}

public class SessionView: ObservableObject, Decodable{

    @Published public var searchResult: SearchResult = SearchResult()
    @Published public var title: String = ""
    @Published var rendererName: String = "list"
    var name: String = ""
    var subtitle: String = ""
    var selection: [String] = []
    var renderConfigs: [String: RenderConfig]=[:]
    var editButtons: [ActionDescription]=[]
    var filterButtons: [ActionDescription]=[]
    var actionItems: [ActionDescription]=[]
    var navigateItems: [ActionDescription]=[]
    var contextButtons: [ActionDescription]=[]
    var icon: String=""
    var showLabels: Bool=false
    var contextMode: Bool=false
    var filterMode: Bool=false
    var editMode: Bool=false
    var browsingMode: String="default"
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        self.searchResult = try decoder.decodeIfPresent("searchResult") ?? self.searchResult
        self.title = try decoder.decodeIfPresent("title") ?? self.title
        self.rendererName = try decoder.decodeIfPresent("rendererName") ?? self.rendererName
        self.name = try decoder.decodeIfPresent("name") ?? self.name
        self.subtitle = try decoder.decodeIfPresent("subtitle") ?? self.subtitle
        self.selection = try decoder.decodeIfPresent("selection") ?? self.selection
        self.renderConfigs = try decoder.decodeIfPresent("renderConfigs") ?? self.renderConfigs
        self.editButtons = try decoder.decodeIfPresent("editButtons") ?? self.editButtons
        self.filterButtons = try decoder.decodeIfPresent("filterButtons") ?? self.filterButtons
        self.actionItems = try decoder.decodeIfPresent("actionItems") ?? self.actionItems
        self.navigateItems = try decoder.decodeIfPresent("navigateItems") ?? self.navigateItems
        self.contextButtons = try decoder.decodeIfPresent("contextButtons") ?? self.contextButtons
        self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
        self.showLabels = try decoder.decodeIfPresent("showLabels") ?? self.showLabels
        self.contextMode = try decoder.decodeIfPresent("contextMode") ?? self.contextMode
        self.filterMode = try decoder.decodeIfPresent("filterMode") ?? self.filterMode
        self.editMode = try decoder.decodeIfPresent("editMode") ?? self.editMode
        self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
    }
    
    public static func fromSearchResult(searchResult: SearchResult, rendererName: String = "list") -> SessionView{
        let sv = SessionView()
        sv.searchResult = searchResult
        sv.rendererName = rendererName
        return sv
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        var jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
}
