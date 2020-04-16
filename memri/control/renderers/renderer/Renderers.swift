//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import RealmSwift
import SwiftUI

public class Renderers {
    var all: [String: Renderer] = [
        "list":             ListRenderer(),
        "list.alphabet":    ListRenderer(mode: "alphabet"),
        "richTextEditor":   RichTextRenderer(),
        "thumbnail":        ThumbnailRenderer()
    ]
    
    var allViews: [String: AnyView] = [
        "list":             AnyView(ListRendererView()),
        "richTextEditor":   AnyView(RichTextRendererView()),
        "thumbnail":        AnyView(ThumbnailRendererView())
    ]
    
    var tuples: [(key: String, value: Renderer)] {
        return all.sorted{$0.key < $1.key}
    }
}

// TODO unsure about inheriting from ActionDescription as this is never a realm managed object
class Renderer: ActionDescription, ObservableObject{
    @objc dynamic var name = ""
    @objc dynamic var order = 0
    @objc dynamic var lastActive = ""
    @objc dynamic var renderConfig: RenderConfig? = RenderConfig()
    
    required init(){
        super.init()
        
        self.hasState.value = true
        self.actionName = .setRenderer
        self.activeBackgroundColor = Color(white: 0.95).uiColor()
        self.actionName = .setRenderer
        
        self.color = self.actionName.defaultColor
        self.backgroundColor = self.actionName.defaultBackgroundColor
        self.activeColor = self.actionName.defaultActiveColor
        self.inactiveColor = self.actionName.defaultInactiveColor
        self.activeBackgroundColor = self.actionName.defaultActiveBackgroundColor
        self.inactiveBackgroundColor = self.actionName.defaultInactiveBackgroundColor
    }
    
    func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
}

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
    var renderDescription: [String:GUIElementDescription]? {
        if let itemRenderer = renderCache.get(self._renderDescription!) {
            return itemRenderer
        }
        else if let description = self._renderDescription {
            if let itemRenderer:[String: GUIElementDescription] = unserialize(description) {
                renderCache.set(description, itemRenderer)
                return itemRenderer
            }
        }
        
        return nil
    }
    @objc dynamic var _renderDescription: String? = nil
    
    /**
     *
     */
    public func render(_ dataItem:DataItem, _ part:String = "*") -> GUIElementInstance {
        if _renderDescription == nil {
            return GUIElementInstance(GUIElementDescription(), dataItem)
        }
        else {
            return GUIElementInstance(self.renderDescription![part]!, dataItem)
        }
    }
    
    /**
     *
     */
    public func superMerge(_ renderConfig:RenderConfig) {
        self.name = renderConfig.name ?? self.name
        self._renderDescription = renderConfig._renderDescription ?? self._renderDescription
    }
    
    /**
     * @private
     */
    public func superDecode(from decoder: Decoder) throws {
        self.name = try decoder.decodeIfPresent("name") ?? self.name
        self._renderDescription = try decoder.decodeIfPresent("renderDescription") ?? self._renderDescription
    }
}

class RenderCache {
    var cache:[String:[String:GUIElementDescription]] = [:]
    
    public func get(_ key:String) -> [String:GUIElementDescription]? {
        return cache[key]
    }
    
    public func set(_ key:String, _ itemRenderer: [String:GUIElementDescription]) {
        cache[key] = itemRenderer
    }
}
let renderCache = RenderCache()
