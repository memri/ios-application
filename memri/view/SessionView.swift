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
        
        jsonErrorHandling(decoder) {
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
//                    self.actionArgs[0] = AnyCodable(try DataItem(from: self.actionArgs[0].value))
                1+1
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
    @Published var filterButtons: [ActionDescription]? = nil
    @Published public var showFilterPanel: Bool? = nil
    var actionItems: [ActionDescription]? = nil
    var navigateItems: [ActionDescription]? = nil
    var contextButtons: [ActionDescription]? = nil
    var actionButton: ActionDescription? = nil
    var backButton: ActionDescription? = nil
    var backTitle: String?=nil
    var editActionButton: ActionDescription?=nil
    var icon: String? = nil
    var showLabels: Bool? = nil
    var contextMode: Bool? = nil
    var filterMode: Bool? = nil
    var editMode: Bool? = nil
    var browsingMode: String? = nil
    @State var isEditMode: EditMode = .inactive
    @State var abc: Bool = false
    
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
            self.showFilterPanel = try decoder.decodeIfPresent("showFilterPanel") ?? self.showFilterPanel
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
    }
    
    public func merge(_ view:SessionView) {
        let query = view.searchResult.query
        let sr = self.searchResult
        
        // TODO this function is called way too often
        
        sr.query.query = query.query ?? sr.query.query ?? nil
        sr.query.sortProperty = query.sortProperty ?? sr.query.sortProperty ?? ""
        sr.query.sortAscending = query.sortAscending ?? sr.query.sortAscending ?? -1
        sr.query.pageCount = query.pageCount ?? sr.query.pageCount ?? 0
        sr.query.pageIndex = query.pageIndex ?? sr.query.pageIndex ?? 0
        
        self.title = view.title ?? self.title ?? ""
        self.rendererName = view.rendererName ?? self.rendererName ?? ""
        self.name = view.name ?? self.name ?? ""
        self.subtitle = view.subtitle ?? self.subtitle ?? ""
        self.selection = view.selection ?? self.selection ?? []
        self.icon = view.icon ?? self.icon ?? ""
        self.showLabels = view.showLabels ?? self.showLabels ?? true
        self.contextMode = view.contextMode ?? self.contextMode ?? false
        self.filterMode = view.filterMode ?? self.filterMode ?? false
        self.editMode = view.editMode ?? self.editMode ?? false
        self.browsingMode = view.browsingMode ?? self.browsingMode ?? "default"
        self.actionButton = view.actionButton ?? self.actionButton ?? nil
        self.backButton = view.backButton ?? self.backButton ?? nil
        self.showFilterPanel = view.showFilterPanel ?? self.showFilterPanel ?? false
        self.backTitle = view.backTitle ?? self.backTitle ?? ""
        self.editActionButton = view.editActionButton ?? self.editActionButton ?? nil
        self.isEditMode = view.isEditMode ?? self.isEditMode
        
        self.renderConfigs = view.renderConfigs ?? self.renderConfigs ?? [:] // TODO merge this properly
        
        self.editButtons = (self.editButtons ?? []) + (view.editButtons ?? []) // TODO filter out any duplicates
        self.filterButtons = (self.filterButtons ?? []) + (view.filterButtons ?? []) // TODO filter out any duplicates
        self.actionItems = (self.actionItems ?? []) + (view.actionItems ?? []) // TODO filter out any duplicates
        self.navigateItems = (self.navigateItems ?? []) + (view.navigateItems ?? []) // TODO filter out any duplicates
        self.contextButtons = (self.contextButtons ?? []) + (view.contextButtons ?? []) // TODO filter out any duplicates
    }
    
    public static func fromSearchResult(searchResult: SearchResult, rendererName: String = "list", currentView: SessionView) -> SessionView{
        let sv = SessionView()
        sv.searchResult = searchResult
        sv.rendererName = rendererName
        sv.backButton = ActionDescription(icon: "chevron.left",
                                          title: "Back",
                                          actionName: "back",
                                          actionArgs: [])
        print("TITLE \(searchResult.data[0].getString("title"))")
        sv.title = searchResult.data[0].getString("title")
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
