//
//  RenderConfigs.swift
//  memri
//
//  Created by Koen van der Veen on 02/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

/*
    TODO:
    - fix search
    - fix starring
    - including back and restart behavior
    - Clean up of sessionview, queryoptions, session, renderConfig, etc
*/

public class RenderConfigs: Object, Codable {
    /**
     *
     */
    @objc dynamic var list: ListConfig? = nil
    /**
     *
     */
    @objc dynamic var thumbnail: ThumbnailConfig? = nil
    
    /**
     *
     */
    public func merge(_ renderConfigs:RenderConfigs) {
        if let config = renderConfigs.list {
            if self.list == nil { self.list = ListConfig() }
            self.list!.merge(config)
        }
        if let config = renderConfigs.thumbnail {
            if self.thumbnail == nil { self.thumbnail = ThumbnailConfig() }
            self.thumbnail!.merge(config)
        }
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.list = try decoder.decodeIfPresent("list") ?? self.list
            self.thumbnail = try decoder.decodeIfPresent("thumbnail") ?? self.thumbnail
        }
    }
}

public class RenderConfig: Object, Codable {
    /**
     *
     */
    @objc dynamic var name: String? = nil
    /**
     *
     */
    @objc dynamic var icon: String? = nil
    /**
     *
     */
    @objc dynamic var category: String? = nil
    /**
     *
     */
    let items = RealmSwift.List<ActionDescription>()
    /**
     *
     */
    let options1 = RealmSwift.List<ActionDescription>()
    /**
     *
     */
    let options2 = RealmSwift.List<ActionDescription>()
    
    /**
     *
     */
    public func superMerge(_ renderConfig:RenderConfig) {
        self.name = renderConfig.name ?? self.name
        self.icon = renderConfig.icon ?? self.icon
        self.category = renderConfig.category ?? self.category
        
        self.items.append(objectsIn: renderConfig.items)
        self.options1.append(objectsIn: renderConfig.options1)
        self.options2.append(objectsIn: renderConfig.options2)
    }
    
    /**
     * @private
     */
    public func superDecode(from decoder: Decoder) throws {
        self.name = try decoder.decodeIfPresent("name") ?? self.name
        self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
        self.category = try decoder.decodeIfPresent("category") ?? self.category
        
        decodeIntoList(decoder, "items", self.items)
        decodeIntoList(decoder, "options1", self.options1)
        decodeIntoList(decoder, "options2", self.options2)
    }
    
    func generatePreview(_ item:DataItem) -> String {
        let content = item.getString("content")
        return content
    }

}

public class ListConfig: RenderConfig {
    @objc dynamic var type: String? = "list"
    @objc dynamic var browse: String? = ""
    @objc dynamic var itemRenderer: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    
    let slideLeftActions = RealmSwift.List<ActionDescription>()
    let slideRightActions = RealmSwift.List<ActionDescription>()

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
        
        self.slideLeftActions.append(objectsIn: listConfig.slideLeftActions)
        self.slideRightActions.append(objectsIn: listConfig.slideRightActions)
        
        super.superMerge(listConfig)
    }
    
    func renderItem(item: DataItem) -> some View {
        return VStack{
                    Text(item.getString("title"))
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(self.generatePreview(item))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
    }
    
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> ListConfig {
        let jsonData = try jsonDataFromFile(file, ext)
        let config: ListConfig = try! JSONDecoder().decode(ListConfig.self, from: jsonData)
        return config
    }
    
}


class ThumbnailConfig: RenderConfig {
    @objc dynamic var type: String? = "thumbnail"
    @objc dynamic var browse: String? = ""
    @objc dynamic var itemRenderer: String? = ""
    @objc dynamic var longPress: ActionDescription? = nil
    @objc dynamic var press: ActionDescription? = nil
    let cols = RealmOptional<Int>(3)
    
    let slideLeftActions = RealmSwift.List<ActionDescription>()
    let slideRightActions = RealmSwift.List<ActionDescription>()

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
