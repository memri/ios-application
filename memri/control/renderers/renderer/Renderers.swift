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
import OrderedDictionary

public class Renderers {
    var all: [String: Renderer] = [
        "list":             ListRenderer(),
        "list.alphabet":    ListRenderer(mode: "alphabet"),
        "richTextEditor":   RichTextRenderer(),
        "thumbnail":        ThumbnailRenderer(),
        "thumbnail.grid":   ThumbGridRenderer(),
        "generalEditor":    GeneralEditor()
    ]
    
    var allViews: [String: AnyView] = [
        "list":             AnyView(ListRendererView()),
        "list.alphabet":    AnyView(ListRendererView()),
        "richTextEditor":   AnyView(RichTextRendererView()),
        "thumbnail":        AnyView(ThumbnailRendererView()),
        "thumbnail.grid":   AnyView(ThumbGridRendererView()),
        "generalEditor":    AnyView(GeneralEditorView())
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
    @objc dynamic var thumbnail_grid: ThumbGridConfig? = nil
    /**
     *
     */
    @objc dynamic var generalEditor: GeneralEditorConfig? = nil
    /**
     *
     */
    @objc dynamic var virtual: RenderConfig? = nil
    
    public func merge(_ renderConfigs:RenderConfigs) {
        if let config = renderConfigs.list {
            if self.list == nil { self.list = ListConfig() }
            self.list!.merge(config)
        }
        if let config = renderConfigs.thumbnail {
            if self.thumbnail == nil { self.thumbnail = ThumbnailConfig() }
            self.thumbnail!.merge(config)
        }
        if let config = renderConfigs.thumbnail_grid {
            if self.thumbnail_grid == nil { self.thumbnail_grid = ThumbGridConfig() }
            self.thumbnail_grid!.merge(config)
        }
        if let config = renderConfigs.generalEditor {
            if self.generalEditor == nil { self.generalEditor = GeneralEditorConfig() }
            self.generalEditor!.merge(config)
        }
        if let config = renderConfigs.virtual {
            if self.virtual == nil { self.virtual = RenderConfig() }
            self.virtual!.superMerge(config)
        }
    }
    
    // Refactor maybe: https://stackoverflow.com/questions/50713638/swift-codable-with-dynamic-keys
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.list = try decoder.decodeIfPresent("list") ?? self.list
            self.thumbnail = try decoder.decodeIfPresent("thumbnail") ?? self.thumbnail
            self.thumbnail_grid = try decoder.decodeIfPresent("thumbnail.grid") ?? self.thumbnail_grid
            self.generalEditor = try decoder.decodeIfPresent("generalEditor") ?? self.generalEditor
            
            if let parsedJSON:[String:AnyCodable] = try decoder.decodeIfPresent("virtual") {
                let str = String(data: try! MemriJSONEncoder.encode(parsedJSON), encoding: .utf8)!
                self.virtual = RenderConfig(name: "virtual", renderDescription: str)
            }
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
    @objc dynamic var _renderDescription: String? = nil
    
    convenience init(name:String, renderDescription:String) {
        self.init()
        
        self.name = name
        self._renderDescription = renderDescription
    }
    
    /**
     *
     */
    var renderDescription: [String:GUIElementDescription]? {
        guard let rd = self._renderDescription else {
            return nil
        }
        
        if let renderDescription:[String: GUIElementDescription] = renderCache.get(rd) {
            return renderDescription
        }
        else if let renderDescription:[String: GUIElementDescription] = unserialize(rd) {
            renderCache.set(rd, renderDescription)
            return renderDescription
        }
        
        return nil
    }
    
    /**
     *
     */
    public func render(item:DataItem, part:String = "*",
                       variables:[String:() -> Any] = [:]) -> GUIElementInstance {
        
        if _renderDescription == nil {
            print("WARNING, NO RENDERDESCRIPTION GIVEN FOR \(item.genericType) : \(item.uid)")
            return GUIElementInstance(GUIElementDescription(), item, variables)
        }
        else {
            if self.renderDescription![part] != nil {
                return GUIElementInstance(self.renderDescription![part]!, item, variables)
            }
            else {
                return GUIElementInstance(self.renderDescription!["*"]!, item, variables)
            }
        }
    }
    
    /**
     *
     */
    public func superMerge(_ renderConfig:RenderConfig) {
        self.name = renderConfig.name ?? self.name
        
        if let renderDescription = renderConfig.renderDescription {
            var myRD = self.renderDescription ?? [:]
            
            for (key, value) in renderDescription {
                myRD[key] = value
            }
            
            let data = try! MemriJSONEncoder.encode(myRD)
            self._renderDescription = String(data: data, encoding: .utf8)!
        }
    }
    
    /**
     * @private
     */
    public func superDecode(from decoder: Decoder) throws {
        self.name = try decoder.decodeIfPresent("name") ?? self.name
        
        if let parsedJSON:[String:AnyCodable] = try decoder.decodeIfPresent("renderDescription") {
            self._renderDescription = String(
                data: try! MemriJSONEncoder.encode(parsedJSON), encoding: .utf8)!
        }
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
    public class func parseRenderDescription(_ parsed: Any) -> Any {
        var pDict:[String:Any]
        var result:[String:Any] = [:]
        
        // Make sure the description is in a dict, otherwise wrap the array in one
        if let pList = parsed as? [Any] { pDict = ["*": pList] }
        else { pDict = parsed as! [String:Any] }
        
        for (key, value) in pDict {
            result[key] = try! parseSingleRenderDescription(value as! [Any])
        }
        
        // Returning a string to optimize savin as a string in realm
        return result
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

// Refactor: orderedDicts can go probably?
class RenderCache {
    var cache:[String:[String:GUIElementDescription]] = [:]
    var dictCache:[String:[String:[String]]] = [:]
    var orderedDictCache:[String: OrderedDictionary<String,[String]>] = [:]
    
    public func get(_ key:String) -> [String:[String]]? {
        return dictCache[key]
    }
    
    public func get(_ key:String) -> OrderedDictionary<String,[String]>?{
        return orderedDictCache[key]
    }
    
    public func set(_ key:String, _ dict: [String:[String]]) {
        dictCache[key] = dict
    }
    
    public func set(_ key:String, _ dict: OrderedDictionary<String,[String]>) {
        orderedDictCache[key] = dict
    }
    
    public func get(_ key:String) -> [String:GUIElementDescription]? {
        return cache[key]
    }
    
    public func set(_ key:String, _ itemRenderer: [String:GUIElementDescription]) {
        cache[key] = itemRenderer
    }
}
let renderCache = RenderCache()
