//
//  ListConfig.swift
//  memri
//
//  Created by Ruben Daniels on 4/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class ThumbnailRenderer: Renderer{
    required init(){
        super.init()
        self.name = "thumbnail"
        self.icon = "square.grid.3x2.fill"
        self.renderConfig = ThumbnailConfig()

    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        // checks if everything can be casted to note
        return items.count == items.compactMap({$0 as? Note}).count
    }
}

class ThumbnailConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail"
    @objc dynamic var browse: String? = ""
    @objc dynamic var itemRenderer: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    let cols = RealmOptional<Int>(3)
    
    let slideLeftActions = List<ActionDescription>()
    let slideRightActions = List<ActionDescription>()

    // TODO: Why do we need this contructor?
    init(name: String?=nil, icon: String?=nil, category: String?=nil,
         items: [ActionDescription]?=nil, options1: [ActionDescription]?=nil,
         options2: [ActionDescription]?=nil, cascadeOrder: [String]?=nil,
         slideLeftActions: [ActionDescription]?=nil, slideRightActions: [ActionDescription]?=nil,
         type: String?=nil, browse: String?=nil, itemRenderer: String?=nil,
         longPress: ActionDescription?=nil, press: ActionDescription? = nil, cols: Int? = nil){
        
        super.init()
        
        self.type = type ?? self.type
        self.browse = browse ?? self.browse
        self.itemRenderer = itemRenderer ?? self.itemRenderer
        self.longPress = longPress ?? self.longPress
        self.press = press ?? self.press
        self.cols.value = cols ?? 3
        
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
            self.cols.value = try decoder.decodeIfPresent("cols") ?? 3
            
            decodeIntoList(decoder, "slideLeftActions", self.slideLeftActions)
            decodeIntoList(decoder, "slideRightActions", self.slideRightActions)
            
            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ thumbnailConfig:ThumbnailConfig) {
        self.type = thumbnailConfig.type ?? self.type
        self.browse = thumbnailConfig.browse ?? self.browse
        self.itemRenderer = thumbnailConfig.itemRenderer ?? self.itemRenderer
        self.longPress = thumbnailConfig.longPress ?? self.longPress
        self.press = thumbnailConfig.press ?? self.press
        self.cols.value = thumbnailConfig.cols.value ?? self.cols.value
        
        self.slideLeftActions.append(objectsIn: thumbnailConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: thumbnailConfig.slideRightActions)
        
        super.superMerge(thumbnailConfig)
    }
}
