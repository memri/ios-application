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
    
    override func asView()-> AnyView {
        return AnyView(
                VStack{
                ForEach(0..<self.children.count ){ index in
                    self.children[index].asView()
                }
            }
        )
    }
}
    
    
class TextComponentClass: ComponentClass{
    
    var content: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case content
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
    }
    
    override func asView()-> AnyView {
        return AnyView(
            Text(content)
        )
    }
    
}
