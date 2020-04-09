//
//  RichTextConfig.swift
//  memri
//
//  Created by Ruben Daniels on 4/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class RichTextRenderer: Renderer{
    required init(){
        super.init()
        self.name = "richTextEditor"
        self.icon = "pencil"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        if items.count>0{
            if items.count == 1 && items[0] is Note{
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
}
