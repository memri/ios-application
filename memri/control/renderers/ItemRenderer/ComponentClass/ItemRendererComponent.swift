//
//  ComponentClass.swift
//  memri
//
//  Created by Koen van der Veen on 09/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

enum ComponentFamily: String, ClassFamily {
    case VStack = "VStack"
    case Text = "Text"

    static var discriminator: Discriminator = .type

    func getType() -> AnyObject.Type {
        switch self {
        case .VStack:
            return VStackComponentClass.self
        case .Text:
            return TextComponentClass.self
        }
    }
}

class ItemRendererComponent: Decodable{
    
    var element: ItemRendererComponent? = nil
    
    enum ComponentClassCodingKeys: String, CodingKey {
      case type
      case element
      case children
    }
    
    func asView(item: DataItem)-> AnyView {
        return self.element!.asView(item: item)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        jsonErrorHandling(decoder) {
            let container = try decoder.container(keyedBy: ComponentClassCodingKeys.self)

            
            switch try container.decode(String.self, forKey: .type) {
            case "vstack":
                self.element = VStackComponentClass(children: try container.decode([ItemRendererComponent].self,
                                                                        forKey: .children))
            case "text":
                self.element = try TextComponentClass(from: decoder)
            default: fatalError("Unknown type")
            }
        }
    }
    
    public static func fromJSONFile(_ file: String, ext: String = "json") throws -> ItemRendererComponent {
        let jsonData = try jsonDataFromFile(file, ext)
        let comp: ItemRendererComponent = try! JSONDecoder().decode(ItemRendererComponent.self, from: jsonData)
        return comp
    }
    
}

