//
//  ItemRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 08/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI




struct ItemRenderer: View, Decodable {
    var baseComponent: ComponentClass? = nil
    
//    @ObservedObject var item: DataItem = DataItem()

    
    var body: some View {
        Group{
            if baseComponent != nil{
                baseComponent!.asView()
            }else{
                EmptyView()
            }
        }
    }
    
    enum RendererConfigKeys: String, CodingKey {
        case parentView
    }
    
//    func setItem(item: DataItem){
//        if let component = baseComponent{
//            self.item = item
//            component.setItem(item: item)
//        }
//    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RendererConfigKeys.self)
        baseComponent = try container.decode(ComponentClass.self, forKey: .parentView)
    }
    
    
    public static func fromJSONFile(_ file: String, ext: String = "json") throws -> ItemRenderer {
        let jsonData = try jsonDataFromFile(file, ext)
        let rend: ItemRenderer = try! JSONDecoder().decode(ItemRenderer.self, from: jsonData)
        return rend
    }
    
}
//
struct ItemRenderer_Previews: PreviewProvider {
    static var previews: some View {
        try! ItemRenderer.fromJSONFile("itemcomponent")
    }
}
