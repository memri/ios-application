import Foundation
import Combine
import RealmSwift


public class SessionView: Object, ObservableObject, Codable {
    @Published public var searchResult: SearchResult = SearchResult()
    @Published public var title: String? = nil
    @Published var rendererName: String? = nil
    
    var name: String? = nil
    var subtitle: String? = nil
    var selection: [String]? = nil
    var renderConfigs: [String: RenderConfig]? = nil
    var editButtons: [ActionDescription]? = nil
    @Published var filterButtons: [ActionDescription]? = nil
    var actionItems: [ActionDescription]? = nil
    var navigateItems: [ActionDescription]? = nil
    var contextButtons: [ActionDescription]? = nil
    var actionButton: ActionDescription? = nil
    var backTitle: String? = nil
    var editActionButton: ActionDescription?=nil
    var icon: String? = nil
    var showLabels: Bool? = nil
    var contextMode: Bool? = nil
    var filterMode: Bool? = nil
    var browsingMode: String? = nil
    @Published var isEditMode: Bool? = nil
    var cascadeOrder:[String]? = nil
    
    /**
     * @private
     */
    @objc dynamic var json:String? = nil
    /**
     *
     */
    @objc dynamic var loadState:SyncState? = SyncState()
    
    private enum CodingKeys: String, CodingKey {
        case searchResult, title, rendererName, name, subtitle, selection, renderConfigs,
            editButtons, filterButtons, actionItems, navigateItems, contextButtons, actionButton,
            backTitle, editActionButton, icon, showLabels, contextMode, filterMode, isEditMode,
            browsingMode, cascadeOrder
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
//        jsonErrorHandling(decoder) {
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
            self.backTitle = try decoder.decodeIfPresent("backTitle") ?? self.backTitle
            self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.showLabels = try decoder.decodeIfPresent("showLabels") ?? self.showLabels
            self.contextMode = try decoder.decodeIfPresent("contextMode") ?? self.contextMode
            self.filterMode = try decoder.decodeIfPresent("filterMode") ?? self.filterMode
            self.isEditMode = try decoder.decodeIfPresent("isEditMode") ?? self.isEditMode
            self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
            self.cascadeOrder = try decoder.decodeIfPresent("cascadeOrder") ?? self.cascadeOrder
//        }
    }
    
    deinit {
        if let realm = self.realm {
            try! realm.write {
                realm.delete(self)
            }
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
        self.isEditMode = view.isEditMode ?? self.isEditMode ?? false
        self.browsingMode = view.browsingMode ?? self.browsingMode ?? "default"
        self.actionButton = view.actionButton ?? self.actionButton ?? nil
        self.backTitle = view.backTitle ?? self.backTitle ?? ""
        self.editActionButton = view.editActionButton ?? self.editActionButton ?? nil
        self.cascadeOrder = view.cascadeOrder ?? self.cascadeOrder ?? ["renderer", "datatype"]
        
        self.renderConfigs = view.renderConfigs ?? self.renderConfigs ?? [:] // TODO merge this properly
        
        self.editButtons = (self.editButtons ?? []) + (view.editButtons ?? []) // TODO filter out any duplicates
        self.filterButtons = (self.filterButtons ?? []) + (view.filterButtons ?? []) // TODO filter out any duplicates
        self.actionItems = (self.actionItems ?? []) + (view.actionItems ?? []) // TODO filter out any duplicates
        self.navigateItems = (self.navigateItems ?? []) + (view.navigateItems ?? []) // TODO filter out any duplicates
        self.contextButtons = (self.contextButtons ?? []) + (view.contextButtons ?? []) // TODO filter out any duplicates
    }
    
    /**
     * Validates a merged view
     */
    public func validate() throws {
        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
        if self.searchResult.query.query == "" { throw("No query is defined for this view") }
        if self.actionButton == nil && self.editActionButton == nil {
            throw("Missing action button in this view")
        }
    }
    
    /**
     *
     */
    public func persist() {
        try! self.realm!.write {
//            self.json = serialize(self)
            let data = try! JSONEncoder().encode(self)
            self.json = String(data: data, encoding: .utf8)!
            dump(self.json)
        }
    }
    /**
     *
     */
    public func expand() {
        if let view:SessionView = unserialize(self.json ?? "") {
            let properties = self.objectSchema.properties
            for prop in properties {
                self[prop.name] = view[prop.name]
            }
        }
    }
    
    public static func fromSearchResult(searchResult: SearchResult, rendererName: String = "list", currentView: SessionView) -> SessionView{
        let sv = SessionView()
        sv.searchResult = searchResult
        sv.rendererName = rendererName
        sv.title = searchResult.data[0].getString("title")
        sv.backTitle = currentView.title
        return sv
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
}
