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
        self.title = "Default"
        self.icon = "square.grid.3x2.fill"
        self.renderConfig = ThumbnailConfig()

    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
}

class ThumbnailConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail"
    @objc dynamic var browse: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let columns = RealmOptional<Int>()
    let itemInset = RealmOptional<Int>()
    let edgeInset = List<Int>()
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
            self.longPress = try decoder.decodeIfPresent("longPress") ?? self.longPress
            self.press = try decoder.decodeIfPresent("press") ?? self.press
            
            self.columns.value = try decoder.decodeIfPresent("columns") ?? self.columns.value
            self.itemInset.value = try decoder.decodeIfPresent("itemInset") ?? self.itemInset.value
            
            decodeIntoList(decoder, "edgeInset", self.edgeInset)
            
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
        
        self.columns.value = thumbnailConfig.columns.value ?? self.columns.value
        self.itemInset.value = thumbnailConfig.itemInset.value ?? self.itemInset.value
        
        self.edgeInset.append(objectsIn: thumbnailConfig.edgeInset)
        
        super.superMerge(thumbnailConfig)
    }
}
