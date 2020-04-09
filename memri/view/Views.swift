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
        var rendererName:String
        
        cascadeOrders["defaults"]![0].append(objectsIn: ["renderer", "datatype"])
        
        // If we know the type of data we are rendering use it to determine the view
        if type != "mixed" {
            // Determine query
            let needle = isList ? "{[type:\(type)]}" : "{type:\(type)}"
            
            // Find views based on datatype
            for key in searchOrder {
                if let datatypeView = getSessionView(self.defaultViews[key]![needle]) {
                    datatypeViews.append(datatypeView)
                    
                    dump(datatypeView.name)
                    dump(datatypeView.actionButton)
                    
                    if let S = datatypeView.rendererName { rendererNames.append(S) }
                    if datatypeView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(datatypeView.cascadeOrder)
                    }
                }
            }
            
            rendererName = rendererNames[rendererNames.count - 1]
        }
        // Otherwise default to what we know from the view from the session
        else {
            rendererName = viewFromSession.rendererName ?? ""
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


public class SessionView: Object, ObservableObject, Codable {
    
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
    
    /**
     *
     */
    @objc dynamic var syncState:SyncState? = SyncState()
    
    private enum CodingKeys: String, CodingKey {
        case queryOptions, title, rendererName, name, subtitle, selection, renderConfigs,
            editButtons, filterButtons, actionItems, navigateItems, contextButtons, actionButton,
            backTitle, editActionButton, icon, showLabels,
            browsingMode, cascadeOrder, activeStates, emptyResultText
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
    
    public func copy() -> SessionView {
        let view = SessionView()
        
        view.queryOptions!.merge(self.queryOptions!)
        
        view.name = self.name
        view.rendererName = self.rendererName
        view.backTitle = self.backTitle
        view.icon = self.icon
        view.browsingMode = self.browsingMode
        
        view.title = self.title
        view.subtitle = self.subtitle
        view.filterText = self.filterText
        view.emptyResultText = self.emptyResultText
        
        view.showLabels.value = self.showLabels.value
        
        view.cascadeOrder.append(objectsIn: self.cascadeOrder)
        view.selection.append(objectsIn: self.selection)
        view.editButtons.append(objectsIn: self.editButtons)
        view.filterButtons.append(objectsIn: self.filterButtons)
        view.actionItems.append(objectsIn: self.actionItems)
        view.navigateItems.append(objectsIn: self.navigateItems)
        view.contextButtons.append(objectsIn: self.contextButtons)
        view.activeStates.append(objectsIn: self.activeStates)
        
        if let renderConfigs = self.renderConfigs {
            view.renderConfigs!.merge(renderConfigs)
        }
        
        view.actionButton = self.actionButton
        view.editActionButton = self.editActionButton
        
        return view
    }
    
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

    var cascadeOrder: [String] = []
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
        let view:DynamicView = try JSONDecoder().decode(DynamicView.self, from: jsonData)
        return view
    }
    
    public class func fromJSONString(_ json: String) throws -> DynamicView {
        let view:DynamicView = try JSONDecoder().decode(DynamicView.self, from: Data(json.utf8))
        return view
    }
}

public class CompiledView {
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
        
        // TODO this is the place to optimize compilation
        // - Fetch all variables and put them in .variables
        // - Fill variables and replace them in the json when doing generateView()
        
        func recursiveWalk(_ object:Object, _ parsed:[String:Any]) throws {
            for (key, _) in parsed {
                
                // Do not parse actionStateName as it is handled at runtime (when action is executed)
                if key == "actionStateName" { continue }
                
                do {
                    if object.objectSchema[key] == nil {
                        throw "Exception: Invalid key while parsing view: \(key)"
                    }
                    
                    // If its an object continue the walk to find strings to update
                    if let _ = parsed[key] as? [String:Any] {
                        print(key)
                        try! recursiveWalk(object[key] as! Object, parsed[key] as! [String:Any])
                    }
                    // Update strings
                    else if let prop = parsed[key] as? String {
                        object[key] = computeString(prop)
                    }
                }
                catch { // Error can be thrown by illegal subscript access
                    print("Warn: Could not find property: \(key)")
                }
            }
        }
        
        try! recursiveWalk(view, parsed!)
    }
    
    /**
     *
     */
    func generateView() throws -> SessionView {
        var view:SessionView
        
        // Parse at first use
        if parsed == nil { try! parse() }
        
        // Copy from the current view
        if ["{view}", "{sessionView}"].contains(dynamicView.fromTemplate)  {
            
            // TODO add feature that validates the current view and checks whether
            //      the dynamic view can operate on it
            
            // Copy the current view
            view = main.currentSession.currentView.copy()
        }
        // Copy from a named view
        else if let copyFromView = dynamicView.fromTemplate {
            view = main.views.getSessionView(copyFromView) ?? SessionView()
        }
        // Start from a new view
        else {
            view = SessionView()
        }
        
        func recursiveWalk(_ object:Object, _ parsed:[String:Any]) throws {
            for (key, _) in parsed {
                
                // Do not parse actionStateName as it is handled at runtime (when action is executed)
                if key == "actionStateName" { continue }
                
                do {
                    if object.objectSchema[key] == nil {
                        throw "Exception: Invalid key while parsing view: \(key)"
                    }
                    
                    // If its an object continue the walk to find strings to update
                    if let _ = parsed[key] as? [String:Any] {
                        print(key)
                        try! recursiveWalk(object[key] as! Object, parsed[key] as! [String:Any])
                    }
                    // Update strings
                    else if let prop = parsed[key] as? String {
                        object[key] = computeString(prop)
                    }
                }
                catch { // Error can be thrown by illegal subscript access
                    print("Warn: Could not find property: \(key)")
                }
            }
        }
        
        try! recursiveWalk(view, parsed!)
        
        return view
    }
    
    public func computeString(_ expr:String) -> String {
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]+).([^\{]*)\})?)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var result:String = ""
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expr.startIndex..<expr.endIndex, in: expr)
        regex.enumerateMatches(in: expr, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            // We should have 4 matches
            if match.numberOfRanges == 4 {
                
                // Fetch the text portion of the match
                if let rangeText = Range(match.range(at: 1), in: expr) {
                    result += String(expr[rangeText])
                }
                
                // compute the string result of the expression
                if let rangeObject = Range(match.range(at: 2), in: expr),
                  let rangeProp = Range(match.range(at: 3), in: expr) {
                    result += queryObject(String(expr[rangeObject]), String(expr[rangeProp]))
                }
            }
        }
        
        return result
    }
    
    public func queryObject(_ object:String, _ prop:String) -> String{
        if object == "" || prop == "" { return "" } // TODO think about having a default object
        
        // Split the property by dots to look up each property separately
        let propParts = prop.split(separator: ".")
        
        // Get the first property of the object
        var value:Any? = getProperty(object, String(propParts[0]))
        
        // Check if the value is not nil
        if value != nil {
            
            // Loop through the properties and fetch each
            if propParts.count > 1 {
                for i in 1...propParts.count - 1 {
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
                view.name = parsedList[i].removeValue(forKey: "name") as! String
                view.fromTemplate = parsedList[i].removeValue(forKey: "fromTemplate") as? String ?? nil
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
