import Foundation
import Combine
import RealmSwift

public class SessionView: Object, ObservableObject, Codable {
    
    /**
     *
     */
    @objc dynamic var searchResult: SearchResult? = SearchResult()
    
    @objc dynamic var name: String? = nil
    @objc dynamic var title: String? = nil
    @objc dynamic var rendererName: String? = nil
    @objc dynamic var subtitle: String? = nil
    @objc dynamic var backTitle: String? = nil
    @objc dynamic var icon: String? = nil
    @objc dynamic var browsingMode: String? = nil
    
    let showLabels = RealmOptional<Bool>()
    let contextMode = RealmOptional<Bool>()
    let filterMode = RealmOptional<Bool>()
    let isEditMode = RealmOptional<Bool>()
    
    let cascadeOrder = List<String>()
    let renderConfigs = List<RenderConfig>()
    let selection = List<DataItem>()
    let editButtons = List<ActionDescription>()
    let filterButtons = List<ActionDescription>()
    let actionItems = List<ActionDescription>()
    let navigateItems = List<ActionDescription>()
    let contextButtons = List<ActionDescription>()
    
    @objc dynamic var actionButton: ActionDescription? = nil
    @objc dynamic var editActionButton: ActionDescription? = nil
    
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
        self.name = try decoder.decodeIfPresent("name") ?? self.name
        self.title = try decoder.decodeIfPresent("title") ?? self.title
        self.rendererName = try decoder.decodeIfPresent("rendererName") ?? self.rendererName
        self.subtitle = try decoder.decodeIfPresent("subtitle") ?? self.subtitle
        self.backTitle = try decoder.decodeIfPresent("backTitle") ?? self.backTitle
        self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
        self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
        
        self.showLabels.value = try decoder.decodeIfPresent("showLabels") ?? self.showLabels.value
        self.contextMode.value = try decoder.decodeIfPresent("contextMode") ?? self.contextMode.value
        self.filterMode.value = try decoder.decodeIfPresent("filterMode") ?? self.filterMode.value
        self.isEditMode.value = try decoder.decodeIfPresent("isEditMode") ?? self.isEditMode.value
        
        decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
        decodeIntoList(decoder, "renderConfigs", self.renderConfigs)
        decodeIntoList(decoder, "selection", self.selection)
        decodeIntoList(decoder, "editButtons", self.editButtons)
        decodeIntoList(decoder, "filterButtons", self.filterButtons)
        decodeIntoList(decoder, "actionItems", self.actionItems)
        decodeIntoList(decoder, "navigateItems", self.navigateItems)
        decodeIntoList(decoder, "contextButtons", self.contextButtons)
        
        self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
        self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
//        }
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public func merge(_ view:SessionView) {
        // TODO this function is called way too often
        
        let query = view.searchResult!.query!
        if let qry = self.searchResult!.query {
            qry.query = query.query ?? qry.query ?? nil
            qry.sortProperty = query.sortProperty ?? qry.sortProperty ?? ""
            qry.sortAscending.value = query.sortAscending.value ?? qry.sortAscending.value ?? -1
            qry.pageCount.value = query.pageCount.value ?? qry.pageCount.value ?? 0
            qry.pageIndex.value = query.pageIndex.value ?? qry.pageIndex.value ?? 0
        }
        
        self.name = view.name ?? self.name ?? ""
        self.title = view.title ?? self.title ?? ""
        self.rendererName = view.rendererName ?? self.rendererName ?? ""
        self.subtitle = view.subtitle ?? self.subtitle ?? ""
        self.backTitle = view.backTitle ?? self.backTitle ?? ""
        self.icon = view.icon ?? self.icon ?? ""
        self.browsingMode = view.browsingMode ?? self.browsingMode ?? ""
        
        self.showLabels.value = view.showLabels.value ?? self.showLabels.value ?? true
        self.contextMode.value = view.contextMode.value ?? self.contextMode.value ?? false
        self.filterMode.value = view.filterMode.value ?? self.filterMode.value ?? false
        self.isEditMode.value = view.isEditMode.value ?? self.isEditMode.value ?? false
        
        self.cascadeOrder.append(objectsIn: view.cascadeOrder)
        self.renderConfigs.append(objectsIn: view.renderConfigs)
        self.selection.append(objectsIn: view.selection)
        self.editButtons.append(objectsIn: view.editButtons)
        self.filterButtons.append(objectsIn: view.filterButtons)
        self.actionItems.append(objectsIn: view.actionItems)
        self.navigateItems.append(objectsIn: view.navigateItems)
        self.contextButtons.append(objectsIn: view.contextButtons)
        
        self.actionButton = view.actionButton ?? self.actionButton ?? nil
        self.editActionButton = view.editActionButton ?? self.editActionButton ?? nil
    }
    
    /**
     * Validates a merged view
     */
    public func validate() throws {
        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
        if self.searchResult!.query!.query == "" { throw("No query is defined for this view") }
        if self.actionButton == nil && self.editActionButton == nil {
            throw("Missing action button in this view")
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
