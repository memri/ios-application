import Foundation
import Combine

public class ActionDescription: Codable {
    var icon: String = ""
    var title: String = ""
    var actionName: String = ""
    var actionArgs: [AnyCodable] = []
    
    public convenience required init(from decoder: Decoder) throws{
        self.init()
        
        jsonErrorHandling(decoder) {
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.actionName = try decoder.decodeIfPresent("actionName") ?? self.actionName
            self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
                    
            // we manually set the objects for the actionArgs key, since it has a somewhat dynamic value
            switch self.actionName{
                case "add":
                    self.actionArgs[0] = AnyCodable(try DataItem(from: self.actionArgs[0].value))
                case "openView":
                // TODO make this work
                1+1
//                    self.actionArgs[0] = AnyCodable(try! SessionView(from: self.actionArgs[0].value))
                default:
                    break
            }
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
        let jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
    }
}

public class SessionView: ObservableObject, Decodable{
    @Published public var searchResult: SearchResult = SearchResult()
    @Published public var title: String? = nil
    @Published var rendererName: String? = nil
    
    var name: String? = nil
    var subtitle: String? = nil
    var selection: [String]? = nil
    var renderConfigs: [String: RenderConfig]? = nil
    var editButtons: [ActionDescription]? = nil
    var filterButtons: [ActionDescription]? = nil
    var actionItems: [ActionDescription]? = nil
    var navigateItems: [ActionDescription]? = nil
    var contextButtons: [ActionDescription]? = nil
    var actionButton: ActionDescription? = nil
    var backButton: ActionDescription? = nil
    var icon: String? = nil
    var showLabels: Bool? = nil
    var contextMode: Bool? = nil
    var filterMode: Bool? = nil
    var editMode: Bool? = nil
    var browsingMode: String? = nil
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
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
            self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
            self.backButton = try decoder.decodeIfPresent("backButton") ?? self.backButton
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.showLabels = try decoder.decodeIfPresent("showLabels") ?? self.showLabels
            self.contextMode = try decoder.decodeIfPresent("contextMode") ?? self.contextMode
            self.filterMode = try decoder.decodeIfPresent("filterMode") ?? self.filterMode
            self.editMode = try decoder.decodeIfPresent("editMode") ?? self.editMode
            self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
        }
    }
    
    public func merge(_ view:SessionView) {
        let query = view.searchResult.query
        let sr = self.searchResult
        if query.query != nil { sr.query.query = query.query }
        if query.sortProperty != nil { sr.query.sortProperty = query.sortProperty }
        if query.sortAscending != nil { sr.query.sortAscending = query.sortAscending }
        if query.pageCount != nil { sr.query.pageCount = query.pageCount }
        if query.pageIndex != nil { sr.query.pageIndex = query.pageIndex }
        
        if view.title != nil { self.title = view.title }
        if view.rendererName != nil { self.rendererName = view.rendererName }
        if view.name != nil { self.name = view.name }
        if view.subtitle != nil { self.subtitle = view.subtitle }
        if view.selection != nil { self.selection = view.selection }
        if view.icon != nil { self.icon = view.icon }
        if view.showLabels != nil { self.showLabels = view.showLabels }
        if view.contextMode != nil { self.contextMode = view.contextMode }
        if view.filterMode != nil { self.filterMode = view.filterMode }
        if view.editMode != nil { self.editMode = view.editMode }
        if view.browsingMode != nil { self.browsingMode = view.browsingMode }
        if view.actionButton != nil { self.actionButton = view.actionButton }
        if view.backButton != nil { self.backButton = view.backButton }
        
        if view.renderConfigs != nil { self.renderConfigs = view.renderConfigs } // TODO merge this properly
        
        if view.editButtons != nil { self.editButtons = (self.editButtons ?? []) + view.editButtons! } // TODO filter out any duplicates
        if view.filterButtons != nil { self.filterButtons = (self.filterButtons ?? []) + view.filterButtons! } // TODO filter out any duplicates
        if view.actionItems != nil { self.actionItems = (self.actionItems ?? []) + view.actionItems! } // TODO filter out any duplicates
        if view.navigateItems != nil { self.navigateItems = (self.navigateItems ?? []) + view.navigateItems! } // TODO filter out any duplicates
        if view.contextButtons != nil { self.contextButtons = (self.contextButtons ?? []) + view.contextButtons! } // TODO filter out any duplicates
    }
    
    public static func fromSearchResult(searchResult: SearchResult, rendererName: String = "list") -> SessionView{
        let sv = SessionView()
        sv.searchResult = searchResult
        sv.rendererName = rendererName
        sv.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        return sv
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        var jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
}
