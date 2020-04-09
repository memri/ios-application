//
//  Component.swift
//  memri
//
//  Created by Koen van der Veen on 08/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

enum Component: Decodable {
    case vstack(VStackComponent)
    case text(TextComponent)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case element
        case children
    }
    
    init(){
        self = .text(TextComponent(content: ""))
    }

    init(from decoder: Decoder) throws {
        self.init()
        jsonErrorHandling(decoder) {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            switch try container.decode(String.self, forKey: .type) {
            case Unassociated.vstack.rawValue:
                self = .vstack(VStackComponent(children: try container.decode([Component].self,
                                               forKey: .children)))
            case Unassociated.text.rawValue:
                self = .text(try TextComponent(from: decoder))
            default: fatalError("Unknown type")
            }
        }
    }
    
    func setItem(item: DataItem){
//        switch self{
//        case .vstack(let component):
//            component.setItem(item)
//            self = .vstack(component)
//        case .text(let component):
//            component.setItem(item)
//            self = .vstack(component)
//            return AnyView(component)
//        }
    }
    
    enum Unassociated: String {
        case vstack
        case text
    }
    
    
    func asView() -> AnyView{
        switch self{
        case .vstack(let component):
            return AnyView(component)
        case .text(let component):
            return AnyView(component)
        }
    }
}
