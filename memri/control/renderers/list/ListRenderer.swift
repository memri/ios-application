//
//  ListConfig.swift
//  memri
//
//  Created by Ruben Daniels on 4/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class ListRenderer: Renderer{
    required init(){
        super.init()
        self.name = "list"
        self.icon = "line.horizontal.3"
        self.renderConfig = ListConfig()
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        // checks if everything can be casted to note
        return items.count == items.compactMap({$0 as? Note}).count
    }
}

class ListConfig: RenderConfig {
    @objc dynamic var type: String? = "list"
    @objc dynamic var browse: String? = ""
    @objc dynamic var itemRenderer: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    // TODO: Persist
    var renderDescription: ComponentClass? = nil
    
    let slideLeftActions = List<ActionDescription>()
    let slideRightActions = List<ActionDescription>()


    // TODO: Why do we need this contructor?
    init(name: String?=nil, icon: String?=nil, category: String?=nil,
         items: [ActionDescription]?=nil, options1: [ActionDescription]?=nil,
         options2: [ActionDescription]?=nil, cascadeOrder: [String]?=nil,
         slideLeftActions: [ActionDescription]?=nil, slideRightActions: [ActionDescription]?=nil,
         type: String?=nil, browse: String?=nil, itemRenderer: String?=nil,
         longPress: ActionDescription?=nil, press: ActionDescription? = nil){
        
        super.init()
        
        self.type = type ?? self.type
        self.browse = browse ?? self.browse
        self.itemRenderer = itemRenderer ?? self.itemRenderer
        self.longPress = longPress ?? self.longPress
        self.press = press ?? self.press
        
        self.slideLeftActions.append(objectsIn: slideLeftActions ?? [])
        self.slideRightActions.append(objectsIn: slideRightActions ?? [])
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
            self.itemRenderer = try decoder.decodeIfPresent("itemRenderer") ?? self.itemRenderer
            self.longPress = try decoder.decodeIfPresent("longPress") ?? self.longPress
            self.press = try decoder.decodeIfPresent("press") ?? self.press
            self.renderDescription = try decoder.decodeIfPresent("renderDescription") ?? self.renderDescription
            
            decodeIntoList(decoder, "slideLeftActions", self.slideLeftActions)
            decodeIntoList(decoder, "slideRightActions", self.slideRightActions)
            
            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ listConfig:ListConfig) {
        self.type = listConfig.type ?? self.type
        self.browse = listConfig.browse ?? self.browse
        self.itemRenderer = listConfig.itemRenderer ?? self.itemRenderer
        self.longPress = listConfig.longPress ?? self.longPress
        self.press = listConfig.press ?? self.press
        self.renderDescription = listConfig.renderDescription ?? self.renderDescription
        
        self.slideLeftActions.append(objectsIn: listConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: listConfig.slideRightActions)
        
        super.superMerge(listConfig)
    }
}

