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
        return true
    }
}

class ThumbnailConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail"
    @objc dynamic var browse: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let columns = RealmOptional<Int>()
    let vPadding = RealmOptional<Int>()
    let hPadding = RealmOptional<Int>()
    let vSpacing = RealmOptional<Int>()
    let hSpacing = RealmOptional<Int>()
    let columnsInLandscape = RealmOptional<Int>()
    
    let slideLeftActions = List<ActionDescription>()
    let slideRightActions = List<ActionDescription>()
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
            self.longPress = try decoder.decodeIfPresent("longPress") ?? self.longPress
            self.press = try decoder.decodeIfPresent("press") ?? self.press
            
            self.columns.value = try decoder.decodeIfPresent("columns") ?? self.columns.value
            self.vPadding.value = try decoder.decodeIfPresent("vPadding") ?? self.vPadding.value
            self.hPadding.value = try decoder.decodeIfPresent("hPadding") ?? self.hPadding.value
            self.vSpacing.value = try decoder.decodeIfPresent("vSpacing") ?? self.vSpacing.value
            self.hSpacing.value = try decoder.decodeIfPresent("hSpacing") ?? self.hSpacing.value
            self.columnsInLandscape.value = try decoder.decodeIfPresent("columnsInLandscape") ?? self.columnsInLandscape.value
            
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
        
        self.columns.value = thumbnailConfig.columns.value ?? self.columns.value
        self.vPadding.value = thumbnailConfig.vPadding.value ?? self.vPadding.value
        self.hPadding.value = thumbnailConfig.hPadding.value ?? self.hPadding.value
        self.vSpacing.value = thumbnailConfig.vSpacing.value ?? self.vSpacing.value
        self.hSpacing.value = thumbnailConfig.hSpacing.value ?? self.hSpacing.value
        self.columnsInLandscape.value = thumbnailConfig.columnsInLandscape.value ?? self.columnsInLandscape.value
        
        self.slideLeftActions.append(objectsIn: thumbnailConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: thumbnailConfig.slideRightActions)
        
        super.superMerge(thumbnailConfig)
    }
}
