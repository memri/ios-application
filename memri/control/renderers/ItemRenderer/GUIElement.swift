
//
//  ComponentClasses.swift
//  memri
//
//  Created by Koen van der Veen on 09/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

extension View {
    func setProperties(_ properties:[String:Any]) -> AnyView {
        var view:AnyView = AnyView(self)
        for (name, value) in properties {
            view = view.setProperty(name, value)
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
        case "font":
            if let value = value as? [Any] {
                var font:Font
                if let name = value[0] as? String {
                    font = .custom(name, size: value[1] as! CGFloat)
                }
                else {
                    let weight = value[1] as! String
                    font = .system(size: value[0] as! CGFloat,
                       weight: weight == "regular" ? .regular : .bold, design: .default)
                }
                return AnyView(self.font(font))
            }
        default:
            print("NOT IMPLEMENTED PROPERTY: \(name)")
        }
        
        return AnyView(self)
    }

   // Example: .if(bold){ $0.bold() }
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
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
            properties[key] = parseProperty(value.value)
        }
    }
    
    func parseProperty(_ value:Any) -> Any? {
        if let value = value as? String {
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
                value[i] = parseProperty(value[i])!
            }
            return value
        }
        
        return nil
    }
    
    struct CompiledProperty {
        var result: [Any]
    }
    
    func compile(_ expr: String) -> Any {
        // We'll use this regular expression to match the name of the object and property
        let pattern = #"(?:([^\{]+)?(?:\{([^\.]*.[^\}]*)\})?)"#
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
                return (compiled.result.map {
                    if let s = $0 as? [String] { return traverseProperties(item!, s) }
                    return $0 as! String
                }.joined() as! T)
            }
            
            return (propValue as! T)
        }
        return nil
    }
    
    private func traverseProperties(_ item:DataItem, _ propParts:[String]) -> String {
        // Loop through the properties and fetch each
        var value:Any? = item
        for i in 0..<propParts.count {
            value = (value as! Object)[String(propParts[i])]
        }
        
        // Return the value as a string
        return value as? String ?? ""
    }
    
    public static func fromJSONFile(_ file: String, ext: String = "json") throws -> GUIElementDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let comp: GUIElementDescription = try! JSONDecoder().decode(GUIElementDescription.self, from: jsonData)
        return comp
    }
}

// All functions
extension GUIElementDescription {
    
    func processText(_ text: String) -> String{
        var outText = text
        let maxChar:CGFloat? = get("maxChar")
        
        outText = get("removeWhiteSpace") ?? false ? removeWhiteSpace(text: text) : text
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
    
    // TODO can this be optimized for performance??
    // What about setting .setProperties on result of another property access
    // and make two different ones based on whether it has children
    @ViewBuilder
    public var body: some View {
        if from.type == "vstack" {
            VStack(alignment: .leading, spacing: get("spacing") ?? 0) { self.childrenAsView }
                .setProperties(from.properties)
        }
        else if from.type == "hstack" {
            HStack(alignment: .top, spacing: get("spacing") ?? 0) { self.childrenAsView }
                .setProperties(from.properties)
        }
        else if from.type == "zstack" {
            ZStack(alignment: .top) { self.childrenAsView }
                .setProperties(from.properties)
        }
        else if from.type == "button" {
            Button(action: { self.main.executeAction(self.get("press")!, self.item) }) {
                self.childrenAsView
            }
            .setProperties(from.properties)
        }
        if from.type == "text" {
            Text(from.processText(get("text") ?? "[nil]"))
                .setProperties(from.properties)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        else if from.type == "textfield" {
        }
        else if from.type == "securefield" {
        }
        else if from.type == "action" {
            Action(action: get("press"))
//            .font(Font.system(size: 19, weight: .semibold))
        }
        else if from.type == "image" {
            if has("systemName") {
                Image(systemName: get("systemName") ?? "exclamationmark.bubble")
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .setProperties(from.properties)
            }
            else { // assuming image property
                Image(uiImage: get("image") ?? UIImage())
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .setProperties(from.properties)
            }
        }
        else if from.type == "textfield" {
        }
        else if from.type == "circle" {
        }
        else if from.type == "rectangle" {
            Rectangle()
                .setProperties(from.properties)
        }
        else if from.type == "roundedrectangle" {
            RoundedRectangle(cornerRadius: get("cornerRadius") ?? 5)
                .setProperties(from.properties)
        }
        else if from.type == "spacer" {
            Spacer()
        }
        else if from.type == "divider" {
            Divider()
        }
    }
    
    @ViewBuilder
    var childrenAsView: some View {
        ForEach(0..<from.children.count){ index in
            GUIElementInstance(self.from.children[index], self.item)
        }
    }
    
}
