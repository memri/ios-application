//
//  ThumbGridRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class ThumbGridRenderer: Renderer{
    required init(){
        super.init()
        self.name = "thumbnail.grid"
        self.title = "Photo Grid"
        self.icon = "square.grid.3x2.fill"
        self.renderConfig = ThumbGridConfig()

    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
}

class ThumbGridConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail.grid"
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
    
    public func merge(_ thumbgridConfig:ThumbGridConfig) {
        self.type = thumbgridConfig.type ?? self.type
        self.browse = thumbgridConfig.browse ?? self.browse
        self.longPress = thumbgridConfig.longPress ?? self.longPress
        self.press = thumbgridConfig.press ?? self.press
        
        self.columns.value = thumbgridConfig.columns.value ?? self.columns.value
        self.columnsWide.value = thumbgridConfig.columnsWide.value ?? self.columnsWide.value
        self.itemInset.value = thumbgridConfig.itemInset.value ?? self.itemInset.value
        
        self.edgeInset.append(objectsIn: thumbgridConfig.edgeInset)
        
        super.superMerge(thumbgridConfig)
    }
}
