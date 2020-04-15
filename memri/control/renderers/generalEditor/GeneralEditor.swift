//
//  generalEditor.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class GeneralRenderer: Renderer{
    required init(){
        super.init()
        self.name = "generalRenderer"
        self.icon = "pencil.circle.fill"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return items.count == 1
    }
}


class GeneralRendererConfig: RenderConfig{
    
    
    
    
//    override var renderDescription: [String:GUIElementDescription]? {
//        if let itemRenderer = renderCache.get(self._renderDescription!) {
//            return itemRenderer
//        }
//        else if let description = self._renderDescription {
////            try JSONDecoder().decode(family: DataItemFamily.self, from: data)
//            
//            if let itemRenderer:[String:GUIElementDescription] = unserialize(description) {
//                renderCache.set(description, itemRenderer)
//                return itemRenderer
//            }
//        }
//        
//        return nil
//    }
}
