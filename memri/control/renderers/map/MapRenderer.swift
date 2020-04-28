//
//  MapConfig.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class MapRenderer: Renderer{
    var mode:String = ""
    
    required init(){
        super.init()
        self.name = "map"
        self.title = "Default"
        self.order = 3
        self.icon = "map"
        self.renderConfig = MapConfig()
    }
    
    convenience required init(mode:String){
        self.init()
    }
    
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        // checks if everything can be casted to data item
        return true
    }
}

class MapConfig: RenderConfig {
    @objc dynamic var type: String? = "map"
    @objc dynamic var browse: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.browse = try decoder.decodeIfPresent("browse") ?? self.browse
            self.longPress = try decoder.decodeIfPresent("longPress") ?? self.longPress
            self.press = try decoder.decodeIfPresent("press") ?? self.press
            
            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ mapConfig:MapConfig) {
        self.type = mapConfig.type ?? self.type
        self.browse = mapConfig.browse ?? self.browse
        self.longPress = mapConfig.longPress ?? self.longPress
        self.press = mapConfig.press ?? self.press
        
        super.superMerge(mapConfig)
    }
}

