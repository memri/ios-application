import Foundation
import Combine
import RealmSwift

public class SessionView: Object, ObservableObject, Codable {
    
    /**
     *
     */
    @objc dynamic var queryOptions: QueryOptions? = QueryOptions()
    
    @objc dynamic var name: String? = nil
    @objc dynamic var title: String? = nil
    @objc dynamic var rendererName: String? = nil
    @objc dynamic var subtitle: String? = nil
    @objc dynamic var backTitle: String? = nil
    @objc dynamic var icon: String? = nil
    @objc dynamic var browsingMode: String? = nil
    @objc dynamic var filterText: String? = nil
    
    let showLabels = RealmOptional<Bool>()
    let contextMode = RealmOptional<Bool>()
    let filterMode = RealmOptional<Bool>()
    let isEditMode = RealmOptional<Bool>()
    
    let cascadeOrder = List<String>()
    let selection = List<DataItem>()
    let editButtons = List<ActionDescription>()
    let filterButtons = List<ActionDescription>()
    let actionItems = List<ActionDescription>()
    let navigateItems = List<ActionDescription>()
    let contextButtons = List<ActionDescription>()
    
    @objc dynamic var renderConfigs: RenderConfigs? = nil
    @objc dynamic var actionButton: ActionDescription? = nil
    @objc dynamic var editActionButton: ActionDescription? = nil
    
    /**
     *
     */
    @objc dynamic var syncState:SyncState? = SyncState()
    
    private enum CodingKeys: String, CodingKey {
        case queryOptions, title, rendererName, name, subtitle, selection, renderConfigs,
            editButtons, filterButtons, actionItems, navigateItems, contextButtons, actionButton,
            backTitle, editActionButton, icon, showLabels, contextMode, filterMode, isEditMode,
            browsingMode, cascadeOrder
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.queryOptions = try decoder.decodeIfPresent("queryOptions") ?? self.queryOptions
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.rendererName = try decoder.decodeIfPresent("rendererName") ?? self.rendererName
            self.subtitle = try decoder.decodeIfPresent("subtitle") ?? self.subtitle
            self.backTitle = try decoder.decodeIfPresent("backTitle") ?? self.backTitle
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
            self.filterText = try decoder.decodeIfPresent("filterText") ?? self.filterText
            
            self.showLabels.value = try decoder.decodeIfPresent("showLabels") ?? self.showLabels.value
            self.contextMode.value = try decoder.decodeIfPresent("contextMode") ?? self.contextMode.value
            self.filterMode.value = try decoder.decodeIfPresent("filterMode") ?? self.filterMode.value
            self.isEditMode.value = try decoder.decodeIfPresent("isEditMode") ?? self.isEditMode.value
            
            decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
            decodeIntoList(decoder, "selection", self.selection)
            decodeIntoList(decoder, "editButtons", self.editButtons)
            decodeIntoList(decoder, "filterButtons", self.filterButtons)
            decodeIntoList(decoder, "actionItems", self.actionItems)
            decodeIntoList(decoder, "navigateItems", self.navigateItems)
            decodeIntoList(decoder, "contextButtons", self.contextButtons)
            
            self.renderConfigs = try decoder.decodeIfPresent("renderConfigs") ?? self.renderConfigs
            self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
            self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
        }
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> SessionView {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! JSONDecoder().decode(SessionView.self, from: jsonData)
        return items
    }
}

public class ComputedView: ObservableObject {

    /**
     *
     */
    var queryOptions: QueryOptions = QueryOptions()
    var resultSet: ResultSet

    var name: String = ""
    var rendererName: String = ""
    var backTitle: String = ""
    var icon: String = ""
    var browsingMode: String = ""

    var showLabels: Bool = true
    var contextMode: Bool = false
    var filterMode: Bool = false
    var isEditMode: Bool = false

    var cascadeOrder: [String] = []
    var selection: [DataItem] = []
    var editButtons: [ActionDescription] = []
    var filterButtons: [ActionDescription] = []
    var actionItems: [ActionDescription] = []
    var navigateItems: [ActionDescription] = []
    var contextButtons: [ActionDescription] = []

    var sessionView: SessionView? = nil
    var renderConfigs: RenderConfigs = RenderConfigs()
    var actionButton: ActionDescription? = nil
    var editActionButton: ActionDescription? = nil
    
