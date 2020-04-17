
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
    "order": ["frame", "color", "font", "rowinset", "padding", "background", "textalign",
              "rowbackground", "cornerradius", "cornerborder", "border", "shadow", "offset"]
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
        case "rowinset":
            if let value = value as? [CGFloat] {
                return AnyView(self.listRowInsets(EdgeInsets(
                    top: value[0],
                    leading: value[3],
                    bottom: value[2],
                    trailing: value[1])))
            }
            else if let value = value as? CGFloat {
                return AnyView(self.listRowInsets(EdgeInsets(top: value,
                            leading: value, bottom: value, trailing: value)))
            }
        case "offset":
            if let value = value as? [CGFloat] {
                return AnyView(self.offset(x: value[0], y: value[1]))
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

public class GUIElementDescription: Decodable {
    var type: String = ""
    var properties: [String: Any] = [:]
    var children: [GUIElementDescription] = []
    
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            children = try decoder.decodeIfPresent("children") ?? children
            
            if let props:[String:AnyCodable] = try decoder.decodeIfPresent("properties") {
                parseProperties(props)
            }
        }
    }
    
    func parseProperties(_ props:[String:AnyCodable]){
        for (key, value) in props {
            properties[key.lowercased()] = parseProperty(key, value.value)
        }
        
        for item in ViewConfig["frame"]! {
            if properties[item] != nil {
                
                let values:[Any?] = [
                    properties["minwidth"] as Any?,
                    properties["maxwidth"] as Any?,
                    properties["minheight"] as Any?,
                    properties["maxheight"] as Any?,
                    properties["align"] as Any?
                ]
                
                properties["minwidth"] = nil
                properties["maxwidth"] = nil
                properties["minheight"] = nil
                properties["maxheight"] = nil
                properties["align"] = nil
                
                properties["frame"] = values
                break
            }
        }
        
        if properties["cornerradius"] != nil && properties["border"] != nil {
            var value = properties["border"] as! [Any]
            value.append(properties["cornerradius"]!)
            
            properties["cornerborder"] = value as Any
            properties["border"] = nil
        }
    }
    
    func parseProperty(_ key:String, _ value:Any) -> Any? {
        if key == "alignment" {
            switch value as! String {
            case "left": return HorizontalAlignment.leading
            case "top": return VerticalAlignment.top
            case "right": return HorizontalAlignment.trailing
            case "bottom": return VerticalAlignment.bottom
            case "center": return self.type == "vstack"
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
//                    let str = String(expr[rangeQuery])
//                    if str.test("^[^\\.]$") {
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
        return properties[propName] != nil
    }
    
    public func getString(_ propName:String, _ item:DataItem? = nil) -> String {
        return get(propName, item) ?? ""
    }
    
    public func getBool(_ propName:String, _ item:DataItem? = nil) -> Bool {
        return get(propName, item) ?? false
    }
    
    public func get<T>(_ propName:String, _ item:DataItem? = nil,
                       _ options:[String:Any]=[:]) -> T? {
        
        if let prop = properties[propName] {
            let propValue = prop
            
            // Compile string properties
            if let compiled = propValue as? CompiledProperty {
                let x:T? = GUIElementDescription.computeProperty(compiled, item, options)
                return x
            }
            
            return (propValue as! T)
        }
        return nil
    }
    
    private class func formatDate(_ date:Date?) -> String{
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
    
    private class func traverseProperties<T>(_ item:DataItem, _ propParts:[String],
                                             _ options:[String:Any]=[:]) -> T? {
        // Loop through the properties and fetch each
        var value:Any? = nil
        /*
            NOTE: If there is ever a desire to query other objects such as currentSession
                  or computedView, then this is the place to add that.
         */
        
        let isNegationTest = propParts.first?.first == "!"
        let firstItem = isNegationTest
            ? propParts[0].substr(1)
            : propParts[0]
        
        if firstItem == "dataItem" {
            value = item
        }
        else {
            value = isNegationTest
                ? !(options[firstItem.lowercased()] as! Bool)
                : options[firstItem.lowercased()]
        }
            
        for i in 1..<propParts.count {
            let part = propParts[i]
            
            if part == "functions" {
                value = (value as! DataItem).functions[propParts[i+1]];
                break
            }
            else {
                value = (value as! Object)[String(part)]
            }
        }
        
        // Format a date
        if let date = value as? Date { value = formatDate(date) }
            
        // Get the image uri from a file
        else if let file = value as? File {
            // Preload the image
            let _ = file.asUIImage
            
            // Set the uri string as the value
            value = file.uri
        }
            
        // Execute a custom function
        else if let f = value as? ([Any]?) -> String { value = f([]) }
        
        // Return the value as a string
        return value as? T
    }
    
    public class func computeProperty<T>(_ compiled:CompiledProperty, _ item:DataItem?,
                                         _ options:[String:Any]=[:]) -> T? {
        
        // If this is a single lookup e.g. {.myBoolean} then lets return the actual
        // type rather than a string
        if compiled.result.count == 1 && (compiled.result.first as! [Any]).count == 1 {
            // TODO Error Handling
            let x:T? = traverseProperties(item!, compiled.result.first as! [String], options)
            return x
        }
        else {
            return (compiled.result.map {
                if let s = $0 as? [String] { return traverseProperties(item!, s, options) ?? ""}
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
    let options:[String:Any]
    
    public init(_ gui:GUIElementDescription, _ dataItem:DataItem, _ opts:[String:Any]=[:]) {
        from = gui
        item = dataItem
        options = opts
    }
    
    public func has(_ propName:String) -> Bool {
        return options[propName] != nil || from.has(propName)
    }
    
    public func get<T>(_ propName:String) -> T? {
        if propName.first == "$" {
            dump(options)
            print(options[propName.substr(1)] as! Bool)
            return (options[propName.substr(1)] as! T)
        }
        else {
            return from.get(propName, self.item, options)
        }
    }
    
    public func getList<T:RealmCollectionValue>(_ propName:String) -> [T] {
        let x:RealmSwift.List<T> = get("list")!
        var result:[T] = []
    
        for n in x {
            result.append(n)
        }
        
        return result
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
    
//    @ViewBuilder
    public var body: some View {
        VStack {
        if (!has("condition") || get("condition") == true) {
            if from.type == "vstack" {
                VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                    self.childrenAsView
                }
                .animation(nil)
                .setProperties(from.properties, self.item)
            }
            else if from.type == "hstack" {
                HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                    self.childrenAsView
                }
                .animation(nil)
                .setProperties(from.properties, self.item)
            }
            else if from.type == "zstack" {
                ZStack(alignment: get("alignment") ?? .top) { self.childrenAsView }
                    .animation(nil)
                    .setProperties(from.properties, self.item)
            }
            if from.type == "editorsection" {
                if self.has("title") {
                    Section(header: Text(LocalizedStringKey(
                        (self.get("title") ?? "").uppercased()
                    )).generalEditorHeader()){
                        Divider()
                        self.childrenAsView
                        Divider()
                    }
                    .animation(nil)
                    .setProperties(from.properties, self.item)
                }
                else {
                    VStack(spacing: 0){
                        self.childrenAsView
                    }
                    .animation(nil)
                    .setProperties(from.properties, self.item)
                }
            }
            if from.type == "editorrow" {
                VStack (spacing: 0) {
                    VStack(alignment: .leading, spacing: 4){
                        Text(LocalizedStringKey(self.get("title") ?? ""
                            .camelCaseToWords()
                            .lowercased()
                            .capitalizingFirstLetter())
                        )
                        .generalEditorLabel()
                        
                        self.childrenAsView
                            .generalEditorCaption()
                    }
                    .fullWidth()
                    .padding(.bottom, 10)
                    .padding(.horizontal, 36)
                    .background(self.get("$readonly") ?? false
                        ? Color(hex:"#f9f9f9")
                        : Color(hex:"#f7fcf5"))
                    .animation(nil)
                    .setProperties(from.properties, self.item)
                    
                    Divider().padding(.leading, 35)
                }

            }
            else if from.type == "button" {
                Button(action: { self.main.executeAction(self.get("press")!, self.item) }) {
                    self.childrenAsView
                }
                .setProperties(from.properties, self.item)
            }
            else if from.type == "wrapstack" {
                WrapStack(getList("list")) { listItem in
                    ForEach(0..<self.from.children.count){ index in
                        GUIElementInstance(self.from.children[index], listItem)
                    }
                }
                .animation(nil)
                .setProperties(from.properties, self.item)
            }
            else if from.type == "text" {
                Text(from.processText(get("text") ?? "[nil]"))
                    .if(from.getBool("bold")){ $0.bold() }
                    .if(from.getBool("italic")){ $0.italic() }
                    .if(from.getBool("underline")){ $0.underline() }
                    .if(from.getBool("strikethrough")){ $0.strikethrough() }
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "textfield" {
            }
            else if from.type == "securefield" {
            }
            else if from.type == "action" {
                Action(action: get("press"))
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "image" {
                if has("systemname") {
                    Image(systemName: get("systemname") ?? "exclamationmark.bubble")
                        .if(from.has("resizable")) { self.resize($0) }
                        .setProperties(from.properties, self.item)
                }
                else { // assuming image property
                    Image(uiImage: try! fileCache.read(from.getString("image", self.item)) ?? UIImage())
                        .if(from.has("resizable")) { self.resize($0) }
                        .setProperties(from.properties, self.item)
                }
            }
            else if from.type == "circle" {
            }
            else if from.type == "horizontalline" {
                HorizontalLine()
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "rectangle" {
                Rectangle()
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "roundedrectangle" {
                RoundedRectangle(cornerRadius: get("cornerradius") ?? 5)
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "spacer" {
                Spacer()
                    .setProperties(from.properties, self.item)
            }
            else if from.type == "divider" {
                Divider()
                    .setProperties(from.properties, self.item)
            }
        }
        }
    }
    
    @ViewBuilder
    var childrenAsView: some View {
        ForEach(0..<from.children.count){ index in
            GUIElementInstance(self.from.children[index], self.item, self.options)
        }
    }
    
}
