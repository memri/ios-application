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

class ComponentClass: Decodable{
    
    var element: ComponentClass? = nil
    
    enum ComponentClassCodingKeys: String, CodingKey {
      case type
      case element
      case children
    }
    
    func asView()-> AnyView {
        return self.element!.asView()
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        jsonErrorHandling(decoder) {
            let container = try decoder.container(keyedBy: ComponentClassCodingKeys.self)

            
            switch try container.decode(String.self, forKey: .type) {
            case "vstack":
                self.element = VStackComponentClass(children: try container.decode([ComponentClass].self,
                                                                        forKey: .children))
            case "text":
                self.element = try TextComponentClass(from: decoder)
            default: fatalError("Unknown type")
            }
        }
    }
    
}

