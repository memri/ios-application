//
//  SessionView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class SessionView: DataItem {
 
    override var genericType:String { "sessionview" }
 
    @objc dynamic var name: String? = nil
    @objc dynamic var title: String? = nil
    @objc dynamic var rendererName: String? = nil
    @objc dynamic var subtitle: String? = nil
    @objc dynamic var backTitle: String? = nil
    @objc dynamic var icon: String? = nil
    @objc dynamic var browsingMode: String? = nil
    @objc dynamic var filterText: String? = nil
    @objc dynamic var emptyResultText: String? = nil
    
    let showLabels = RealmOptional<Bool>()
    
    let cascadeOrder = RealmSwift.List<String>()
    let sortFields = RealmSwift.List<String>()
    let selection = RealmSwift.List<DataItem>()
    let editButtons = RealmSwift.List<ActionDescription>()
    let filterButtons = RealmSwift.List<ActionDescription>()
    let actionItems = RealmSwift.List<ActionDescription>()
    let navigateItems = RealmSwift.List<ActionDescription>()
    let contextButtons = RealmSwift.List<ActionDescription>()
    let activeStates = RealmSwift.List<String>()
    
    @objc dynamic var queryOptions: QueryOptions? = QueryOptions()
    @objc dynamic var renderConfigs: RenderConfigs? = RenderConfigs()
    
    @objc dynamic var actionButton: ActionDescription? = nil
    @objc dynamic var editActionButton: ActionDescription? = nil
    
    @objc dynamic var session: Session? = nil
    
    @objc dynamic var _variables: String? = nil
    
 
    // TODO Refactor: Holy Guacamole this seems inefficient
    // Variables should probably be a more intelligent class that does conversion to codable
    var variables: [String:Any]? {
        get {
            if let strVars = self._variables {
                // TODO REfactor: error handling
                let data = strVars.data(using: .utf8)!
                let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments)
                
                if var variables = json as? [String: Any] {
                    for (key, value) in variables {
                        if let value = value as? [String:Any] {
                            // TODO Refactor: find a stronger assumption when generalizing this
                            if let uid = value["uid"], let type = value["type"] {
                                let type = DataItemFamily(rawValue: type as! String)
                                if let type = type {
                                    variables[key] = DataItemReference(type: type, uid: uid as! String)
                                }
                            }
                        }
                    }
                    
                    return variables
                }
            }
            
            return nil
        }
        set (vars) {
            if let vars = vars {
                var result = [String:Any]()
                for (key, value) in vars {
                    if let value = value as? DataItemReference {
                        result[key] = ["type": value.type.rawValue, "uid": value.uid]
                    }
                    else if let value = value as? DataItem {
                        result[key] = ["type": value.genericType, "uid": value.uid]
                    }
                    else {
                        result[key] = value
                    }
                }
                
                self._variables = serialize(AnyCodable(result))
            }
            else {
                self._variables = serialize(nil)
            }
        }
    }
    
    override var computeTitle:String {
        if let value = self.name ?? self.title { return value }
        else if let rendererName = self.rendererName {
            return "A \(rendererName) showing: \(self.queryOptions?.query ?? "")"
        }
        else if let query = self.queryOptions?.query {
            return "Showing: \(query)"
        }
        return "[No Name]"
    }
    
    private enum CodingKeys: String, CodingKey {
        case queryOptions, title, rendererName, name, subtitle, selection, renderConfigs,
            editButtons, filterButtons, actionItems, navigateItems, contextButtons, actionButton,
            backTitle, editActionButton, icon, showLabels, sortFields,
            browsingMode, cascadeOrder, activeStates, emptyResultText
    }
    
    required init(){
        super.init()
        
        self.functions["computedDescription"] = {_ in
            print("MAKE THIS DISSAPEAR")
            return self.computeTitle
        }
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.queryOptions = try decoder.decodeIfPresent("queryOptions") ?? self.queryOptions
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.rendererName = try decoder.decodeIfPresent("rendererName") ?? self.rendererName
            self.subtitle = try decoder.decodeIfPresent("subtitle") ?? self.subtitle
            self.backTitle = try decoder.decodeIfPresent("backTitle") ?? self.backTitle
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.browsingMode = try decoder.decodeIfPresent("browsingMode") ?? self.browsingMode
            self.filterText = try decoder.decodeIfPresent("filterText") ?? self.filterText
            self.emptyResultText = try decoder.decodeIfPresent("emptyResultText") ?? self.emptyResultText
            
            self.showLabels.value = try decoder.decodeIfPresent("showLabels") ?? self.showLabels.value
            
            decodeIntoList(decoder, "cascadeOrder", self.cascadeOrder)
            decodeIntoList(decoder, "sortFields", self.sortFields)
            decodeIntoList(decoder, "selection", self.selection)
            decodeIntoList(decoder, "editButtons", self.editButtons)
            decodeIntoList(decoder, "filterButtons", self.filterButtons)
            decodeIntoList(decoder, "actionItems", self.actionItems)
            decodeIntoList(decoder, "navigateItems", self.navigateItems)
            decodeIntoList(decoder, "contextButtons", self.contextButtons)
            decodeIntoList(decoder, "activeStates", self.activeStates)
            
            self.renderConfigs = try decoder.decodeIfPresent("renderConfigs") ?? self.renderConfigs
            self.actionButton = try decoder.decodeIfPresent("actionButton") ?? self.actionButton
            self.editActionButton = try decoder.decodeIfPresent("editActionButton") ?? self.editActionButton
            
            if let parsedJSON:[String:AnyCodable] = try decoder.decodeIfPresent("variables") {
                self._variables = String(
                    data: try! MemriJSONEncoder.encode(parsedJSON), encoding: .utf8)!
            }
            
            try! super.superDecode(from: decoder)
        }
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public func hasState(_ stateName:String) -> Bool{
        if activeStates.contains(stateName){
            return true
        }
        return false
    }
    
    public func toggleState(_ stateName:String) {
        if let index = activeStates.index(of: stateName){
            activeStates.remove(at: index)
        }
        else {
            activeStates.append(stateName)
        }
    }
    
    public func merge(_ view:SessionView) {
        
        self.queryOptions!.merge(view.queryOptions!)
        
        self.name = view.name ?? self.name
        self.rendererName = view.rendererName ?? self.rendererName
        self.backTitle = view.backTitle ?? self.backTitle
        self.icon = view.icon ?? self.icon
        self.browsingMode = view.browsingMode ?? self.browsingMode
        
        self.title = view.title ?? self.title
        self.subtitle = view.subtitle ?? self.subtitle
        self.filterText = view.filterText ?? self.filterText
        self.emptyResultText = view.emptyResultText ?? self.emptyResultText
        
        self.showLabels.value = view.showLabels.value ?? self.showLabels.value
        
        if view.sortFields.count > 0 {
            self.sortFields.removeAll()
            self.sortFields.append(objectsIn: view.sortFields)
        }
        
        self.cascadeOrder.append(objectsIn: view.cascadeOrder)
        self.selection.append(objectsIn: view.selection)
        self.editButtons.append(objectsIn: view.editButtons)
        self.filterButtons.append(objectsIn: view.filterButtons)
        self.actionItems.append(objectsIn: view.actionItems)
        self.navigateItems.append(objectsIn: view.navigateItems)
        self.contextButtons.append(objectsIn: view.contextButtons)
        
        if let renderConfigs = view.renderConfigs {
            self.renderConfigs!.merge(renderConfigs)
        }
        
        self.actionButton = view.actionButton ?? self.actionButton
        self.editActionButton = view.editActionButton ?? self.editActionButton
        
        // TODO Refactor move to an arguments class
        if let variables = view.variables {
            var myVars = self.variables ?? [:]
            
            for (key, value) in variables {
                myVars[key] = value
            }
            self.variables = myVars
        }
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> SessionView {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: SessionView = try! MemriJSONDecoder.decode(SessionView.self, from: jsonData)
        return items
    }
    
    public class func fromJSONString(_ json: String) throws -> SessionView {
        let view:SessionView = try MemriJSONDecoder.decode(SessionView.self, from: Data(json.utf8))
        return view
    }
}
