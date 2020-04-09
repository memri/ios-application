//
//  Components.swift
//  memri
//
//  Created by Koen van der Veen on 08/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct VStackComponent: View, Decodable {

    var children: [Component] = []
    
    var body: some View{
        VStack{
            EmptyView()
            ForEach(0..<self.children.count ){ index in
                self.children[index].asView()
            }
        }
    }
    
//    var x: VStack<AnyView>{
//        return VStack{
//            y()
//        }
//    }
//    
//    func y() -> AnyView{
//        return AnyView(Text("ABC"))
//    }
    
    private enum CodingKeys: String, CodingKey {
        case children
    }
    
    init(children: [Component]? = nil){
        self.children = children ?? self.children
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        children = try container.decode([Component].self, forKey: .children)
    }
    
}

struct TextComponent: View, Decodable{

    var content: String = ""
    var body: some View{
            Text(content)
    }
    private enum CodingKeys: String, CodingKey {
        case content
    }
    
    init(content: String?){
        self.content = content ?? self.content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
    }
    
}
