
//
//  ComponentClasses.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

let ViewConfig:[String:[String]] = [
    "frame": ["minwidth", "maxwidth", "minheight", "maxheight", "align"],
    "order": ["frame", "color", "font", /*"rowinset",*/ "padding", "background", "textalign",
              "rowbackground", "cornerradius", "cornerborder", "border", "margin", "shadow", "offset",
              "blur", "opacity", "zindex"]
]

extension View {
    func setProperties(_ properties:[String:Any], _ item:DataItem) -> AnyView {
        var view:AnyView = AnyView(self)
        
        for name in ViewConfig["order"]! {
            if var value = properties[name] {
                
                // Compile string properties
                if let compiled = value as? GUIElementDescription.CompiledProperty {
                    value = GUIElementDescription.computeProperty(compiled, item) ?? ""
                }
                
                view = view.setProperty(name, value)
            }
        }
        
        return AnyView(view)
    }
    
    func setProperty(_ name:String, _ value:Any) -> AnyView {
        switch name {
        case "shadow":
            if let value = value as? [Any] {
                return AnyView(self.shadow(color: Color(hex: value[0] as! String),
                            radius: value[1] as! CGFloat,
                            x: value[2] as! CGFloat,
                            y: value[3] as! CGFloat))
            }
        case "margin":
            fallthrough
        case "padding":
            if let value = value as? [CGFloat] {
                return AnyView(self
                    .padding(.top, value[0])
                    .padding(.trailing, value[1])
                    .padding(.bottom, value[2])
                    .padding(.leading, value[3]))
            }
            else if let value = value as? CGFloat {
                return AnyView(self.padding(value))
            }
        case "blur":
            if let value = value as? CGFloat {
                return AnyView(self.blur(radius: value))
            }
        case "opacity":
            if let value = value as? CGFloat {
                return AnyView(self.opacity(Double(value)))
            }
        case "color":
            if let value = value as? String {
                return AnyView(self.foregroundColor(value.first == "#"
                    ? Color(hex: value) : Color(value))) //TODO named colors do not work
            }
        case "background":
            if let value = value as? String {
                return AnyView(self.background(value.first == "#"
                    ? Color(hex: value) : Color(value))) //TODO named colors do not work
            }
        case "rowbackground":
            if let value = value as? String {
                return AnyView(self.listRowBackground(value.first == "#"
                    ? Color(hex: value) : Color(value))) //TODO named colors do not work
            }
        case "border":
            if let value = value as? [Any] {
                if let color = value[0] as? String {
                    return AnyView(self.border(Color(hex:color), width: value[1] as! CGFloat))
                }
            }
//        case "rowinset":
//            if let value = value as? [CGFloat] {
//                return AnyView(self.listRowInsets(EdgeInsets(
//                    top: value[0],
//                    leading: value[3],
//                    bottom: value[2],
//                    trailing: value[1])))
//            }
//            else if let value = value as? CGFloat {
//                return AnyView(self.listRowInsets(EdgeInsets(top: value,
//                            leading: value, bottom: value, trailing: value)))
//            }
        case "offset":
            if let value = value as? [CGFloat] {
                return AnyView(self.offset(x: value[0], y: value[1]))
            }
        case "zindex":
            if let value = value as? CGFloat {
                return AnyView(self.zIndex(Double(value)))
            }
        case "cornerradius":
            if let value = value as? CGFloat {
                return AnyView(self.cornerRadius(value))
            }
        case "cornerborder":
            if let value = value as? [Any] {
                if let color = value[0] as? String {
                    return AnyView(self.overlay(
                        RoundedRectangle(cornerRadius: value[2] as! CGFloat)
                            .stroke(Color(hex: color), lineWidth: value[1] as! CGFloat)
                            .padding(1)
                    ))
                }
            }
        case "frame":
            if let value = value as? [Any] {
                return AnyView(self.frame(
                    minWidth: value[0] as? CGFloat ?? .none,
                    maxWidth: value[1] as? CGFloat ?? .greatestFiniteMagnitude,
                    minHeight: value[2] as? CGFloat ?? .none,
                    maxHeight: value[3] as? CGFloat ?? .greatestFiniteMagnitude,
                    alignment: value[4] as? Alignment ?? .top))
            }
        case "font":
            if let value = value as? [Any] {
                var font:Font
                if let name = value[0] as? String {
                    font = .custom(name, size: value[1] as! CGFloat)
                }
                else {
                    font = .system(size: value[0] as! CGFloat,
                                   weight: value[1] as! Font.Weight,
                                   design: .default)
                }
                return AnyView(self.font(font))
            }
        case "textalign":
            if let value = value as? TextAlignment {
                return AnyView(self.multilineTextAlignment(value))
            }
        case "minwidth", "minheight", "align", "maxwidth", "maxheight", "spacing", "alignment", "text", "maxchar", "removewhitespace", "bold":
            break
        default:
            print("NOT IMPLEMENTED PROPERTY: \(name)")
        }
        
        return AnyView(self)
    }
    
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional { return AnyView(content(self)) }
        else { return AnyView(self) }
    }
    
    // TODO Refactor: use only one path to draw this (is that possible?)
    func border(width: [CGFloat], color: Color) -> some View {
        var x:AnyView = AnyView(self)
        if width[0] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[0], edge: .leading).foregroundColor(color)))
        }
        if width[1] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[1], edge: .top).foregroundColor(color)))
        }
        if width[2] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[2], edge: .trailing).foregroundColor(color)))
        }
        if width[3] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[3], edge: .bottom).foregroundColor(color)))
        }
        
        return x
    }
    func border(width: CGFloat, edge: Edge, color: Color) -> some View {
        self.overlay(
            EdgeBorder(width: width, edge: edge).foregroundColor(color)
        )
    }
}

