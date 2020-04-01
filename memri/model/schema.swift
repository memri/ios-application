//
//  schema.swift
//  memri
//
//  Created by Ruben Daniels on 4/1/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

// The family of all data item classes
enum DataItemFamily: String, ClassFamily {
    case note = "note"
    case logitem = "logitem"

    static var discriminator: Discriminator = .type

    func getType() -> DataItem.Type {
        switch self {
        case .note:
            return Note.self
        case .logitem:
            return LogItem.self
        }
    }
}

//// CHALLENGE 1: Nested Heterogeneous Array Decoded.
//required init(from decoder: Decoder) throws {
//  let container = try decoder.container(keyedBy: PersonCodingKeys.self)
//  name = try container.decode(String.self, forKey: .name)
//  pets = try container.decode(family: DataItemFamily.self, forKey: .pets)
//}

// completion(try JSONDecoder().decode(family: DataItemFamily.self, from: data))

class Note:DataItem {
    @objc dynamic var title:String? = nil
    @objc dynamic var content:String? = nil
    override var type:String { "note" }
    
    let writtenBy = List<DataItem>()
    let sharedWith = List<DataItem>()
    let comments = List<DataItem>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            content = try decoder.decodeIfPresent("content") ?? content
        }
        
        try! self.initFomJSON(from: decoder)
    }
}

class LogItem:DataItem {
    @objc dynamic var date:Int = 0
    @objc dynamic var content:String? = nil
    override var type:String { "logitem" }
    
    let appliesTo = List<DataItem>()
}
