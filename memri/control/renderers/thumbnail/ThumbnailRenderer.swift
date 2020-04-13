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
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    let cols = RealmOptional<Int>(3)
    
    let slideLeftActions = List<ActionDescription>()
    let slideRightActions = List<ActionDescription>()
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
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
        self.longPress = thumbnailConfig.longPress ?? self.longPress
        self.press = thumbnailConfig.press ?? self.press
        self.cols.value = thumbnailConfig.cols.value ?? self.cols.value
        
        self.slideLeftActions.append(objectsIn: thumbnailConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: thumbnailConfig.slideRightActions)
        
        super.superMerge(thumbnailConfig)
    }
}
