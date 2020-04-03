//
//  ListRendererObject.swift
//  memri
//
//  Created by Koen van der Veen on 01/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class RendererObject: ActionDescription, ObservableObject{
    @objc dynamic var name = ""
    @objc dynamic var renderConfig: RenderConfig? = RenderConfig()
    
    func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
    
    required init(){
        super.init()
        self.hasState = true
        self.actionName = .setRenderer
        self.activeBackgroundColor = Color(white: 0.95).uiColor()
        self.actionName = .setRenderer
    }
    
    func candisplayresultset(items: [DataItem]) -> Bool{
        return true
    }

}

class ListRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "list"
        self.icon = "line.horizontal.3"
        self.renderConfig = ListConfig()
    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
        // checks if everything can be casted to note
        return items.count == items.compactMap({$0 as? Note}).count
    }
}

class ThumbnailRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "thumbnail"
        self.icon = "square.grid.3x2.fill"
        self.renderConfig = ThumbnailConfig()

    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
        // checks if everything can be casted to note
        return items.count == items.compactMap({$0 as? Note}).count
    }
}
class RichTextRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "richTextEditor"
        self.icon = "pencil"
    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
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

class CalendarRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "calendar"
        self.icon = "calendar"
    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
        return false
    }
}

class MapRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "map"
        self.icon = "location.fill"
    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
        return false
    }
}

class graphRendererObject: RendererObject{
    required init(){
        super.init()
        self.name = "graph"
        self.icon = "chart.bar.fill"
    }
    override func candisplayresultset(items: [DataItem]) -> Bool{
        return false
    }
}




