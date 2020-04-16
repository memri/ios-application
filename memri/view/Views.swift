import Foundation
import Combine
import SwiftUI
import RealmSwift

// Move to integrate with some of the sessions features so that Sessions can be nested
public class Views {
    /**
     *
     */
    var compiledViews: [String:CompiledView] = [:]
    /**
     *
     */
    var defaultViews: [String:[String:DynamicView]] = [:]
    
    private var realm:Realm
    private var main:Main? = nil

    init(_ rlm:Realm) {
        realm = rlm
    }
    
    /**
     *
     */
    public func load(_ mn:Main, _ callback: () -> Void) throws {
        // Store main for use within computeView()
        self.main = mn
        
        // Load the default views from the package
        let data = try! jsonDataFromFile("views_from_server")
        let (parsed, named) = try! CompiledView.parseNamedViewDict(data)
        
        // Set the parsed views to the defaultViews property for later use in computeView
        self.defaultViews = parsed
        
        // Add the named views to the compiled views
        for (name, view) in named {
            compiledViews[name] = compileView(view)
        }
        
        // Done
        callback()
    }
    
    /**
     *
     */
    public func install() {
        
        // Load named views from the package
        let namedViews = try! CompiledView.parseNamedViewList(jsonDataFromFile("named_views"))
        
        // Store named views
        if let namedViews = namedViews {
            try! realm.write {
                for dynamicView in namedViews {
                    realm.add(dynamicView, update: .modified)
                }
            }
        }
    }
    
    /**
     *
     */
    public func getDynamicView (_ viewName:String) -> DynamicView? {
        var dynamicView:DynamicView?
        
        // If a declaration is passed instead of a name create new DynamicView
        if viewName.prefix(1) == "{" {
            dynamicView = DynamicView(viewName)
        }
        // Otherwise load from the database the dynamic view with that name
        else {
            dynamicView = realm.objects(DynamicView.self).filter("name = '\(viewName)'").first
        }
        
        return dynamicView
    }
    
    /**
     *
     */
    public func getCompiledView (_ viewName:String) -> CompiledView? {
        // Find an already compiled view
        if let compiledView = compiledViews[viewName] {
            return compiledView
        }
        
        // Otherwise generate it from a dynamic view
        if let dynamicView = getDynamicView(viewName) {
            return compileView(dynamicView)
        }
        
        return nil
    }
    
    /**
     *
     */
    public func getSessionView (_ viewName:String) -> SessionView? {
        if let compiledView = getCompiledView(viewName) {
            return try! compiledView.generateView()
        }
        
        return nil
    }
    /**
     *
     */
    public func getSessionView (_ view:DynamicView?) -> SessionView? {
        if let dynamicView = view {
            return try! compileView(dynamicView).generateView()
        }
        
        return nil
    }
    /**
     *
     */
    public func getSessionOrView(_ viewName:String, wrapView:Bool=false) -> (Session?, SessionView?) {
        if let compiledView = getCompiledView(viewName) {
            
            // Parse so we now if it includes a session
            try! compiledView.parse()
            
            if compiledView.hasSession {
                return (try! compiledView.generateSession(), nil)
            }
            else {
                let view = try! compiledView.generateView()
                return (wrapView ? Session(value: ["views": [view]]) : nil, view)
            }
        }
        
        return (nil, nil)
    }
    
    /**
     *
     */
    func compileView(_ dynamicView:DynamicView) -> CompiledView {
        // If we have a cached version, let's return that
        if let compiledView = compiledViews[dynamicView.name] {
            return compiledView
        }
        
        // Create a compiled view based on the dynamic view
        let compiledView = try! CompiledView(dynamicView, main!)
        
        // Add the dynamic view for easy reference
        compiledViews[dynamicView.name] = compiledView
        
        return compiledView
    }
    