extension Text {
    func `if`(_ conditional: Bool, content: (Self) -> Text) -> Text {
        if conditional { return content(self) }
        else { return self }
    }
}

//extension Image {
//    func `if`(_ conditional: Bool, content: (Self) -> Image) -> Image {
//        if conditional { return content(self) }
//        else { return self }
//    }
//}

struct EdgeBorder: Shape {

    var width: CGFloat
    var edge: Edge

    func path(in rect: CGRect) -> Path {
        var x: CGFloat {
            switch edge {
            case .top, .bottom, .leading: return rect.minX
            case .trailing: return rect.maxX - width
            }
        }

        var y: CGFloat {
            switch edge {
            case .top, .leading, .trailing: return rect.minY
            case .bottom: return rect.maxY - width
            }
        }

        var w: CGFloat {
            switch edge {
            case .top, .bottom: return rect.width
            case .leading, .trailing: return self.width
            }
        }

        var h: CGFloat {
            switch edge {
            case .top, .bottom: return self.width
            case .leading, .trailing: return rect.height
            }
        }

        return Path( CGRect(x: x, y: y, width: w, height: h) )
    }
}

/*
    TODO: In order to support mixed content we will need to add an element that renders a dataitem
          based on the way it is rendered by default for that (multi-item) renderer. This should be
          overwritable with a renderDescription for that renderer that is for a specific view-type.
          i.e. for the view-type "inbox". The default render description can always be specified
          using *. Here's an example:
 
            "renderConfigs": {
                "list": {
                    "renderDescription": [
                        "VStack", ["Text", {"text": "Hello"}]
                    ]
                },
                "inbox": {
                    "renderDescription": [
                        "VStack", ["Image", {"systemName": "email"}]
                    ]
                }
            }
        
          Inbox in the above example is a virtual renderer that is added to a dict on the
          renderConfigs object. Virtual renderers are useful for composability in the hands of
          users. For instance the memri button rendering can be implemented using a virtual
          renderer that simply renders the button in a SubView (see below) and can be customized
          for each type, without the need of actually implementing a renderer.
 
          For this purpose we need to introduce a new element called "ItemCell", this will render
          the data item as if it was rendered inside the renderer of that type when it would be
          only showing elements of that type (i.e. "[{type:Person}]" in views_from_json). It would
          look like this:
 
            ItemCell(dataItem, rendererNames [, viewOverride])
 
          with viewOverride being the name of a view that should be the template instead of the
          default. rendererNames is an array of rendererName so that it can search for multiple,
          for instance if the data item doesnt have definitions for one renderer, but it does for
          another.
 
          The inbox renderer can overlay other elements in its rendering, like this:
 
            // this is the inbox render config
            renderConfigs: {
                list: {
                    renderDescription: [
                        "ZStack", [
                            "VStack", ["Text", {"text": "Type: {.type}"}],
                            "ItemCell", {
                                "dataItem": "{.}",
                                "rendererNames: ["inbox", "list", "thumbnail", "map"]
                            }
                        ],
                    ]
                }
            }
 
          In addition and to facilitate the abilities of the view hyper network is the introduction of
          the subview element that can display views inline. An immediate use case is to view a list
          of views (in fact they are sessions, but its easier to perceive them as views), and
          instead of seeing a screenshot of the last state they are the actual live instantiation of
          that view. This can be used for showing a list of charts that are easy to scroll through
          and thus easy to check daily without having to go to many views (N.B. this can somewhat be
          achieved with a session that has a history of each chart you want. you can then navigate
          with the back button and via the list of views in the session. However this is not as
          easy as scrolling). This is the signature of the element
 
            SubView(viewName or viewInstance, dataItem, variables)
 
          And the renderConfig of the session view for the charts could look like this:
          
            renderConfigs: {
                list: {
                    renderDescription: [
                        "VStack", [
                            "Text", {"text": "{.computedTitle}"},
                            "SubView", {
                                "view": "{.}", // or "viewName": "someView" for other use cases
                                "dataItem": "{.}", // this could be left out in this case
                                "variables": {
                                    "toolbar": false,
                                    "readonly": true
                                }
                            }
                        ]
                    ]
                }
            }
 
          In order for the hyper network to work openView needs to be extended to be able to open
          views from URIs (file, http, elsewhere), and to download any additional data from sources
          other than the pod, for usage in memri. We can even imagine a limited web renderer of views
          that people can embed on their website, where they also link to the view for download in
          memri. By allowing views to refer to each other a network of knowledge can appear. But the
          exact shape of that is still beyond the horizon of my imagination.
 */
             
