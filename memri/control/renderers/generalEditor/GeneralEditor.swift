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
