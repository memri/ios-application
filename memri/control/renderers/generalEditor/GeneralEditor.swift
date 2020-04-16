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
    
    var groups: [String:[String]]? {
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

    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            
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
        self._groups = generalEditorConfig._groups ?? self._groups

        super.superMerge(generalEditorConfig)
    }
    
}