public class GUIElementDescription: Codable {
    var type: String = ""
    var properties: [String: AnyCodable] = [:]
    var children: [GUIElementDescription] = []
    var _properties: [String:Any] = [:]
    
    private enum CodingKeys: String, CodingKey {
        case type, properties, children
    }
    
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            children = try decoder.decodeIfPresent("children") ?? children
            properties = try decoder.decodeIfPresent("properties") ?? properties
            
            parseProperties(properties)
        }
    }
    
    func parseProperties(_ props:[String:AnyCodable]){
        for (key, value) in props {
            _properties[key.lowercased()] = parseProperty(key, value.value)
        }
        
        for item in ViewConfig["frame"]! {
            if _properties[item] != nil {
                
                let values:[Any?] = [
                    _properties["minwidth"] as Any?,
                    _properties["maxwidth"] as Any?,
                    _properties["minheight"] as Any?,
                    _properties["maxheight"] as Any?,
                    _properties["align"] as Any?
                ]
                
                _properties["minwidth"] = nil
                _properties["maxwidth"] = nil
                _properties["minheight"] = nil
                _properties["maxheight"] = nil
                _properties["align"] = nil
                
                _properties["frame"] = values
                break
            }
        }
        
        if _properties["cornerradius"] != nil && _properties["border"] != nil {
            var value = _properties["border"] as! [Any]
            value.append(_properties["cornerradius"]!)
            
            _properties["cornerborder"] = value as Any
            _properties["border"] = nil
        }
    }
    
    func parseProperty(_ key:String, _ value:Any) -> Any? {
        if key == "alignment" {
            switch value as! String {
            case "left": return HorizontalAlignment.leading
            case "top": return VerticalAlignment.top
            case "right": return HorizontalAlignment.trailing
            case "bottom": return VerticalAlignment.bottom
            case "center":
                if self.type == "zstack" { return Alignment.center }
                return self.type == "vstack"
                    ? HorizontalAlignment.center
                    : VerticalAlignment.center
            default: return nil
            }
        }
        else if key == "align" {
            switch value as! String {
            case "left": return Alignment.leading
            case "top": return Alignment.top
            case "right": return Alignment.trailing
            case "bottom": return Alignment.bottom
            case "center": return Alignment.center
            case "lefttop", "topleft": return Alignment.topLeading
            case "righttop", "topright": return Alignment.topTrailing
            case "leftbottom", "bottomleft": return Alignment.bottomLeading
            case "rightbottom", "bottomright": return Alignment.bottomTrailing
            default: return nil
            }
        }
        else if key == "textalign" {
            switch value as! String {
            case "left": return TextAlignment.leading
            case "center": return TextAlignment.center
            case "right": return TextAlignment.trailing
            default: return nil
            }
        }
        else if let value = value as? String {
            return compile(value)
        }
        else if let value = value as? Int {
            return CGFloat(value)
        }
        else if let value = value as? Double {
            return CGFloat(value)
        }
        else if var value = value as? [Any] {
            for i in 0..<value.count {
                value[i] = parseProperty("", value[i])!
            }
            
            if key == "font", let _ = value[0] as? CGFloat {
                if value.count == 1 { value.append("regular") }
                let weight = value[1] as! String
                
                switch weight {
                case "regular": value[1] = Font.Weight.regular
                case "bold": value[1] = Font.Weight.bold
                case "semibold": value[1] = Font.Weight.semibold
                case "heavy": value[1] = Font.Weight.heavy
                case "light": value[1] = Font.Weight.light
                case "ultralight": value[1] = Font.Weight.ultraLight
                case "black": value[1] = Font.Weight.black
                default: value[1] = Font.Weight.medium
                }
            }
            
            return value
        }
        else if let value = value as? [String:Any] {
            if value["actionName"] != nil {
                return ActionDescription(
                    icon: value["icon"] as? String ?? nil,
                    title: value["title"] as? String ?? nil,
                    actionName: ActionName(rawValue: value["actionName"] as? String ?? "nil"),
                    actionArgs: (value["actionArgs"] as? [Any] ?? [] ).map { AnyCodable($0) },
                    actionType: ActionType(rawValue: value["actionType"] as? String ?? "nil")
                )
            }
        }
        
        return value
    }
    
    public struct CompiledProperty {
        var result: [Any]
    }
    
    // Parsed (example): "Views element at {.dateAccessed} with title: {.title}"
    // CompiledProperty becomes: ["Views element at ", ["dateAccessed"], " with title: ", ["title"]]
    func compile(_ expr: String) -> Any {
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]*\.?[^\}]*)\})?)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var result:[Any] = []
        var isCompiled = false
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(expr.startIndex..<expr.endIndex, in: expr)
        regex.enumerateMatches(in: expr, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            // We should have 4 matches
            if match.numberOfRanges == 3 {
                
                // Fetch the text portion of the match
                if let rangeText = Range(match.range(at: 1), in: expr) {
                    result.append(String(expr[rangeText]))
                }
                
                // compute the string result of the expression
                if let rangeQuery = Range(match.range(at: 2), in: expr) {
                    
                    var searchPath:[String]
                    if expr[rangeQuery] == "." {
                        searchPath = ["."]
                    }
                    else {
                        searchPath = expr[rangeQuery]
                            .split(separator: ".", omittingEmptySubsequences: false)
                            .map{ String($0) }
                        
                        if searchPath.first == "" {
                            searchPath[0] = "dataItem"
                        }
                    }
                    
                    // Detecting functions (could be more elegant) // TODO
                    if let last = searchPath.last, last.last == ")" {
                        searchPath[searchPath.count - 1] = "functions"
                        searchPath.append(String(last.prefix(last.count - 2)))
                    }
                    
                    // Add to the result for future fast parsing
                    result.append(searchPath)
                    
                    isCompiled = true
                }
            }
        }
        
        return isCompiled
            ? CompiledProperty(result: result)
            : (result as! [String]).joined()
    }
    
    public func has(_ propName:String) -> Bool {
        return _properties[propName] != nil
    }
    
    public func getString(_ propName:String, _ item:DataItem? = nil) -> String {
        return get(propName, item) ?? ""
    }
    
    public func getBool(_ propName:String, _ item:DataItem? = nil) -> Bool {
        return get(propName, item) ?? false
    }
    
    public func get<T>(_ propName:String, _ item:DataItem? = nil,
                       _ variables:[String: () -> Any] = [:]) -> T? {
        
        if let prop = _properties[propName] {
            let propValue = prop
            
            // Compile string properties
            if let compiled = propValue as? CompiledProperty {
                let x:T? = GUIElementDescription.computeProperty(compiled, item, variables)
                return x
            }
            
            // TODO REfactor: Properly generalize. It's weird to do this here. What other edge cases are there?
            if T.self == SessionView.self {
                return (SessionView(value: propValue) as! T)
            }
            
            return (propValue as! T)
        }
        return nil
    }
    
    public func getType(_ propName:String, _ item:DataItem) -> (PropertyType, String) {
        // TODO REfactor: Error Handling
        if let prop = _properties[propName] {
            let propValue = prop
            
            // Compile string properties
            // TODO: Refactor: the following wouldn't work: dataItem.address[0].street
            if let compiled = propValue as? CompiledProperty {
                if let dataItemPropName = (compiled.result.first as? [String])?.last {
                    let type = item.objectSchema[dataItemPropName]?.type
                    return (type ?? .any, dataItemPropName)
                }
            }
        }
        
        // TODO Refactor: Error Handling
        return (.any, "")
    }
    
    public class func formatDate(_ date:Date?) -> String{
        let showAgoDate:Bool? = Settings.get("user/general/gui/showDateAgo")
        
        if let date = date {
            // Compare against 36 hours ago
            if showAgoDate == false || date.timeIntervalSince(Date(timeIntervalSinceNow: -129600)) < 0 {
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = Settings.get("user/formatting/date") ?? "yyyy/MM/dd HH:mm"
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                return dateFormatter.string(from: date)
            }
            else {
                return date.timestampString ?? ""
            }
        }
        else {
            return "never"
        }
    }
    
    public class func formatDateSinceCreated(_ date:Date?) -> String{
        if let date = date {
            return date.timeDelta ?? ""
        }
        else {
            return "never"
        }
    }
    
    private class func traverseProperties<T>(_ item:DataItem, _ propParts:[String],
                                             _ variables:[String:()->Any]=[:]) -> T? {
        // Loop through the properties and fetch each
        var value:Any? = nil
        /*
            NOTE: If there is ever a desire to query other objects such as currentSession
                  or computedView, then this is the place to add that.
         */
        
        let isNegationTest = propParts.first?.first == "!"
        var firstItem = isNegationTest
            ? propParts[0].substr(1)
            : propParts[0]
        if isNegationTest && firstItem == "" { firstItem = "dataItem" }
        
        if firstItem == "dataItem" {
            value = item
        }
        else {
            if let f = variables[firstItem.lowercased()] {
                value = f()
            }
            else { // TODO Refactor: integrate in larger error handling effort
                print("Warn: fetching undefined variable: \(firstItem)")
                value = nil
            }
        }
        
        var lastPart:String? = nil
        var lastObject:Object? = nil
        for i in 1..<propParts.count {
            let part = propParts[i]
            
            if part == "functions" {
                value = (value as! DataItem).functions[propParts[i+1]];
                lastPart = nil
                break
            }
            else if part == "count" { // TODO support other collections
                value = (value as! RealmSwift.ListBase).count
                lastPart = nil
                break
            }
            else {
                lastPart = String(part)
                if value is Object{
                    lastObject = (value as! Object)
                    value = lastObject![lastPart!]

                }
                else{
                    lastObject = nil
                    print("THIS SHOULD NEVER HAPPEN 987239487234")
                    value = Array(arrayLiteral: value).count
                }
//                lastObject = (value as! Object)
//                value = lastObject![lastPart!]
            }
        }
        
        if let lastPart = lastPart, lastObject?.objectSchema[lastPart]?.isArray ?? false,
           let className = lastObject?.objectSchema[lastPart]?.objectClassName {
            
            // Convert Realm List into Array
            value = DataItemFamily(rawValue: className.lowercased())!.getCollection(value as Any)
        }
        
        // Format a date
        else if let date = value as? Date { value = formatDate(date) }
            
        // Get the image uri from a file
        else if let file = value as? File {
            if T.self == String.self {
                // Set the uri string as the value
                value = file.uri
            }
        }
            
        // Execute a custom function
        else if let f = value as? ([Any]?) -> String { value = f([]) }
        
        // Support boolean operations on multiple types
        else if T.self == Bool.self {
            if isNegationTest {
                value = negateAny(value ?? true)
            }
            else {
                value = !negateAny(value ?? false)
            }
        }
        
        // TODO: Refactor: Many things, but generalize and make sure all types are supported
        
        // Return the value as a string
        return value as? T
    }
    
    public class func computeProperty<T>(_ compiled:CompiledProperty, _ item:DataItem?,
                                         _ variables:[String:()->Any]=[:]) -> T? {
        
        // If this is a single lookup e.g. {.myBoolean} then lets return the actual
        // type rather than a string
        if compiled.result.count == 1, let result = compiled.result.first as? [String] {
            // TODO Error Handling
            let x:T? = traverseProperties(item!, result, variables)
            return x
        }
        else {
            return (compiled.result.map {
                if let s = $0 as? [String] { return traverseProperties(item!, s, variables) ?? ""}
                return $0 as! String
            }.joined() as! T)
        }
    }
    
    public static func fromJSONFile(_ file: String, ext: String = "json") throws -> GUIElementDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let comp: GUIElementDescription = try! MemriJSONDecoder.decode(GUIElementDescription.self, from: jsonData)
        return comp
    }
}

