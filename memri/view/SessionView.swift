import Foundation
import Combine
import SwiftUI


public class ActionDescription: Decodable, Identifiable {
    
    
    public var id = UUID()
    var color: UIColor = .gray
    var icon: String = ""
    var title: String = ""
    var actionName: String = ""
    var actionArgs: [AnyCodable] = []
    
    public convenience required init(from decoder: Decoder) throws{
        self.init()
        self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
        self.title = try decoder.decodeIfPresent("title") ?? self.title
        self.actionName = try decoder.decodeIfPresent("actionName") ?? self.actionName
        self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
        
        let colorString = try decoder.decodeIfPresent("color") ?? ""
        
        switch colorString{
            case "gray": self.color = .gray
            case "yellow","systemYellow": self.color = .systemYellow
            default: self.color = .gray
        }
        
                
        // we manually set the objects for the actionArgs key, since it has a somewhat dynamic value
        switch self.actionName{
            case "add":
                self.actionArgs[0] = AnyCodable(try! DataItem(from: self.actionArgs[0].value))
            case "openView":
                self.actionArgs[0] = AnyCodable(try! SessionView(from: self.actionArgs[0].value))
            default:
                break
        }
        }
    
    public convenience init(icon: String?=nil, title: String?=nil, actionName: String?=nil, actionArgs: [AnyCodable]?=nil){
        self.init()
        self.icon = icon ?? self.icon
        self.title = title ?? self.title
        self.actionName = actionName ?? self.actionName
        self.actionArgs = actionArgs ?? self.actionArgs
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> ActionDescription {
        var jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
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
    @Published public var filterButtons: [ActionDescription]=[]
    @Published public var showFilterPannel: Bool = true
    var actionItems: [ActionDescription]=[]
    var navigateItems: [ActionDescription]=[]
    var contextButtons: [ActionDescription]=[]
    var actionButton: ActionDescription?=nil
    var backButton: ActionDescription?=nil
    var backTitle: String?=nil
    var editActionButton: ActionDescription?=nil
    var icon: String=""
    var showLabels: Bool=false
    var contextMode: Bool=false
    var filterMode: Bool=false
    var editMode: Bool=false
    var browsingMode: String="default"
    @State var isEditMode: EditMode = .inactive
    @State var abc: Bool = false
    
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
        self.showFilterPannel = try decoder.decodeIfPresent("showFilterPannel") ?? self.showFilterPannel
        self.actionItems = try decoder.decodeIfPresent("actionItems") ?? self.actionItems
        self.navigateItems = try decoder.decodeIfPresent("navigateItems") ?? self.navigateItems
        self.contextButtons = try decoder.decodeIfPresent("contextButtons") ?? self.contextButtons
        self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
        self.backButton = try decoder.decodeIfPresent("backButton") ?? self.backButton
        self.backTitle = try decoder.decodeIfPresent("backTitle") ?? self.backTitle
        self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
        self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
        self.showLabels = try decoder.decodeIfPresent("showLabels") ?? self.showLabels
        self.contextMode = try decoder.decodeIfPresent("contextMode") ?? self.contextMode
        self.filterMode = try decoder.decodeIfPresent("filterMode") ?? self.filterMode
        self.editMode = try decoder.decodeIfPresent("editMode") ?? self.editMode
        self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
    }
    
    public static func fromSearchResult(searchResult: SearchResult, rendererName: String = "list", currentView: SessionView) -> SessionView{
        let sv = SessionView()
        sv.searchResult = searchResult
        sv.rendererName = rendererName
        sv.backButton = ActionDescription(icon: "chevron.left",
                                          title: "Back",
                                          actionName: "back",
                                          actionArgs: [])
        print("TITLE \(searchResult.data[0].properties["title"]!)")
        sv.title = searchResult.data[0].properties["title"] ?? ""
        sv.backTitle = currentView.title
        return sv
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        var jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
    
    public func toggleEditMode(){
        switch self.isEditMode{
            case .active:
                self.isEditMode = .inactive
            case .inactive:
                self.isEditMode = .active
//                self.$isEditMode.wrappedValue = .active
                print(self.isEditMode)
            default:
                break
        }
        self.isEditMode = .active
        print(self.abc)
        self.abc.toggle()
        self.abc=true
        self.$abc.wrappedValue = true
        print(self.abc)
    }
}
