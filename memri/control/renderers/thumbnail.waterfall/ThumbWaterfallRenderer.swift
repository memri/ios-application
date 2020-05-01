//
//  ThumbWaterfallRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class ThumbWaterfallRenderer: Renderer{
    required init(){
        super.init()
        self.name = "thumbnail.waterfall"
        self.title = "Waterfall Grid"
        self.order = 30
        self.icon = "square.grid.3x2.fill"
        self.renderConfig = ThumbWaterfallConfig()

    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
}

class ThumbWaterfallConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail.waterfall"
    @objc dynamic var browse: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let columns = RealmOptional<Int>()
    let columnsWide = RealmOptional<Int>()
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
            self.columnsWide.value = try decoder.decodeIfPresent("columnsWide") ?? self.columnsWide.value
            self.itemInset.value = try decoder.decodeIfPresent("itemInset") ?? self.itemInset.value
            
            decodeIntoList(decoder, "edgeInset", self.edgeInset)
            
            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ thumbwaterfallConfig:ThumbWaterfallConfig) {
        self.type = thumbwaterfallConfig.type ?? self.type
        self.browse = thumbwaterfallConfig.browse ?? self.browse
        self.longPress = thumbwaterfallConfig.longPress ?? self.longPress
        self.press = thumbwaterfallConfig.press ?? self.press
        
        self.columns.value = thumbwaterfallConfig.columns.value ?? self.columns.value
        self.columnsWide.value = thumbwaterfallConfig.columnsWide.value ?? self.columnsWide.value
        self.itemInset.value = thumbwaterfallConfig.itemInset.value ?? self.itemInset.value
        
        self.edgeInset.append(objectsIn: thumbwaterfallConfig.edgeInset)
        
        super.superMerge(thumbwaterfallConfig)
    }
}