// All functions
extension GUIElementDescription {
    
    func processText(_ text: String) -> String{
        var outText = text
        let maxChar:CGFloat? = get("maxchar")
        
        outText = get("removewhitespace") ?? false ? removeWhiteSpace(text: text) : text
        outText = maxChar != nil ? String(outText.prefix(Int(maxChar!))) : outText
        
        return outText
    }
    
    func removeWhiteSpace(text: String) -> String{
        return text.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
    }
}

public struct GUIElementInstance: View {
    @EnvironmentObject var main: Main
    
    let from:GUIElementDescription
    let item:DataItem
    let variables:[String:()->Any]
    
    public init(_ gui:GUIElementDescription, _ dataItem:DataItem, _ opts:[String:()->Any]=[:]) {
        from = gui
        item = dataItem
        variables = opts
    }
    
    public func has(_ propName:String) -> Bool {
        return variables[propName] != nil || from.has(propName)
    }
    
    public func get<T>(_ propName:String) -> T? {
        if propName.first == "$" {
            // TODO Refactor Error Handling
            if let f = variables[propName.substr(1)] {
                return (f() as! T)
            }
            else { // TODO Refactor: integrate in larger error handling effort
                print("Warn: fetching undefined variable: \(propName.substr(1))")
                return nil
            }
        }
        else {
            return from.get(propName, item, variables)
        }
    }
    
