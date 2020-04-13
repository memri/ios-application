
//
//  ComponentClasses.swift
//  memri
//
//  Created by Koen van der Veen on 09/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    func setProperties(_ properties:[String:AnyCodable]) -> some View {
        self.frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0, maxHeight: .infinity,
                   alignment: Alignment.topLeading)
    }
}

public class GUIElementDescription: Decodable {
    var type: String = ""
    var properties: [String: AnyCodable] = [:]
    var children: [GUIElementDescription] = []
    
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            children = try decoder.decodeIfPresent("children") ?? children
            properties = try decoder.decodeIfPresent("properties") ?? properties
        }
    }
    
    func processText(_ text: String) -> String{
        var outText = text
//        outText = removeWhiteSpace ? removeWhiteSpace(text: text) : text
//        outText = maxChar != -1 ? String(outText.prefix(maxChar)) : outText
        return outText
    }
    
    public func has(_ propName:String) -> Bool {
        return properties[propName] != nil
    }
    
    public func get<T>(_ propName:String, _ item:DataItem) -> T? {
        if let propValue = properties[propName] {
            return (propValue.value as! T)
        }
        return nil
    }
    
    public static func fromJSONFile(_ file: String, ext: String = "json") throws -> GUIElementDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let comp: GUIElementDescription = try! JSONDecoder().decode(GUIElementDescription.self, from: jsonData)
        return comp
    }
    
//     .init(rawValue: get("alignment") ?? "left")
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
            Text(from.processText(get("text") ?? ""))
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
    }
    
    @ViewBuilder
    var childrenAsView: some View {
        ForEach(0..<from.children.count){ index in
            GUIElementInstance(self.from.children[index], self.item)
        }
    }
    
}


class VStackComponent: ItemRendererComponent{
    var children: [ItemRendererComponent] = []
    
    convenience init(children: [ItemRendererComponent]? = nil){
        self.init()
        self.children = children ?? self.children
    }
    
    private enum CodingKeys: String, CodingKey {
        case content
    }
    
    override func asView(item: DataItem)-> AnyView {
        return AnyView(
                VStack{
                    ForEach(0..<self.children.count ){ index in
                        self.children[index].asView(item: item)
                    }
                }
            )
    }
}

class HStackComponent: ItemRendererComponent{
    var children: [ItemRendererComponent] = []
    
    convenience init(children: [ItemRendererComponent]? = nil){
        self.init()
        self.children = children ?? self.children
    }
    
    private enum CodingKeys: String, CodingKey {
        case content
    }
    
    override func asView(item: DataItem)-> AnyView {
        return AnyView(
                HStack{
                    ForEach(0..<self.children.count){ index in
                        self.children[index].asView(item: item)
                    }
                }
            )
    }
}

extension View {
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}
        
class TextComponent: ItemRendererComponent{
    var value: String = ""
    var bold: Bool = false
    var removeWhiteSpace = false
    var maxChar = -1
    
    private enum CodingKeys: String, CodingKey {
        case property, bold, removeWhiteSpace
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        self.value = try decoder.decodeIfPresent("value") ?? self.value
        self.bold = try decoder.decodeIfPresent("bold") ?? self.bold
        self.removeWhiteSpace = try decoder.decodeIfPresent("removeWhiteSpace") ?? self.removeWhiteSpace
    }
    
    func removeWhiteSpace(text: String) -> String{
        return text.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
    }
    
    func processText(text: String) -> String{
        var outText = text
        outText = removeWhiteSpace ? removeWhiteSpace(text: text) : text
        outText = maxChar != -1 ? String(outText.prefix(maxChar)) : outText
        return outText
    }
    
    func getValue(_ item: DataItem) -> String{
        return item.getString(value) // TODO parse using the logic from compiledView
    }
    
    override func asView(item: DataItem) -> AnyView {
        return AnyView(
            Text(processText(text: self.getValue(item)))
                .if(bold){
                      $0.bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        )
    }
}

class RoundedRectangleComponent: ItemRendererComponent{
    var cornerRadius: CGFloat = 5
    var background: Color = Color.white
    
    private enum CodingKeys: String, CodingKey {
        case cornerRadius, background
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        self.cornerRadius = try decoder.decodeIfPresent("cornerRadius") ?? self.cornerRadius
        
        if let bg:String = try decoder.decodeIfPresent("background") {
            self.background = Color(hex: bg)
        }
    }
    
    func removeWhiteSpace(text: String) -> String{
        return text.replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
    }
    
    func getValue(_ item: DataItem) -> String{
        return ""
    }
    
    override func asView(item: DataItem) -> AnyView {
        return AnyView(
            RoundedRectangle(cornerRadius: cornerRadius)
                
//                .frame(maxWidth: .infinity, alignment: .leading)
        )
    }
}

class SpacerComponent: ItemRendererComponent{
    required convenience init(from decoder: Decoder) throws {
        self.init()
    }
    
    override func asView(item: DataItem) -> AnyView {
        return AnyView(
            Spacer()
        )
    }
}
