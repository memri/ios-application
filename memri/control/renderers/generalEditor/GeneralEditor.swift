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
//    @objc dynamic var groups: [String:String]? = nil
//    let groups = List<[String]>()


    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.type = try decoder.decodeIfPresent("type") ?? self.type
            self.groups = try decoder.decodeIfPresent("groups") ?? self.groups

            try! self.superDecode(from: decoder)
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ generalEditorConfig:GeneralEditorConfig) {
        self.type = generalEditorConfig.type ?? self.type
        self.groups = generalEditorConfig.groups ?? self.groups

        super.superMerge(generalEditorConfig)
    }
    
}