    public func getImage(_ propName:String) -> UIImage {
        if let file:File? = get(propName) {
            return file?.asUIImage ?? UIImage()
        }
        
        return UIImage()
    }
    
    public func getList(_ propName:String) -> [DataItem] {
        let x:[DataItem]? = get("list")
        return x ?? []
    }
    
    // Keeping this around until sure that size setting is never needed
//    private func setSize<T:Shape>(_ view:T) -> SwiftUI.ModifiedContent<SwiftUI._SizedShape<T>, SwiftUI._FlexFrameLayout> {
//        let x:[CGFloat] = from.get("size")!
//
//        return view
//            .size(width: x[0], height: x[1])
//            .frame(maxWidth: x[0], maxHeight: x[1])
//                as! SwiftUI.ModifiedContent<SwiftUI._SizedShape<T>, SwiftUI._FlexFrameLayout>
//    }
    
//    private func setSize<T:Shape>(_ view:T) -> SwiftUI.ModifiedContent<T, SwiftUI._FlexFrameLayout> {
//        var x:[CGFloat] = from.get("size")!
//
//        if x[0] == 0 { x[0] = .greatestFiniteMagnitude }
//        if x[1] == 0 { x[1] = .greatestFiniteMagnitude }
//
//        return view
//            .frame(maxWidth: x[0], maxHeight: x[1])
//                as! SwiftUI.ModifiedContent<T, SwiftUI._FlexFrameLayout>
//    }

