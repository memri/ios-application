//
//  DynamicView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class DynamicView: Object, ObservableObject, Codable {
 
    @objc dynamic var name:String = ""
 
    @objc dynamic var declaration:String = ""
 
    @objc dynamic var fromTemplate:String? = nil
    
    public override static func primaryKey() -> String? {
        return "name"
    }
    
    public init(_ decl:String) {
        declaration = decl
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.declaration = try decoder.decodeIfPresent("declaration") ?? self.declaration
            self.fromTemplate = try decoder.decodeIfPresent("copyFromView") ?? self.fromTemplate
        }
    }
        
    required init() {
        super.init()
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> DynamicView {
        let jsonData = try jsonDataFromFile(file, ext)
        let view:DynamicView = try MemriJSONDecoder.decode(DynamicView.self, from: jsonData)
        return view
    }
    
    public class func fromJSONString(_ json: String) throws -> DynamicView {
        let view:DynamicView = try MemriJSONDecoder.decode(DynamicView.self, from: Data(json.utf8))
        return view
    }
}
