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
        "richTextEditor":   RichTextRenderer(),
        "thumbnail":        ThumbnailRenderer(),
        "generalEditor":    GeneralEditor()
    ]
    
    var allViews: [String: AnyView] = [
        "list":             AnyView(ListRendererView()),
        "richTextEditor":   AnyView(RichTextRendererView()),
        "thumbnail":        AnyView(ThumbnailRendererView()),
        "generalEditor":    AnyView(GeneralEditorView())
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
    @objc dynamic var generalEditor: GeneralEditorConfig? = nil

    
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
            self.generalEditor = try decoder.decodeIfPresent("generalEditor") ?? self.generalEditor
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
    @objc dynamic var _renderDescription: String? = nil
    
    
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
        self.icon = renderConfig.icon ?? self.icon
        self.category = renderConfig.category ?? self.category
        self._renderDescription = renderConfig._renderDescription ?? self._renderDescription
        
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
        
        // Receiving a string from the preprocessed view description for storage in realm
        self._renderDescription = try decoder.decodeIfPresent("renderDescription") ?? self._renderDescription
        
        decodeIntoList(decoder, "items", self.items)
        decodeIntoList(decoder, "options1", self.options1)
        decodeIntoList(decoder, "options2", self.options2)
    }
    
    /*
        Loading views from disk
        1. read user defined json string from disk and puts it in a DynamicView that can be stored in realm
        
        The first time a view is instantiated (with the goal of creating a SessionView)
        2. Load json string in CompiledView and parse it into [String:Any] object tree structure
        3. Pre-process object tree into an optimized json string so that its very fast to generate a SessionView by replacing all dynamic properties (e.g. {.title}) as needed in step (4) and preprocessing what is needed (i.e. parseRenderDescription() that turns the renderDescription into a string)
     
            How is the json string optimized?
            - Looks up all the variables and puts them in a dict
                - Skips over variables that need to be calculated at runtime (i.e. ActionDescription.actionStateName)
            - Replaces the variables that need to be replaces with {$0} (0 being a auto-increment)
            - At the end you have a dict and a json string
     
        Any time a view is instantiated
        4. During CompiledView.generateView() the optimized json string (using the dict) is decoded using Codable into a SessionView, and its class hierarchy. (i.e. SessionView.renderConfigs.* is the RenderConfig). N.B. in the class hierarchy we have a _renderDescription that is a string.
        5. RenderConfig gets the renderDescription string in that process from the json and stores it in _renderDescription for potential storage in realm
     
        When .render() is called
        6. First time, the _renderDescription json string is decoded into [String:GUIElement] and added to the RenderCache
        7. Next time .render() is called simply get the [String:GUIElement] from the cache
     */
    
    // How users type it
    //    [ "VStack", { "padding": 5 }, [
    //        "Text", { "value": "{.content}" },
    //        "Button", { "press": {"actionName": "back"} }, ["Text", "Back"],
    //        "Button", { "press": {"actionName": "openView"} }, [
    //            "Image", {"systemName": "star.fill"}
    //        ],
    //        "Text", { "value": "{.content}" }
    //    ]]
        
    // How codable wants it - the above is transformed into below in parseRenderDescription()
    //    {
    //        "type": "vstack",
    //        "children": [
    //            {
    //                "type": "text",
    //                "properties": {
    //                    "value": "{.title}",
    //                    "bold": true
    //                }
    //            },
    //            {
    //                "type": "text",
    //                "properties": {
    //                    "values": "{.content}",
    //                    "bold": false,
    //                    "removeWhiteSpace": true,
    //                    "maxChar": 100
    //                }
    //            }
    //        ]
    //    }
    
    // This is called from CompiledView when pre-processing the view
    public class func parseRenderDescription(_ parsed: Any) -> String {
        var pDict:[String:Any]
        var result:[String:Any] = [:]
        
        // Make sure the description is in a dict, otherwise wrap the array in one
        if let pList = parsed as? [Any] { pDict = ["*": pList] }
        else { pDict = parsed as! [String:Any] }
        
        for (key, value) in pDict {
            result[key] = try! parseSingleRenderDescription(value as! [Any])
        }
        
        // Returning a string to optimize savin as a string in realm
        return serialize(AnyCodable(result))
    }
    
    private class func parseSingleRenderDescription(_ parsed:[Any]) throws -> Any {
        var result:[Any] = []
        
        func walkParsed(_ parsed:[Any], _ result:inout [Any]) throws {
            var currentItem:[String:Any] = [:]
            
            for item in parsed {
                if let item = item as? String {
                    if currentItem["type"] != nil { result.append(currentItem) }
                    currentItem = ["type": item.lowercased()]
                }
                else if let item = item as? [String: Any] {
                    currentItem["properties"] = item
                }
                else if let item = item as? [Any] {
                    var children:[Any] = []
                    try! walkParsed(item, &children)
                    currentItem["children"] = children
                }
                else {
                    throw "Exception: Could not parse render description"
                }
            }
            
            if currentItem["type"] != nil { result.append(currentItem) }
        }
        
        try! walkParsed(parsed, &result)
        
        return result[0]
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