    private var _title: String = ""
    private var _titleTemp: String? = nil
    var title: String {
        get {
            return _titleTemp ?? _title
        }
        set (newSubtitle) {
            if newSubtitle == "" { _titleTemp = nil }
            else { _titleTemp = newSubtitle }
        }
    }
    
    private var _subtitle: String = ""
    private var _subtitleTemp: String? = nil
    var subtitle: String {
        get {
            return _subtitleTemp ?? _subtitle
        }
        set (newSubtitle) {
            if newSubtitle == "" { _subtitleTemp = nil }
            else { _subtitleTemp = newSubtitle }
        }
    }
    
    private var _filterText: String = ""
    var filterText: String {
        get {
            return _filterText
        }
        set (newFilter) {
            
            // Store the new value
            _filterText = newFilter
            
            // If this is a multi item result set
            if self.resultSet.isList {
                
                // TODO we should probably ask the renderer if this is preferred
                // Some renderers such as the charts would probably rather highlight the
                // found results instead of filtering the other data points out
                
                // Filter the result set
                self.resultSet.filterText = _filterText
            }
            else {
                print("Warn: Filtering for single items not Implemented Yet!")
            }
            
            if _filterText == "" {
                title = ""
                subtitle = ""
            }
            else {
                // Set the title to an appropriate message
                if resultSet.count == 0 { title = "No results" }
                else if resultSet.count == 1 { title = "1 item found" }
                else { title = "\(resultSet.count) items found" }
                
                // Temporarily hide the subtitle
                // subtitle = " " // TODO how to clear the subtitle ??
            }
            
            // Save the state on the session view
            try! cache.realm.write { sessionView!.filterText = filterText }
        }
    }
    
    private let cache:Cache
    
    init(_ ch:Cache){
        cache = ch
        resultSet = ResultSet(cache)
    }
    
    public func merge(_ view:SessionView) {
        // TODO this function is called way too often
        
        self.queryOptions.merge(view.queryOptions!)
        
        self.name = view.name ?? self.name
        self.rendererName = view.rendererName ?? self.rendererName
        self.backTitle = view.backTitle ?? self.backTitle
        self.icon = view.icon ?? self.icon
        self.browsingMode = view.browsingMode ?? self.browsingMode
        
        _title = view.title ?? _title
        _subtitle = view.subtitle ?? _subtitle
        _filterText = view.filterText ?? _filterText
        
        self.showLabels = view.showLabels.value ?? self.showLabels
        self.contextMode = view.contextMode.value ?? self.contextMode
        self.filterMode = view.filterMode.value ?? self.filterMode
        self.isEditMode = view.isEditMode.value ?? self.isEditMode
        
        self.cascadeOrder.append(contentsOf: view.cascadeOrder)
        self.selection.append(contentsOf: view.selection)
        self.editButtons.append(contentsOf: view.editButtons)
        self.filterButtons.append(contentsOf: view.filterButtons)
        self.actionItems.append(contentsOf: view.actionItems)
        self.navigateItems.append(contentsOf: view.navigateItems)
        self.contextButtons.append(contentsOf: view.contextButtons)
        
        if let renderConfigs = view.renderConfigs {
            self.renderConfigs.merge(renderConfigs)
        }
        
        self.actionButton = view.actionButton ?? self.actionButton
        self.editActionButton = view.editActionButton ?? self.editActionButton
    }
    
    public func finalMerge(_ view:SessionView) {
        // Merge view into self
        merge(view)
        
        // Store session view on self
        sessionView = view
        
        // Update search result to match the query
        self.resultSet = cache.getResultSet(self.queryOptions)
        
        // Filter the results
        filterText = _filterText
    }

    /**
     * Validates a merged view
     */
    public func validate() throws {
        if self.rendererName == "" { throw("Property 'rendererName' is not defined in this view") }
        
        let renderProps = self.renderConfigs.objectSchema.properties
        if renderProps.filter({ (property) in property.name == self.rendererName }).count == 0 {
//            throw("Missing renderConfig for \(self.rendererName) in this view")
            print("Warn: Missing renderConfig for \(self.rendererName) in this view")
        }
        
        if self.queryOptions.query == "" { throw("No query is defined for this view") }
        if self.actionButton == nil && self.editActionButton == nil {
            throw("Missing action button in this view")
        }
    }
}
