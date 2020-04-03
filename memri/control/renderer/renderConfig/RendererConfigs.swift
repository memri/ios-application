//
//  RenderConfigs.swift
//  memri
//
//  Created by Koen van der Veen on 02/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

/*
    TODO:
    - create a renderConfigs class that has a list for each render config indexed by the name
    - change the json back to the dict as it was before
    - Strange! realm has 0 actiondescriptions
*/

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

class ListConfig: RenderConfig {
    @objc dynamic var type: String = "list"
    @objc dynamic var browse: String = ""
    @objc dynamic var itemRenderer: String = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let cascadeOrder = List<String>()
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
        
        self.type=type ?? self.type
        self.browse=browse ?? self.browse
        self.itemRenderer=itemRenderer ?? self.itemRenderer
        self.longPress=longPress ?? self.longPress
        self.press = press ?? self.press
        
        self.cascadeOrder.append(objectsIn: cascadeOrder ?? [])
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
            
            decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
            decodeIntoList(decoder, "slideLeftActions", self.slideLeftActions)
            decodeIntoList(decoder, "slideRightActions", self.slideRightActions)
        }
    }
    
    required init() {
        super.init()
    }
}

class ThumbnailConfig: RenderConfig {
    @objc dynamic var type: String = "thumbnail"
    @objc dynamic var browse: String = ""
    @objc dynamic var itemRenderer: String = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    @objc dynamic var cols: Int = 3
    
    let cascadeOrder = List<String>()
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
        
        self.type=type ?? self.type
        self.browse=browse ?? self.browse
        self.itemRenderer=itemRenderer ?? self.itemRenderer
        self.longPress=longPress ?? self.longPress
        self.press = press ?? self.press
        self.cols = cols ?? self.cols
        
        self.cascadeOrder.append(objectsIn: cascadeOrder ?? [])
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
            self.cols = try decoder.decodeIfPresent("cols") ?? self.cols
            
            decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
            decodeIntoList(decoder, "slideLeftActions", self.slideLeftActions)
            decodeIntoList(decoder, "slideRightActions", self.slideRightActions)
        }
    }
    
    required init() {
        super.init()
    }
}
