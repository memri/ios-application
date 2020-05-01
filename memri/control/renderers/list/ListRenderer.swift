//
//  ListConfig.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class ListRenderer: Renderer{
    var mode:String = ""
    
    required init(){
        super.init()
        self.name = "list"
        self.title = "Default"
        self.order = 0
        self.icon = "line.horizontal.3"
        self.renderConfig = ListConfig()
    }
    
    convenience required init(mode:String){
        self.init()
        
        if (mode == "alphabet") {
            self.name = "list.alphabet"
            self.order = 1
            self.title = "Alphabet"
        }
    }
    
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        // checks if everything can be casted to data item
        return true
    }
}

class ListConfig: RenderConfig {
    @objc dynamic var type: String? = "list"
    @objc dynamic var browse: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let slideLeftActions = List<ActionDescription>()
    let slideRightActions = List<ActionDescription>()
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
            self.longPress = try decoder.decodeIfPresent("longPress") ?? self.longPress
            self.press = try decoder.decodeIfPresent("press") ?? self.press
            
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
        self.longPress = listConfig.longPress ?? self.longPress
        self.press = listConfig.press ?? self.press
        
        self.slideLeftActions.append(objectsIn: listConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: listConfig.slideRightActions)
        
        super.superMerge(listConfig)
    }
}

