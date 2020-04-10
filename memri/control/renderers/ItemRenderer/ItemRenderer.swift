//
//  ItemRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 08/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ItemRenderer: View, Decodable {
    var baseComponent: ItemRendererComponent? = nil
    
    @ObservedObject var item: DataItem = Note(value: ["content": "test",
                                                      "title": "test"])
    var body: some View {
        Group{
            if baseComponent != nil{
                baseComponent!.asView(item: item)
            }else{
                EmptyView()
            }
        }
    }
    
    enum RendererConfigKeys: String, CodingKey {
        case parentView
    }
    
    init(baseComponent: ItemRendererComponent?=nil, item:DataItem?=nil){
        self.baseComponent = baseComponent ?? self.baseComponent
        self.item = item ?? self.item
        
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: RendererConfigKeys.self)
        baseComponent = try container.decode(ItemRendererComponent.self, forKey: .parentView)
    }

}

struct ItemRenderer_Previews: PreviewProvider {
    static var previews: some View {
        try! ItemRenderer(baseComponent: try! ItemRendererComponent.fromJSONFile("list_item_component"),
                          item: Note(value: ["title": "Some note",
                                             "content": "- content\n -content \n- content"]))
    }
}
