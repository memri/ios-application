//
//  generalEditor.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class GeneralEditor: Renderer{
    required init(){
        super.init()
        self.name = "generalEditor"
        self.icon = "pencil.circle.fill"
    }
    override func canDisplayResultSet(items: [DataItem]) -> Bool{
        return items.count == 1
    }
}

class GeneralEditorConfig: RenderConfig{
    
    @objc dynamic var type: String? = "generalEditor"
    @objc dynamic var _groups: String? = nil
    
    let readOnly = List<String>()
    let excluded = List<String>()
    
    var groups: [String:[String]]? {
        if self._groups != nil{
            if let groups:[String:[String]] = renderCache.get(self._groups!) {
                return groups
            }
            else if let description = self._groups {
                if let groups:[String:[String]] = unserialize(description) {
                    renderCache.set(description, groups)
                    return groups
                }
            }
            return nil
        }
        else{
            return nil
        }
    }
    
    public func allGroupValues() -> [String]{
        if let all_groups = self.groups {
            return all_groups.values.flatMap{ Array($0)}
        }
        else {
            return []
        }
    }

    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            
            decodeIntoList(decoder, "readOnly", self.readOnly)
            decodeIntoList(decoder, "excluded", self.excluded)

            if let parsedJSON:[String:AnyCodable] = try decoder.decodeIfPresent("groups") {
                self._groups = String(
                    data: try! MemriJSONEncoder.encode(parsedJSON), encoding: .utf8)!
            }
            
            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ generalEditorConfig:GeneralEditorConfig) {
        self.type = generalEditorConfig.type ?? self.type
        
        if let otherGroups = generalEditorConfig.groups, otherGroups.count > 0 {
            var groups = self.groups ?? [:]
            for (key, value) in otherGroups {
                groups[key] = value
            }
            
            self._groups = serialize(AnyCodable(groups))
        }
        
        self.excluded.append(objectsIn: generalEditorConfig.excluded)
        self.readOnly.append(objectsIn: generalEditorConfig.readOnly)

        super.superMerge(generalEditorConfig)
    }
    
}
