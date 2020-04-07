import Foundation
import Combine
import SwiftUI
import RealmSwift

public class SessionView: Object, ObservableObject, Codable {
    
    /**
     *
     */
    @objc dynamic var queryOptions: QueryOptions? = QueryOptions()
    @objc dynamic var renderConfigs: RenderConfigs? = RenderConfigs()
    
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
    
    var renderer: RendererObject? = nil // TODO 
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

public class DynamicView: ObservableObject {
    /**
     *
     */
    var declaration:String
    /**
     *
     */
    var copyCurrentView:Bool = false
    /**
     *
     */
    var parsed: [String:Any] = [:]
    
    private var main:Main
    
    init(_ decl:String, _ mn:Main) {
        declaration = decl
        main = mn
        
        parsed = parse() ?? [:]
        copyCurrentView = parsed["copyFrom"] as? Bool ?? false
    }
    
    func parse() -> [String:Any]? {
        let data = declaration.data(using: .utf8)!
        
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        if let object = json as? [String: Any] {
            return object
        }
//        else if let object = json as? [Any] {
//            // json is an array
//        }
        else {
            print("Warn: Invalid JSON while parsing view")
        }
        
        return nil
    }
    
    func generateView() -> SessionView {
        var view:SessionView
        
        // Copy from an existing view if so desired
        if copyCurrentView {
            view = main.currentSession.currentView.copy()
        }
        else {
            view = SessionView()
        }
        
        func recursiveWalk(_ object:Object, _ parsed:[String:Any]) {
            for (key, _) in parsed {
                
                // Skip copyCurrentView as this is only for ComputableView
                if key == "copyCurrentView" { continue }
                
                do {
                    // If its an object continue the walk to find strings to update
                    if let prop = object[key] as? Object {
                        recursiveWalk(prop, parsed[key] as! [String:Any])
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
        
        recursiveWalk(view, parsed)
        
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
        else {
            return ""
        }
        
//        // Fetch the value of the right property on the right object
//        switch object {
//        case "sessions":
//            return main.sessions[prop] as! String
//        case "currentSession":
//            fallthrough
//        case "session":
//            return main.currentSession[prop] as! String
//        case "computedView":
//            return main.computedView.getPropertyValue(prop) as! String
//        case "sessionView":
//            return main.currentSession.currentView[prop] as! String
//        case "view":
//            return main.computedView.getPropertyValue(prop) as! String
//        case "dataItem":
//            if let item = main.computedView.resultSet.item {
//                return item.getString(prop)
//            }
//            else {
//                print("Warning: No item found to update")
//            }
//        default:
//            print("Warning: Unknown object to query: \(object) \(prop)")
//        }
        
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
                print("Warning: No item found to update")
            }
        default:
            print("Warning: Unknown object to query: \(object) \(prop)")
        }
        
        return nil
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
