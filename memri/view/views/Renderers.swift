//
//  Renderer.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import RealmSwift
import SwiftUI
import OrderedDictionary

var allRenderers:Renderers? = nil

public class Renderers {
    var all: [String: FilterPanelRendererButton] = [:]
    var allViews: [String: AnyView] = [:]
    var allConfigTypes: [String: CascadingRenderConfig.Type] = [:]
    
    class func register(name:String, title:String, order:Int, icon:String = "",
                        view:AnyView, renderConfigType: CascadingRenderConfig.Type,
                        canDisplayResults: @escaping (_ items: [DataItem]) -> Bool) {
        
        if allRenderers == nil { allRenderers = Renderers() }
    
        // NOTE: Allowed force unwrap (logic)
        allRenderers!.all[name] = FilterPanelRendererButton(
            name: name,
            order: order,
            title: title,
            icon: icon,
            canDisplayResults: canDisplayResults
        )
        allRenderers!.allViews[name] = view
        allRenderers!.allConfigTypes[name] = renderConfigType
    }
    
    var tuples: [(key: String, value: FilterPanelRendererButton)] {
        return all.sorted{$0.key < $1.key}
    }
}

class FilterPanelRendererButton: Action, ActionExec {
    private var defaults:[String:Any] {[
        "hasState": true,
        "activeColor": Color(hex: "#6aa84f"),
        "activeBackgroundColor": Color(hex: "#eee"),
        "title": "Unnamed Renderer"
    ]}
    
    var order: Int
    var canDisplayResults: (_ items: [DataItem]) -> Bool
    var rendererName: String
    
    required init(name:String, order:Int, title:String, icon:String,
                  canDisplayResults:@escaping (_ items: [DataItem]) -> Bool){
        
        self.rendererName = name
        self.order = order
        self.canDisplayResults = canDisplayResults
        
        super.init("setRenderer", values: ["icon":icon, "title":title])
    }
    
    func exec(_ main:Main, _ arguments:[String: Any]) {
//        self.setInactive(objects: Array(self.renderObjects.values))
//        setActive(object: rendererObject)
        let session = main.currentSession
        realmWriteIfAvailable(main.cache.realm, {
            // TODO: Implement
            main.cascadingView.activeRenderer = self.rendererName
        })
        
        main.scheduleCascadingViewUpdate()
    }
}

public class RenderGroup {
    var options: [String:Any] = [:]
    var body: UIElement? = nil
}

protocol CascadingRendererDefaults {
    func setDefaultValues(_ element: UIElement)
}

 
//    private var renderDescription: [String:Any]? {
//        let rd = cascadeDict("renderDescription", sessionView.definition)
//
//        if let renderDescription:[String: UIElement] = globalInMemoryObjectCache.get(rd) {
//            return renderDescription
//        }
//        else if let renderDescription:[String: UIElement] = unserialize(rd) {
//            globalInMemoryObjectCache.set(rd, renderDescription)
//            return renderDescription
//        }
//
//        return nil
//    }

public class CascadingRenderConfig: Cascadable {
    var viewArguments: ViewArguments
    
    required init(_ cascadeStack: [CVUParsedDefinition], _ viewArguments: ViewArguments) {
        self.viewArguments = viewArguments
        super.init()
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
    
 
    public func render(item:DataItem, group:String = "*",
                       arguments:ViewArguments? = nil) -> UIElementView {
        
        if let renderGroup:RenderGroup = cascadeProperty(group, nil) {
            let body = renderGroup.body
            if let s = self as? CascadingRendererDefaults, let body = body {
                s.setDefaultValues(body)
            }
            
            return UIElementView(body ?? UIElement("Empty"), item, arguments ?? viewArguments)
        }
        else {
            return UIElementView(UIElement("Empty"), item)
        }
    }
}
