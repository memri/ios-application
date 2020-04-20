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
    case label = "label"
    case file = "file"
    case person = "person"
    case logitem = "logitem"
    case sessions = "sessions"
    case session = "session"
    case sessionview = "sessionview"
    case dynamicview = "dynamicview"

    static var discriminator: Discriminator = .type
    
    func getPrimaryKey() -> String {
        return self.getType().primaryKey() ?? ""
    }

    func getCollection(_ object:Any) -> [DataItem] {
        var collection:[DataItem] = []
        
        switch self {
        case .note:
            (object as! RealmSwift.List<Note>).forEach{ collection.append($0) }
        case .label:
            (object as! RealmSwift.List<Label>).forEach{ collection.append($0) }
        case .file:
            (object as! RealmSwift.List<File>).forEach{ collection.append($0) }
        case .person:
            (object as! RealmSwift.List<Person>).forEach{ collection.append($0) }
        case .logitem:
            (object as! RealmSwift.List<LogItem>).forEach{ collection.append($0) }
        case .sessions:
            (object as! RealmSwift.List<Session>).forEach{ collection.append($0) }
        case .session:
            (object as! RealmSwift.List<Session>).forEach{ collection.append($0) }
        case .sessionview:
            (object as! RealmSwift.List<SessionView>).forEach{ collection.append($0) }
        case .dynamicview:
            break
            //(object as! RealmSwift.List<DynamicView>).forEach{ collection.append($0) }
        }
        
        return collection
    }
    
    func getType() -> AnyObject.Type {
        switch self {
        case .note:
            return Note.self
        case .logitem:
            return LogItem.self
        case .label:
            return Label.self
        case .file:
            return File.self
        case .person:
            return Person.self
        case .sessions:
            return Sessions.self
        case .session:
            return Session.self
        case .sessionview:
            return SessionView.self
        case .dynamicview:
            return DynamicView.self
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
    
    override var computeTitle:String {
        return "\(title ?? "")"
    }
    
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
    @objc dynamic var firstName:String? = nil
    @objc dynamic var lastName:String? = nil
    let age = RealmOptional<Double>()
    override var type:String { "person" }
    @objc dynamic var profilePicture:File? = nil
    
    let relations = List<Person>()
    
    override var computeTitle:String {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            firstName = try decoder.decodeIfPresent("firstName") ?? firstName
            lastName = try decoder.decodeIfPresent("lastName") ?? lastName
            age.value = try decoder.decodeIfPresent("age") ?? age.value
            profilePicture = try decoder.decodeIfPresent("profilePicture") ?? profilePicture
            
            decodeIntoList(decoder, "relations", self.relations)
            
            try! self.superDecode(from: decoder)
        }
    }
}

class LogItem:DataItem {
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var type:String { "logitem" }
    
    override var computeTitle:String {
        return "Logged \(action ?? "unknown action") on \(date?.description ?? "")"
    }
    
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
    
    override var computeTitle:String {
        return name
    }
    
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
