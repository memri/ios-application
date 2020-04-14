
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
    "order": ["color", "font", "rowinset", "padding", "background", "rowbackground", "border", "shadow", "offset"]
]

extension View {
    func setProperties(_ properties:[String:Any], _ item:DataItem) -> AnyView {
        var view:AnyView = AnyView(self)
        var setFrame = false
        
        for item in ViewConfig["frame"]! {
            if properties[item] != nil {
                setFrame = true
                break
            }
        }
        
        if setFrame { view = view.setProperty("frame", properties) }
        
        for name in ViewConfig["order"]! {
            if var value = properties[name] {
                
                // Compile string properties
                if let compiled = value as? GUIElementDescription.CompiledProperty {
                    value = GUIElementDescription.computeProperty(compiled, item)
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
        case "frame":
            if let value = value as? [String:Any] {
                
                return AnyView(self.frame(
                    minWidth: value["minwidth"] as? CGFloat ?? .none,
                    maxWidth: value["maxwidth"] as? CGFloat ?? .greatestFiniteMagnitude,
                    minHeight: value["minheight"] as? CGFloat ?? .none,
                    maxHeight: value["maxheight"] as? CGFloat ?? .greatestFiniteMagnitude,
                    alignment: value["align"] as? Alignment ?? .top))
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
        case "minwidth", "minheight", "align", "maxwidth", "maxheight", "spacing", "alignment", "text", "maxchar", "removewhitespace", "bold":
            break
        default:
            print("NOT IMPLEMENTED PROPERTY: \(name)")
        }
        
        return AnyView(self)
    }
    
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}

extension Text {
    func `if`(_ conditional: Bool, content: (Self) -> Text) -> Text {
        if conditional {
            return content(self)
        } else {
            return self
        }
    }
}

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
                case "ultraLight": value[1] = Font.Weight.ultraLight
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
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]*\.[^\}]*)\})?)"#
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
                    
                    var searchPath:[String] = expr[rangeQuery]
                        .split(separator: ".")
                        .map{ String($0) }
                    
                    if searchPath[0] == "dataItem" {
                        searchPath.remove(at: 0)
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
    
    public func getBool(_ propName:String) -> Bool {
        return get(propName) ?? false
    }
    
    public func get<T>(_ propName:String, _ item:DataItem? = nil) -> T? {
        if let prop = properties[propName] {
            let propValue = prop
            
            // Compile string properties
            if let compiled = propValue as? CompiledProperty {
                return (GUIElementDescription.computeProperty(compiled, item) as! T)
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
    
    private class func traverseProperties(_ item:DataItem, _ propParts:[String]) -> String {
        // Loop through the properties and fetch each
        var value:Any? = item
        for i in 0..<propParts.count {
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
        if let date = value as? Date? { value = formatDate(date) }
            
        // Execute a custom function
        else if let f = value as? ([Any]?) -> String { value = f([]) }
        
        // Return the value as a string
        return value as? String ?? ""
    }
    
    public class func computeProperty(_ compiled:CompiledProperty, _ item:DataItem?) -> String {
        return compiled.result.map {
            if let s = $0 as? [String] { return traverseProperties(item!, s) }
            return $0 as! String
        }.joined()
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
    
    var from:GUIElementDescription
    var item:DataItem
    
    public init(_ gui:GUIElementDescription, _ dataItem:DataItem) {
        from = gui
        item = dataItem
    }
    
    public func has(_ propName:String) -> Bool {
        return from.has(propName)
    }
    
    public func get<T>(_ propName:String) -> T? {
        return from.get(propName, self.item)
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
    
    // TODO can this be optimized for performance??
    // What about setting .setProperties on result of another property access
    // and make two different ones based on whether it has children
    @ViewBuilder
    public var body: some View {
        if from.type == "vstack" {
            VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                self.childrenAsView
            }
            .setProperties(from.properties, self.item)
        }
        else if from.type == "hstack" {
            HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                self.childrenAsView
            }
            .setProperties(from.properties, self.item)
        }
        else if from.type == "zstack" {
            ZStack(alignment: get("alignment") ?? .top) { self.childrenAsView }
                .setProperties(from.properties, self.item)
        }
        else if from.type == "button" {
            Button(action: { self.main.executeAction(self.get("press")!, self.item) }) {
                self.childrenAsView
            }
            .setProperties(from.properties, self.item)
        }
        else if from.type == "text" {
            Text(from.processText(get("text") ?? "[nil]"))
                .if(from.has("bold")){ $0.bold() }
                .if(from.has("italic")){ $0.italic() }
                .if(from.has("underline")){ $0.underline() }
                .if(from.has("strikethrough")){ $0.strikethrough() }
                .multilineTextAlignment(.leading)
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
            if has("systemName") {
                Image(systemName: get("systemName") ?? "exclamationmark.bubble")
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .setProperties(from.properties, self.item)
            }
            else { // assuming image property
                Image(uiImage: get("image") ?? UIImage())
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
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
//        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var childrenAsView: some View {
        ForEach(0..<from.children.count){ index in
            GUIElementInstance(self.from.children[index], self.item)
        }
    }
    
}
