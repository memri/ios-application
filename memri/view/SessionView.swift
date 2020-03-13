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
