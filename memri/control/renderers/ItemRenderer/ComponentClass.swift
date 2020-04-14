
//
//  ComponentClasses.swift
//  memri
//
//  Created by Koen van der Veen on 09/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

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
                    ForEach(0..<self.children.count ){ index in
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
