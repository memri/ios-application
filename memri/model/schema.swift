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
    case person = "person"
    case logitem = "logitem"
    case label = "label"
    case sessions = "sessions"
    case session = "session"
    case sessionview = "sessionview"
    case dynamicview = "dynamicview"

    static var discriminator: Discriminator = .type
    
    func getPrimaryKey() -> String {
        return self.getType().primaryKey() ?? ""
    }

    func getType() -> AnyObject.Type {
        switch self {
        case .note:
            return Note.self
        case .logitem:
            return LogItem.self
        case .label:
            return Label.self
        case .sessions:
            return Sessions.self
        case .session:
            return Session.self
        case .sessionview:
            return SessionView.self
        case .dynamicview:
            return DynamicView.self
        case .person:
            return Person.self
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
            
            try! self.superDecode(from: decoder)
        }
    }
}

class Person:DataItem {
    @objc dynamic var title:String? = nil
    @objc dynamic var content:String? = nil
    override var type:String { "person" }
    
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
            
            try! self.superDecode(from: decoder)
        }
    }
}

class LogItem:DataItem {
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var type:String { "logitem" }
    
    let appliesTo = List<DataItem>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            contents = try decoder.decodeIfPresent("contents") ?? contents
            action = try decoder.decodeIfPresent("action") ?? action
            
            decodeIntoList(decoder, "appliesTo", self.appliesTo)
            
            try! self.superDecode(from: decoder)
        }
    }
}

class Label:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var comment:String? = nil
    @objc dynamic var color:String? = nil
    override var type:String { "label" }
    
    let appliesTo = List<DataItem>() // TODO make two-way binding in realm
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            comment = try decoder.decodeIfPresent("comment") ?? comment
            color = try decoder.decodeIfPresent("color") ?? color
            
            decodeIntoList(decoder, "appliesTo", self.appliesTo)
            
            try! self.superDecode(from: decoder)
        }
    }
}
