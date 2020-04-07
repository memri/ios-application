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

// TODO add to Main
public class Renderers {
    var all: [String: Renderer] = [
        "list":             ListRenderer(),
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

class Renderer: ActionDescription, ObservableObject{
    @objc dynamic var name = ""
    @objc dynamic var renderConfig: RenderConfig? = RenderConfig()
    
    required init(){
        super.init()
        
        self.hasState.value = true
        self.actionName = .setRenderer
        self.activeBackgroundColor = Color(white: 0.95).uiColor()
        self.actionName = .setRenderer
    }
    
    func canDisplayResultSet(items: [DataItem]) -> Bool{
        return true
    }
}

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
}