    /*
    "{type:Note}"
    "{renderer:list}"
    "{[type:Note]}"
    */
    public func computeView(_ argView:SessionView? = nil) throws -> ComputedView {
        guard let main = self.main else {
            throw "Exception: Main is not defined in views"
        }

        let viewFromSession = argView == nil
            ? main.sessions.currentSession.currentView
            : argView!
        
        // Create a new view
        let computedView = ComputedView(main.cache)
        
        var isList:Bool = true
        var type:String = ""
        
        // Fetch query from the view from session
        if let queryOptions = viewFromSession.queryOptions {
            
            // Look up the associated result set
            let resultSet = main.cache.getResultSet(queryOptions)
            
            // Determine whether this is a list or a single item resultset
            isList = resultSet.isList
            
            // Fetch the type of the results
            if let determinedType = resultSet.determinedType {
                type = determinedType
            }
            else {
                throw "Exception: ResultSet does not know the type of its data"
            }
        }
        else {
            throw "Exception: Cannot compute a view without a query to fetch data"
        }

        // Helper lists
        var renderViews:[SessionView] = []
        var datatypeViews:[SessionView] = []
        var rendererNames:[String] = []
        var cascadeOrders:[String:[RealmSwift.List<String>]] = ["defaults":[List()], "user":[]]
        let searchOrder = ["defaults", "user"]
        
        // Default to the rendererName we know from the view from the session
        var rendererName:String = viewFromSession.rendererName ?? ""
        
        cascadeOrders["defaults"]![0].append(objectsIn: ["renderer", "datatype"])
        
        // If we know the type of data we are rendering use it to determine the view
        if type != "mixed" {
            // Determine query
            let needles = [
                isList ? "{[type:*]}" : "{type:*}",
                isList ? "{[type:\(type)]}" : "{type:\(type)}", // TODO if this is not found it should get the default template
            ]
            
            // Find views based on datatype
            for needle in needles {
                print(needle)
                for key in searchOrder {
                    if let datatypeView = getSessionView(self.defaultViews[key]![needle]) {
                        if datatypeView.name != nil && datatypeView.name == viewFromSession.name {
                            continue
                        }
                        
                        datatypeViews.append(datatypeView)
                        
                        if let S = datatypeView.rendererName { rendererNames.append(S) }
                        if datatypeView.cascadeOrder.count > 0 {
                            cascadeOrders[key]?.append(datatypeView.cascadeOrder)
                        }
                    }
                }
            }
            
            if rendererNames.count > 0 {
                rendererName = rendererNames[rendererNames.count - 1]
            }
        }
        else {
            print("Warn: mixed views are not supported yet")
        }
        
        // Find renderer views
        if rendererName != "" {
            // Determine query
            let needle = "{renderer:\(rendererName)}"
            
            for key in searchOrder {
                if let rendererView = getSessionView(self.defaultViews[key]![needle]) {
                    renderViews.append(rendererView)
                    
                    if rendererView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(rendererView.cascadeOrder)
                    }
                }
            }
        }
        else {
            throw "Exception: Could not find which renderer to use. renderName not set in this view"
        }

        // Choose cascade order
        let preferredCascadeOrder = (cascadeOrders["user"]!.count > 0
            ? cascadeOrders["user"]
            : cascadeOrders["defaults"]) ?? []
        
        var cascadeOrder = preferredCascadeOrder[preferredCascadeOrder.count - 1]
        if (cascadeOrder.count == 0) {
            cascadeOrder = List()
            cascadeOrder.append(objectsIn: ["renderer", "datatype"])
        }
        
        if (Set(preferredCascadeOrder).count > 1) {
            print("Warn: Found multiple cascadeOrders when cascading view. Choosing \(cascadeOrder)")
        }
        
        // Cascade the different views
        for key in cascadeOrder {
            var views:[SessionView]
            
            if key == "renderer" { views = renderViews }
            else if key == "datatype" { views = datatypeViews }
            else {
                throw ("Exception: Unknown cascadeOrder type specified: \(key)")
            }
            
            for view in views {
                computedView.merge(view)
            }
        }
        
