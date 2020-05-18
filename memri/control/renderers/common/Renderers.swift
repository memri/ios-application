//
//  Renderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import RealmSwift
import SwiftUI
import OrderedDictionary

var globalRenderers:Renderers? = nil

public class Renderers {
    var all: [String: FilterPanelRendererButton] = [:]
    var allViews: [String: AnyView] = [:]
    var allConfigTypes: [String: CascadingRenderConfig.Type]
    
    class func register(name:String, title:String, order:Int, icon:String = "",
                        view:AnyView, renderConfigType: CascadingRenderConfig.Type,
                        canDisplayResults: @escaping (_ items: [DataItem]) -> Bool) {
        
        if globalRenderers == nil { globalRenderers = Renderers() }
    
        globalRenderers!.all[name] = FilterPanelRendererButton(
            name: name,
            order: order,
            icon: icon,
            canDisplayResults: canDisplayResults
        )
        globalRenderers!.allViews[name] = view
        globalRenderers!.allConfigTypes[name] = renderConfigType
    }
    
    var tuples: [(key: String, value: FilterPanelRendererButton)] {
        return all.sorted{$0.key < $1.key}
    }
}

class FilterPanelRendererButton: ActionDescription, ObservableObject{
    var name: String
    var order: Int
    var canDisplayResults: (_ items: [DataItem]) -> Bool
    
    required init(name:String, order:Int, icon:String, canDisplayResults:@escaping (_ items: [DataItem]) -> Bool){
        super.init()
        
        self.name = name
        self.order = order
        self.icon = icon
        self.canDisplayResults = canDisplayResults
        
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
    
    public required init() {
        fatalError("init() has not been implemented")
    }
    
    public convenience required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public class RenderGroup {
    var options: [String:Any] = [:]
    var body: GUIElementDescription? = nil
}

 
//    private var renderDescription: [String:Any]? {
//        let rd = cascadeDict("renderDescription", sessionView.definition)
//
//        if let renderDescription:[String: GUIElementDescription] = globalCache.get(rd) {
//            return renderDescription
//        }
//        else if let renderDescription:[String: GUIElementDescription] = unserialize(rd) {
//            globalCache.set(rd, renderDescription)
//            return renderDescription
//        }
//
//        return nil
//    }

public class CascadingRenderConfig: Cascadable {
    private var viewArguments: ViewArguments
    
    init(cascadeStack: [[String:Any]], viewArguments: ViewArguments) {
        self.viewArguments = viewArguments
        self.cascadeStack = cascadeStack
    }
    
    
    func hasGroup(_ group:String) -> Bool {
        cascadeProperty(group, nil) != nil
    }
    
    
    func getGroupOptions(_ group:String) -> [String:Any] {
        if let renderGroup:RenderGroup = cascadeProperty(group, nil) {
            return renderGroup.options
        }
        return [:]
    }
    
 
    public func render(item:DataItem, group:String = "*") -> GUIElementInstance {
        if var renderGroup:RenderGroup = cascadeProperty(group, nil) {
            return GUIElementInstance(renderGroup.body ?? GUIElementDescription(), item, self.viewArguments)
        }
        else {
            return GUIElementInstance(GUIElementDescription(), item, self.viewArguments)
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
