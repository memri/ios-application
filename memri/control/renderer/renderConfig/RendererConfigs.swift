//
//  RenderConfigs.swift
//  memri
//
//  Created by Koen van der Veen on 02/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class RenderConfig: Object, Codable {
    /**
     *
     */
    @objc dynamic var name: String = ""
    /**
     *
     */
    @objc dynamic var icon: String = ""
    /**
     *
     */
    @objc dynamic var category: String = ""
    /**
     *
     */
    let items = List<ActionDescription>()
    /**
     *
     */
    let options1 = List<ActionDescription>()
    /**
     *
     */
    let options2 = List<ActionDescription>()
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.category = try decoder.decodeIfPresent("category") ?? self.category
            
            decodeIntoList(decoder, "items", self.items)
            decodeIntoList(decoder, "options1", self.options1)
            decodeIntoList(decoder, "options2", self.options2)
        }
    }
}

class multiItemConfig: RenderConfig {
    var press: ActionDescription? = ActionDescription(icon: nil, title: nil, actionName: .openView, actionArgs: [])

}

class ListConfig: multiItemConfig {
    var cascadeOrder: [String] = []
    var slideLeftActions: [ActionDescription] = []
    var slideRightActions: [ActionDescription] = []
    var type: String = "list"
    var browse: String = ""
    var sortProperty: String = ""
    var sortAscending: Int = 0
    var itemRenderer: String = ""
    var longPress: ActionDescription? = nil
    

    init(name: String?=nil, icon: String?=nil, category: String?=nil, items: [ActionDescription]?=nil, options1: [ActionDescription]?=nil,
         options2: [ActionDescription]?=nil, cascadeOrder: [String]?=nil, slideLeftActions: [ActionDescription]?=nil,
         slideRightActions: [ActionDescription]?=nil, type: String?=nil, browse: String?=nil, sortProperty: String?=nil,
         sortAscending: Int?=nil, itemRenderer: String?=nil, longPress: ActionDescription?=nil, press: ActionDescription? = nil){
        super.init()
        self.cascadeOrder=cascadeOrder ?? self.cascadeOrder
        self.slideLeftActions=slideLeftActions ?? self.slideLeftActions
        self.slideRightActions=slideRightActions ?? self.slideRightActions
        self.type=type ?? self.type
        self.browse=browse ?? self.browse
        self.sortProperty=sortProperty ?? self.sortProperty
        self.sortAscending=sortAscending ?? self.sortAscending
        self.itemRenderer=itemRenderer ?? self.itemRenderer
        self.longPress=longPress ?? self.longPress
        self.press = press ?? self.press
    }
    
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    required init() {
        super.init()
    }
}

class ThumbnailConfig: multiItemConfig {
    var cascadeOrder: [String] = []
    var slideLeftActions: [ActionDescription] = []
    var slideRightActions: [ActionDescription] = []
    var type: String = "thumbnail"
    var browse: String = ""
    var sortProperty: String = ""
    var sortAscending: Int = 0
    var itemRenderer: String = ""
    var longPress: ActionDescription? = nil
    var cols: Int = 3

    init(name: String?=nil, icon: String?=nil, category: String?=nil, items: [ActionDescription]?=nil, options1: [ActionDescription]?=nil,
         options2: [ActionDescription]?=nil, cascadeOrder: [String]?=nil, slideLeftActions: [ActionDescription]?=nil,
         slideRightActions: [ActionDescription]?=nil, type: String?=nil, browse: String?=nil, sortProperty: String?=nil,
         sortAscending: Int?=nil, itemRenderer: String?=nil, longPress: ActionDescription?=nil, press: ActionDescription? = nil, cols: Int? = nil){
        super.init()
        self.cascadeOrder=cascadeOrder ?? self.cascadeOrder
        self.slideLeftActions=slideLeftActions ?? self.slideLeftActions
        self.slideRightActions=slideRightActions ?? self.slideRightActions
        self.type=type ?? self.type
        self.browse=browse ?? self.browse
        self.sortProperty=sortProperty ?? self.sortProperty
        self.sortAscending=sortAscending ?? self.sortAscending
        self.itemRenderer=itemRenderer ?? self.itemRenderer
        self.longPress=longPress ?? self.longPress
        self.press = press ?? self.press
        self.cols = cols ?? self.cols
    }
    
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    required init() {
        super.init()
    }
}