        // Cascade the view from the session
        // Loads user interactions, e.g. selections, scrollstate, changes of renderer, etc.
        computedView.finalMerge(viewFromSession)
        
        do {
            try computedView.validate()
        }
        catch {
            throw "Exception: Invalid Computed View: \(error)"
        }
        
        // turn off editMode when navigating
        if main.sessions.currentSession.editMode == true {
            try! realm.write {
                main.sessions.currentSession.editMode = false
            }
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if main.sessions.currentSession.showFilterPanel {
            if computedView.filterButtons.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                try! realm.write {
                    main.sessions.currentSession.showFilterPanel = false
                }
            }
        }
        
        return computedView
    }
}

public class SessionView: DataItem {
    /**
     *
     */
    override var type:String { "sessionview" }
    /**
     *
     */
    @objc dynamic var name: String? = nil
    @objc dynamic var title: String? = nil
    @objc dynamic var rendererName: String? = nil
    @objc dynamic var subtitle: String? = nil
    @objc dynamic var backTitle: String? = nil
    @objc dynamic var icon: String? = nil
    @objc dynamic var browsingMode: String? = nil
    @objc dynamic var filterText: String? = nil
    @objc dynamic var emptyResultText: String? = nil
    
    let showLabels = RealmOptional<Bool>()
    
    let cascadeOrder = RealmSwift.List<String>()
    let sortFields = RealmSwift.List<String>()
    let selection = RealmSwift.List<DataItem>()
    let editButtons = RealmSwift.List<ActionDescription>()
    let filterButtons = RealmSwift.List<ActionDescription>()
    let actionItems = RealmSwift.List<ActionDescription>()
    let navigateItems = RealmSwift.List<ActionDescription>()
    let contextButtons = RealmSwift.List<ActionDescription>()
    let activeStates = RealmSwift.List<String>()
    
    @objc dynamic var queryOptions: QueryOptions? = QueryOptions()
    @objc dynamic var renderConfigs: RenderConfigs? = RenderConfigs()
    
    @objc dynamic var actionButton: ActionDescription? = nil
    @objc dynamic var editActionButton: ActionDescription? = nil
    
    @objc dynamic var session: Session? = nil
    
    private enum CodingKeys: String, CodingKey {
        case queryOptions, title, rendererName, name, subtitle, selection, renderConfigs,
            editButtons, filterButtons, actionItems, navigateItems, contextButtons, actionButton,
            backTitle, editActionButton, icon, showLabels, sortFields,
            browsingMode, cascadeOrder, activeStates, emptyResultText
    }
    
    required init(){
        super.init()
        
        self.functions["computedDescription"] = {_ in
            if let value = self.name ?? self.title { return value }
            else if let rendererName = self.rendererName {
                return "A \(rendererName) showing: \(self.queryOptions?.query ?? "")"
            }
            else if let query = self.queryOptions?.query {
                return "Showing: \(query)"
            }
            return "[No Name]"
        }
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
            self.emptyResultText = try decoder.decodeIfPresent("emptyResultText") ?? self.emptyResultText
            
            self.showLabels.value = try decoder.decodeIfPresent("showLabels") ?? self.showLabels.value
            
            decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
            decodeIntoList(decoder, "sortFields", self.sortFields)
            decodeIntoList(decoder, "selection", self.selection)
            decodeIntoList(decoder, "editButtons", self.editButtons)
            decodeIntoList(decoder, "filterButtons", self.filterButtons)
            decodeIntoList(decoder, "actionItems", self.actionItems)
            decodeIntoList(decoder, "navigateItems", self.navigateItems)
            decodeIntoList(decoder, "contextButtons", self.contextButtons)
            decodeIntoList(decoder, "activeStates", self.activeStates)
            
            self.renderConfigs = try decoder.decodeIfPresent("renderConfigs") ?? self.renderConfigs
            self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
            self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
            
            try! super.superDecode(from: decoder)
        }
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public func hasState(_ stateName:String) -> Bool{
        if activeStates.contains(stateName){
            return true
        }
        return false
    }
    
