//
//  ListRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 01/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class CalendarRenderer: Renderer{
    required init(){
        super.init()
        self.name = "calendar"
        self.icon = "calendar"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return false
    }
}

class MapRenderer: Renderer{
    required init(){
        super.init()
        self.name = "map"
        self.icon = "location.fill"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return false
    }
}

class graphRenderer: Renderer{
    required init(){
        super.init()
        self.name = "graph"
        self.icon = "chart.bar.fill"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return false
    }
}




