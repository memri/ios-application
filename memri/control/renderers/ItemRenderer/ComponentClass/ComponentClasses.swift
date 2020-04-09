//
//  ComponentClasses.swift
//  memri
//
//  Created by Koen van der Veen on 09/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class VStackComponentClass: ComponentClass{
    var children: [ComponentClass] = []
    
    convenience init(children: [ComponentClass]? = nil){
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

extension View {
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}
    
    
class TextComponentClass: ComponentClass{
    
    var property: String = ""
    var bold: Bool = false
    var removeWhiteSpace = false
    var maxChar = -1
    
    private enum CodingKeys: String, CodingKey {
        case property, bold, removeWhiteSpace
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        self.property = try decoder.decodeIfPresent("property") ?? self.property
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

    
    override func asView(item: DataItem)-> AnyView {
        return AnyView(
            Text(processText(text: item.getString(property)))
                .if(bold){
                      $0.bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)


        )
    }
    
}