    public func toggleState(_ stateName:String) {
        if let index = activeStates.index(of: stateName){
            activeStates.remove(at: index)
        }
        else {
            activeStates.append(stateName)
        }
    }
    
    public func merge(_ view:SessionView) {
        
        self.queryOptions!.merge(view.queryOptions!)
        
        self.name = view.name ?? self.name
        self.rendererName = view.rendererName ?? self.rendererName
        self.backTitle = view.backTitle ?? self.backTitle
        self.icon = view.icon ?? self.icon
        self.browsingMode = view.browsingMode ?? self.browsingMode
        
        self.title = view.title ?? self.title
        self.subtitle = view.subtitle ?? self.subtitle
        self.filterText = view.filterText ?? self.filterText
        self.emptyResultText = view.emptyResultText ?? self.emptyResultText
        
        self.showLabels.value = view.showLabels.value ?? self.showLabels.value
        
        if view.sortFields.count > 0 {
            self.sortFields.removeAll()
            self.sortFields.append(objectsIn: view.sortFields)
        }
        
        self.cascadeOrder.append(objectsIn: view.cascadeOrder)
        self.selection.append(objectsIn: view.selection)
        self.editButtons.append(objectsIn: view.editButtons)
        self.filterButtons.append(objectsIn: view.filterButtons)
        self.actionItems.append(objectsIn: view.actionItems)
        self.navigateItems.append(objectsIn: view.navigateItems)
        self.contextButtons.append(objectsIn: view.contextButtons)
        
        if let renderConfigs = view.renderConfigs {
            self.renderConfigs!.merge(renderConfigs)
        }
        
        self.actionButton = view.actionButton ?? self.actionButton
        self.editActionButton = view.editActionButton ?? self.editActionButton
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> SessionView {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! MemriJSONDecoder.decode(SessionView.self, from: jsonData)
        return items
    }
    
    public class func fromJSONString(_ json: String) throws -> SessionView {
        let view:SessionView = try MemriJSONDecoder.decode(SessionView.self, from: Data(json.utf8))
        return view
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

    var cascadeOrder: [String] = []
    var sortFields: [String] = []
    var selection: [DataItem] = []
    var editButtons: [ActionDescription] = []
    var filterButtons: [ActionDescription] = []
    var actionItems: [ActionDescription] = []
    var navigateItems: [ActionDescription] = []
    var contextButtons: [ActionDescription] = []
    var activeStates: [String] = []
    
    var renderer: Renderer? = nil // TODO 
    var rendererView: AnyView? = nil // TODO
    var sessionView: SessionView? = nil
    var renderConfigs: RenderConfigs = RenderConfigs()
    var actionButton: ActionDescription? = nil
    var editActionButton: ActionDescription? = nil
    
    private var _emptyResultText: String = "No items found"
    private var _emptyResultTextTemp: String? = nil
    var emptyResultText: String {
        get {
            return _emptyResultTextTemp ?? _emptyResultText
        }
        set (newEmptyResultText) {
            if newEmptyResultText == "" { _emptyResultTextTemp = nil }
            else { _emptyResultTextTemp = newEmptyResultText }
        }
    }
    
    private var _title: String = ""
    private var _titleTemp: String? = nil
    var title: String {
        get {
            return _titleTemp ?? _title
        }
        set (newTitle) {
            if newTitle == "" { _titleTemp = nil }
            else { _titleTemp = newTitle }
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
                emptyResultText = ""
            }
            else {
                // Set the title to an appropriate message
                if resultSet.count == 0 { title = "No results" }
                else if resultSet.count == 1 { title = "1 item found" }
                else { title = "\(resultSet.count) items found" }
                
                // Temporarily hide the subtitle
                // subtitle = " " // TODO how to clear the subtitle ??
                
                emptyResultText = "No results found using '\(_filterText)'"
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
        _emptyResultText = view.emptyResultText ?? _emptyResultText
        
        self.showLabels = view.showLabels.value ?? self.showLabels
        
        if view.sortFields.count > 0 {
            self.sortFields.removeAll()
            self.sortFields.append(contentsOf: view.sortFields)
        }
        
        self.cascadeOrder.append(contentsOf: view.cascadeOrder)
        self.selection.append(contentsOf: view.selection)
        self.editButtons.append(contentsOf: view.editButtons)
        self.filterButtons.append(contentsOf: view.filterButtons)
        self.actionItems.append(contentsOf: view.actionItems)
        self.navigateItems.append(contentsOf: view.navigateItems)
        self.contextButtons.append(contentsOf: view.contextButtons)
        self.activeStates.append(contentsOf: view.activeStates)
        
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
    
    public func toggleState(_ stateName:String) {
        if let index = activeStates.firstIndex(of: stateName){
            activeStates.remove(at: index)
        }
        else {
            activeStates.append(stateName)
        }
    }
    
    public func hasState(_ stateName:String) -> Bool{
        if activeStates.contains(stateName){
            return true
        }
        return false
    }
    
    public func getPropertyValue(_ name:String) -> Any {
        let type: Mirror = Mirror(reflecting:self)

        for child in type.children {
            if child.label! == name || child.label! == "_" + name {
                return child.value
            }
        }
        
        return ""
    }
    
}

public class DynamicView: Object, ObservableObject, Codable {
    /**
     *
     */
    @objc dynamic var name:String = ""
    /**
     *
     */
    @objc dynamic var declaration:String = ""
    /**
     *
     */
    @objc dynamic var fromTemplate:String? = nil
    
    public override static func primaryKey() -> String? {
        return "name"
    }
    
    public init(_ decl:String) {
        declaration = decl
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.declaration = try decoder.decodeIfPresent("declaration") ?? self.declaration
            self.fromTemplate = try decoder.decodeIfPresent("copyFromView") ?? self.fromTemplate
        }
    }
        
    required init() {
        super.init()
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> DynamicView {
        let jsonData = try jsonDataFromFile(file, ext)
        let view:DynamicView = try MemriJSONDecoder.decode(DynamicView.self, from: jsonData)
        return view
    }
    
    public class func fromJSONString(_ json: String) throws -> DynamicView {
        let view:DynamicView = try MemriJSONDecoder.decode(DynamicView.self, from: Data(json.utf8))
        return view
    }
}

public class CompiledView {
    /**
     *
     */
    var name: String = ""
    /**
     *
     */
    var variables: [String:String] = [:]
    /**
     *
     */
    var parsed: [String:Any]? = nil
    /**
     *
     */
    var jsonString: String = ""
    /**
     *
     */
    var dynamicView:DynamicView
    /**
     *
     */
    var lastSessionView:SessionView? = nil
    /**
     *
     */
    var hasSession:Bool = false
    /**
     *
     */
    var views:[CompiledView] = []
    
    private var main:Main

    init(_ view:DynamicView, _ mn:Main) throws {
        main = mn
        dynamicView = view
    }
    
    /**
     *
     */
    func parse() throws {
        // Turn the declaration in json data
        let data = dynamicView.declaration.data(using: .utf8)!
        
        // Parse the declaration
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        guard let object = json as? [String: Any] else {
            throw "Exception: Invalid JSON while parsing view" // TODO better errors
        }
            
        // Store the parsed json in memory
        parsed = object
        
        // Detect whether this item has a session
        hasSession = object["views"] != nil
        
        // Find all dynamic properties and compile them
        func recursiveWalk(_ parsed:inout [String:Any]) throws {
            for (key, _) in parsed {
                
                // Do not parse actionStateName as it is handled at runtime (when action is executed)
                if key == "actionStateName" { continue }
                
                // Turn renderDescription in a string for persistence in realm
                else if key == "renderDescription" {
                    
                    var pDict:[String:Any]
                    if let pList = parsed[key] as? [Any] { pDict = ["*": pList] }
                    else { pDict = parsed }
                    
                    parsed.updateValue(try! parseRenderDescription(pDict), forKey: key)
                }
                    
                // Parse rest of the json
                else {
                    
                    // If its an object continue the walk to find strings to update
                    var subParsed = parsed[key] as? [String:Any]
                    if subParsed != nil {
                        try! recursiveWalk(&subParsed!)
                        parsed.updateValue(subParsed!, forKey: key)
                    }
                    // Update strings
                    else if let propValue = parsed[key] as? String {
                        
                        // Compile the property for easy lookup
                        let newValue = compileProperty(propValue)
                        
                        // Updated the parsed object with the new value
                        parsed.updateValue(newValue, forKey: key)
                    }
                }
            }
        }
        
        // Generating a session of multiple compiled views
        if hasSession, let list = object["views"] as? [Any] {
            
            // Loop through all view
            for i in 0..<list.count {
                
                // If the view is a string look up its template
                if let value = list[i] as? String {
                    
                    // Find the compiled view
                    let compiledView = main.views.getCompiledView(value)
                    
                    // Append it to the list of views
                    views.append(compiledView!) // TODO error handling
                }
                    
                // Or if its a literal view parse it
                else if var value = list[i] as? [String: Any] {
                    
                    // Start walking to parse values from this part of the subtree
                    try! recursiveWalk(&value)
                    
                    // Create a dynamic view
                    let dynamicView = DynamicView(value: [
                        "declaration": serialize(AnyCodable(value))
                    ])
                    
                    // Create the compiled view
                    let compiledView = try! CompiledView(dynamicView, main)
                    
                    // Append it to the list of views
                    views.append(compiledView)
                }
            }
        }
        // Generating a single view template
        else {
            // Start walking
            try! recursiveWalk(&parsed!)
            
            // Set the new session view json
            jsonString = serialize(AnyCodable(parsed))
        }
    }
    

// How users type it
//    [ "VStack", { "padding": 5 }, [
//        "Text", { "value": "{.content}" },
//        "Button", { "press": {"actionName": "back"} }, ["Text", "Back"],
//        "Button", { "press": {"actionName": "openView"} }, [
//            "Image", {"systemName": "star.fill"}
//        ],
//        "Text", { "value": "{.content}" }
//    ]]
    
// How codable wants it
//    {
//        "type": "vstack",
//        "children": [
//            {
//                "type": "text",
//                "properties": {
//                    "value": "{.title}",
//                    "bold": true
//                }
//            },
//            {
//                "type": "text",
//                "properties": {
//                    "values": "{.content}",
//                    "bold": false,
//                    "removeWhiteSpace": true,
//                    "maxChar": 100
//                }
//            }
//        ]
//    }
    
    private func parseRenderDescription(_ parsed: [String:Any]) throws -> String {
        var result:[String:Any] = [:]
        
        for (key, value) in parsed {
            result[key] = try! parseSingleRenderDescription(value as! [Any])
        }
        
        return serialize(AnyCodable(result))
    }
    
    private func parseSingleRenderDescription(_ parsed:[Any]) throws -> Any {
        var result:[Any] = []
        
        func walkParsed(_ parsed:[Any], _ result:inout [Any]) throws {
            var currentItem:[String:Any] = [:]
            
            for item in parsed {
                if let item = item as? String {
                    if currentItem["type"] != nil { result.append(currentItem) }
                    currentItem = ["type": item.lowercased()]
                }
                else if let item = item as? [String: Any] {
                    currentItem["properties"] = item
                }
                else if let item = item as? [Any] {
                    var children:[Any] = []
                    try! walkParsed(item, &children)
                    currentItem["children"] = children
                }
                else {
                    throw "Exception: Could not parse render description"
                }
            }
            
            if currentItem["type"] != nil { result.append(currentItem) }
        }
        
        try! walkParsed(parsed, &result)
        
        return result[0]
    }
    
    public func compileProperty(_ expr:String) -> String {
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]+.[^\}]*)\})?)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var result:String = ""
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expr.startIndex..<expr.endIndex, in: expr)
        regex.enumerateMatches(in: expr, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            // We should have 4 matches
            if match.numberOfRanges == 3 {
                
                // Fetch the text portion of the match
                if let rangeText = Range(match.range(at: 1), in: expr) {
                    result += String(expr[rangeText])
                }
                
                // compute the string result of the expression
                if let rangeQuery = Range(match.range(at: 2), in: expr) {
                    let query = String(expr[rangeQuery])
                    
                    // Add the query to the variable list
                    variables[query] = String(variables.count)
                    
                    // Add an easy to find reference to the string
                    result += "{$\(variables[query]!)}"
                }
            }
        }
        
        return result
    }
    
    /**
     *
     */
    func generateView() throws -> SessionView {
        // Prevent views generated from a session template
        if self.hasSession { throw "Exception: Cannot generate view from a session template" }
        
        // Parse at first use
        if parsed == nil { try! parse() }
        
        // Return last compiled session view if this is not a dynamic view
        if dynamicView.fromTemplate == nil && variables.count == 0 && lastSessionView != nil {
            
            // Return a copy of the session view
            // TODO this can be optimized by signaling when views are used as a base in computing a view
            let view = SessionView()
            view.merge(lastSessionView!)
            
            return view
        }
        
        // Copy from the current view
        var view:SessionView? = nil
        if ["{view}", "{sessionView}"].contains(dynamicView.fromTemplate)  {
            
            // TODO add feature that validates the current view and checks whether
            //      the dynamic view can operate on it
            
            // Copy the current view
            view = SessionView()
            view!.merge(main.currentSession.currentView)
        }
        // Copy from a named view
        else if let copyFromView = dynamicView.fromTemplate {
            view = main.views.getSessionView(copyFromView) ?? SessionView()
        }
        
        // Fill the template with variables
        let template = insertVariables()
        
        // Generate session view from template
        let sessionView:SessionView = try! SessionView.fromJSONString(template)
        
        // Merge with the view that is copied, if any
        if let view = view {
            view.merge(sessionView)
        }
        else {
            view = sessionView
        }
        
        // Cache session view object in case it isnt dynamic
        lastSessionView = view
        
        return view!
    }
    
    func generateSession() throws -> Session {
        // Prevent views generated from a session template
        if !self.hasSession { throw "Exception: Cannot generate session from a view template" }
        
        // Parse at first use
        if parsed == nil { try! parse() }
        
        // Create new session object
        let session = Session(value: ["name": parsed!["name"] as! String])
        
//        var computedView:ComputedView
        for i in 0..<views.count {
            session.views.append(try! views[i].generateView())
            
            // TODO The code below is the beginning of allow dynamic views that refer the view
            //      or computedView to get the right reference. A major problem is that the data
            //      may not be loaded yet. This may be solved by loading from cache, or annotating
            //      the session view description. More thought is needed, so I'm leaving that out
            //      for now
            
//            overrides:[
//                "view": { () -> Any in views[i - 1] ?? nil },
//                "computedView": { () -> Any in
//                    if let cv = computedView { return computedView }
//                    else if i > 0 {
//                        computedView = main.views.computeView(session.views[i - 1])
//                        return computedView!
//                    }
//                }
//            ])
        }
        
        // set current session indicator to last element
        session.currentViewIndex = session.views.count - 1
        
        return session
    }
    
    public func insertVariables() -> String {
        var i = 0, template = jsonString
        for (key, index) in variables {
            // Compute the value of the variable
            let computedValue = queryObject(key)
            
            // Update the template with the variable
            // TODO make this more efficient. This could just be one regex search
            template = String(template.replacingOccurrences(of: "\\{\\$" + index + "\\}",
                with: computedValue, options: .regularExpression))
            
            // Increment counter
            i += 1
        }
        
        return template
    }
    
    public func queryObject(_ expr:String) -> String{

        // Split the property by dots to look up each property separately
        let propParts = expr.split(separator: ".")
        
        // Get the first property of the object
        var value:Any? = getProperty(String(propParts[0]), String(propParts[1]))
        
        // Check if the value is not nil
        if value != nil {
            
            // Loop through the properties and fetch each
            if propParts.count > 2 {
                for i in 2..<propParts.count {
                    value = (value as! Object)[String(propParts[i])]
                }
            }
            
            // Return the value as a string
            return value as! String
        }
        
        return ""
    }
    
    public func getProperty(_ object:String, _ prop:String) -> Any? {
        // Fetch the value of the right property on the right object
        switch object {
        case "main":
            return main[prop]
        case "sessions":
            return main.sessions[prop]
        case "currentSession":
            fallthrough
        case "session":
            return main.currentSession[prop]
        case "computedView":
            return main.computedView.getPropertyValue(prop)
        case "sessionView":
            return main.currentSession.currentView[prop]
        case "view":
            return main.computedView.getPropertyValue(prop)
        case "dataItem":
            if let item = main.computedView.resultSet.item {
                return item[prop]
            }
            else {
                print("Warning: No item found to get the property off")
            }
        default:
            print("Warning: Unknown object to get the property off: \(object) \(prop)")
        }
        
        return nil
    }
    
    public class func parseNamedViewList(_ data:Data) throws -> [DynamicView]? {
        
        // Parse JSON
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        if var parsedList = json as? [[String: Any]] {
            
            // Define result
            var result:[DynamicView] = []
            
            // Loop over results from parsed json
            for i in 0..<parsedList.count {
                
                // Create the dynamic view
                let view = DynamicView()
                
                // Parse values out of json
                if parsedList[i]["views"] == nil {
                    view.name = parsedList[i].removeValue(forKey: "name") as! String
                    view.fromTemplate = parsedList[i].removeValue(forKey: "fromTemplate") as? String ?? nil
                }
                else {
                    view.name = parsedList[i]["name"] as! String
                }
                
                view.declaration = serialize(AnyCodable(parsedList[i]))
                
                // Add the dynamic view to the result
                result.append(view)
            }
            
            return result
        }
        else {
            print("Warn: Invalid JSON while reading named view list")
        }
        
        return nil
    }
    
    public class func parseNamedViewDict(_ data:Data) throws -> ([String:[String:DynamicView]], [String:DynamicView]) {
        
        // Parse JSON
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        guard let parsedObject = json as? [String: [String: Any]] else {
            throw "Exception: Invalid JSON while reading named view list"
        }
            
        // Define result
        var result:[String:[String:DynamicView]] = [:]
        var named:[String:DynamicView] = [:]
        
        // Loop over results from parsed json
        for (section, lut) in parsedObject {
        
            // Loop over lookup table with named views
            for (key, object) in lut {
                let object = object as! [String:Any]
                    
                // Create the dynamic view
                let view = DynamicView()
                
                // Parse values out of json
                view.name = section + ":" + key
                view.fromTemplate = nil
                view.declaration = serialize(AnyCodable(object))
                
                // Add the dynamic view to the result
                if result[section] == nil { result[section] = [:] }
                
                // Store based on key
                result[section]![key] = view
                
                // Store based on name if set
                if object["name"] != nil {
                    named[object["name"] as! String] = view
                }
            }
        }
        
        // Done
        return (result, named)
    }
    
    public class func parseExpression(_ expression:String, _ defObject:String) -> (object:String, prop:String) {
        // By default we update the named property on the view
        var objectToUpdate:String = defObject, propToUpdate:String = expression
        
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"\{([^\.]+).(.*)\}"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expression.startIndex..<expression.endIndex, in: expression)
        regex.enumerateMatches(in: expression, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            if match.numberOfRanges == 3,
              let rangeObject = Range(match.range(at: 1), in: expression),
              let rangeProp = Range(match.range(at: 2), in: expression)
            {
                objectToUpdate = String(expression[rangeObject])
                propToUpdate = String(expression[rangeProp])
            }
        }
        
        return (objectToUpdate, propToUpdate)
    }
}