    private func resize(_ view:SwiftUI.Image) -> AnyView {
        let resizable:String = from.get("resizable", self.item)!
        let y = view.resizable()
        
        switch resizable {
        case "fill": return AnyView(y.aspectRatio(contentMode: .fill))
        case "fit": return AnyView(y.aspectRatio(contentMode: .fit))
        case "stretch": fallthrough
        default:
            return AnyView(y)
        }
    }
    
    @ViewBuilder
    public var body: some View {
        if (!has("condition") || get("condition") == true) {
            if from.type == "vstack" {
                VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                    self.renderChildren
                }
                .clipped()
                .animation(nil)
                .setProperties(from._properties, self.item)
            }
            else if from.type == "hstack" {
                HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                    self.renderChildren
                }
                .clipped()
                .animation(nil)
                .setProperties(from._properties, self.item)
            }
            else if from.type == "zstack" {
                ZStack(alignment: get("alignment") ?? .top) { self.renderChildren }
                    .clipped()
                    .animation(nil)
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "editorsection" {
                if self.has("title") {
                    Section(header: Text(LocalizedStringKey(
                        (self.get("title") ?? "").uppercased()
                    )).generalEditorHeader()){
                        Divider()
                        self.renderChildren
                        Divider()
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from._properties, self.item)
                }
                else {
                    VStack(spacing: 0){
                        self.renderChildren
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from._properties, self.item)
                }
            }
            else if from.type == "editorrow" {
                VStack (spacing: 0) {
                    VStack(alignment: .leading, spacing: 4){
                        if self.has("title") && self.get("nopadding") != true {
                            Text(LocalizedStringKey(self.get("title") ?? ""
                                .camelCaseToWords()
                                .lowercased()
                                .capitalizingFirstLetter())
                            )
                            .generalEditorLabel()
                        }
                        
                        self.renderChildren
                            .generalEditorCaption()
                    }
                    .fullWidth()
//                    .padding(.bottom, 10)
                    .padding(.leading, self.get("nopadding") != true ? 36 : 0)
                    .padding(.trailing, self.get("nopadding") != true ? 36 : 0)
                    .clipped()
                    .animation(nil)
                    .setProperties(from._properties, self.item)
                    .background(self.get("$readonly") ?? false
                        ? Color(hex:"#f9f9f9")
                        : Color(hex:"#f7fcf5"))
                    
                    if self.has("title") {
                        Divider().padding(.leading, 35)
                    }
                }

            }
            else if from.type == "editorlabel" {
                HStack (alignment: .center, spacing:15) {
                    Button (action:{}) {
                        Image (systemName: "minus.circle.fill")
                            .foregroundColor(Color.red)
                            .font(.system(size: 22))
                    }
                    
                    if self.has("title") {
                        Button (action:{}) {
                            HStack {
                                Text (LocalizedStringKey(self.get("title") ?? ""))
                                    .foregroundColor(Color.blue)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                Spacer()
                                Image (systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray)
                            }
                        }
                    }
                }
                .frame(minWidth: 130, maxWidth: 130, maxHeight: .infinity, alignment: .leading)
                .padding(10)
                .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
            }
            else if from.type == "button" {
                Button(action: { self.main.executeAction(self.get("press")!, self.item) }) {
                    self.renderChildren
                }
                .setProperties(from._properties, self.item)
            }
            else if from.type == "wrapstack" {
                WrapStack(getList("list")) { listItem in
                    ForEach(0..<self.from.children.count){ index in
                        GUIElementInstance(self.from.children[index], listItem)
                    }
                }
                .animation(nil)
                .setProperties(from._properties, self.item)
            }
            else if from.type == "text" {
                Text(from.processText(get("text") ?? "[nil]"))
                    .if(from.getBool("bold")){ $0.bold() }
                    .if(from.getBool("italic")){ $0.italic() }
                    .if(from.getBool("underline")){ $0.underline() }
                    .if(from.getBool("strikethrough")){ $0.strikethrough() }
                    .fixedSize(horizontal: false, vertical: true)
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "textfield" {
                self.renderTextfield()
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "itemcell" {
                // TODO Refactor fix this
//                ItemCell(
//                    item: self.item,
//                    rendererNames: get("rendererNames") as [String],
//                    variables: [] // get("variables") // TODO Refactor fix this
//                )
//                .environmentObject(self.main)
//                .setProperties(from._properties, self.item)
            }
            else if from.type == "subview" {
                if has("viewName") {
                    SubView(
                        main: self.main,
                        viewName: from.getString("viewName"),
                        context: self.item,
                        variables: get("variables") ?? [:] // TODO Refactor: Error Handling
                    )
                    .setProperties(from._properties, self.item)
                }
                else {
                    SubView(
                        main: self.main,
                        view: { let x:SessionView = get("view")!; return x }(),
                        context: self.item,
                        variables: get("variables") ?? [:]
                    )
                    .setProperties(from._properties, self.item)
                }
            }
            else if from.type == "map" {
                MapView(address: get("address"))
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "picker" {
                self.renderPicker()
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "securefield" {
            }
            else if from.type == "action" {
                Action(action: get("press"))
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "memributton" {
                MemriButton(item: self.item)
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "image" {
                if has("systemname") {
                    Image(systemName: get("systemname") ?? "exclamationmark.bubble")
                        .if(from.has("resizable")) { self.resize($0) }
                        .setProperties(from._properties, self.item)
                }
                else { // assuming image property
                    Image(uiImage: getImage("image"))
                        .if(from.has("resizable")) { self.resize($0) }
                        .setProperties(from._properties, self.item)
                }
            }
            else if from.type == "circle" {
            }
            else if from.type == "horizontalline" {
                HorizontalLine()
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "rectangle" {
                Rectangle()
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "roundedrectangle" {
                RoundedRectangle(cornerRadius: get("cornerradius") ?? 5)
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "spacer" {
                Spacer()
                    .setProperties(from._properties, self.item)
            }
            else if from.type == "divider" {
                Divider()
                    .setProperties(from._properties, self.item)
            }
        }
    }
    
//    @ViewBuilder // This crashes the build when Group is gone
    // TODO add this for multiline editing: https://github.com/kenmueller/TextView
    func renderTextfield() -> some View {
        let (type, propName) = from.getType("value", self.item)
        
        return Group {
            if type != PropertyType.string {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), value: Binding<Any>(
                    get: { self.item[propName] as Any},
                    set: { self.item.set(propName, $0) }
                ), formatter: type == .date ? DateFormatter() : NumberFormatter()) // TODO Refactor: expand to properly support all types
                .keyboardType(.decimalPad)
                .generalEditorInput()
            }
            else {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), text: Binding<String>(
                    get: { self.item.getString(propName) },
                    set: { self.item.set(propName, $0) }
                ))
                .generalEditorInput()
            }
        }
    }
    
    func renderPicker() -> some View {
        let dataItem:DataItem? = self.get("value")
        let (_, propName) = from.getType("value", self.item)
        let queryOptions:[String:Any] = self.get("queryoptions")! // TODO refactor error handling
        let emptyValue = self.get("empty") ?? "Pick a value"
        
        return Picker(
            item: self.item,
            selected: dataItem ?? self.get("default"),
            title: "Select a \(emptyValue)",
            emptyValue: emptyValue,
            propName: propName,
            queryOptions: QueryOptions(value: [
                "query": queryOptions["query"],
                "sortProperty": queryOptions["sortProperty"],
                "sortAscending": queryOptions["sortAscending"]
            ])
        )
    }
    
    @ViewBuilder
    var renderChildren: some View {
        ForEach(0..<from.children.count){ index in
            GUIElementInstance(self.from.children[index], self.item, self.variables)
        }
    }
    
}
