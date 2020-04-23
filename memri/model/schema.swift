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
    case phonenumber = "phonenumber"
    case website = "website"
    case location = "location"
    case company = "company"
    case publickey = "publickey"
    case onlineprofile = "onlineprofile"
    case diet = "diet"
    case medicalcondition = "medicalcondition"
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
        case .phonenumber:
            (object as! RealmSwift.List<PhoneNumber>).forEach{ collection.append($0) }
        case .website:
            (object as! RealmSwift.List<Website>).forEach{ collection.append($0) }
        case .location:
            (object as! RealmSwift.List<Location>).forEach{ collection.append($0) }
        case .company:
            (object as! RealmSwift.List<Company>).forEach{ collection.append($0) }
        case .publickey:
            (object as! RealmSwift.List<PublicKey>).forEach{ collection.append($0) }
        case .onlineprofile:
            (object as! RealmSwift.List<OnlineProfile>).forEach{ collection.append($0) }
        case .diet:
            (object as! RealmSwift.List<Diet>).forEach{ collection.append($0) }
        case .medicalcondition:
            (object as! RealmSwift.List<MedicalCondition>).forEach{ collection.append($0) }
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
        case .phonenumber:
            return PhoneNumber.self
        case .website:
            return Website.self
        case .location:
            return Location.self
        case .company:
            return Company.self
        case .publickey:
            return PublicKey.self
        case .onlineprofile:
            return OnlineProfile.self
        case .diet:
            return Diet.self
        case .medicalcondition:
            return MedicalCondition.self
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
    override var genericType:String { "note" }
    
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

class PhoneNumber:DataItem{
    override var genericType:String { "phonenumber" }
    // mobile/landline
    @objc dynamic var type:String? = nil
    @objc dynamic var number:String? = nil
    
    override var computeTitle:String {
        return number ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            number = try decoder.decodeIfPresent("number") ?? number

            try! self.superDecode(from: decoder)
        }
    }
}

class Website:DataItem{
    override var genericType:String { "website" }
    // blog portifolio website
    @objc dynamic var type:String? = nil
    @objc dynamic var url:String? = nil
    
    override var computeTitle:String {
        return url ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            url = try decoder.decodeIfPresent("url") ?? url

            try! self.superDecode(from: decoder)
        }
    }
}

class Location:DataItem{
    override var genericType:String { "location" }
    // country/adress/etc.
    @objc dynamic var type:String? = nil
    @objc dynamic var country:String? = nil
    @objc dynamic var town:String? = nil
    @objc dynamic var street:String? = nil
    let streetNr = RealmOptional<Int>()
    @objc dynamic var postalCode:String? = nil
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            country = try decoder.decodeIfPresent("country") ?? country
            town = try decoder.decodeIfPresent("town") ?? town
            street = try decoder.decodeIfPresent("street") ?? street
            streetNr.value = try decoder.decodeIfPresent("streetNr") ?? streetNr.value
            postalCode = try decoder.decodeIfPresent("postalCode") ?? postalCode

            try! self.superDecode(from: decoder)
        }
    }
}

class Company: DataItem{
    override var genericType:String { "company" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    
    override var computeTitle:String {
        return name ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name

            try! self.superDecode(from: decoder)
        }
    }
}

class PublicKey: DataItem{
    override var genericType:String { "publickey" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    @objc dynamic var key:String? = nil
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name
            key = try decoder.decodeIfPresent("key") ?? key

            try! self.superDecode(from: decoder)
        }
    }
}

class OnlineProfile: DataItem{
    override var genericType:String { "onlineprofile" }
    @objc dynamic var type:String? = nil
    @objc dynamic var handle:String? = nil
    
    override var computeTitle:String {
        return handle ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            handle = try decoder.decodeIfPresent("handle") ?? handle

            try! self.superDecode(from: decoder)
        }
    }
}

class Diet: DataItem{
    override var genericType:String { "diet" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    let additions = List<String>()

    override var computeTitle:String {
        return name ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name
            
            decodeIntoList(decoder, "additions", self.additions)

            try! self.superDecode(from: decoder)
        }
    }
}

class MedicalCondition: DataItem{
    override var genericType:String { "medicalcondition" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    
    override var computeTitle:String {
        return name ?? ""
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name

            try! self.superDecode(from: decoder)
        }
    }
}

class Person:DataItem {
    @objc dynamic var firstName:String? = nil
    @objc dynamic var lastName:String? = nil
    @objc dynamic var birthDate:Date? = nil
    @objc dynamic var gender:String? = nil
    @objc dynamic var sexualOrientation:String? = nil
    let height = RealmOptional<Double>()
    let shoulderWidth = RealmOptional<Double>()
    let armLength = RealmOptional<Double>()

    let age = RealmOptional<Double>()
    override var genericType:String { "person" }
    @objc dynamic var profilePicture:File? = nil
    
    let relations = List<Person>()
    let phoneNumbers = List<PhoneNumber>()
    let websites = List<Website>()
    //TODO
//    let placeOfBirth = List<Location>()
    let companies = List<Company>()
    let addresses = List<Location>()
    let publicKeys = List<PublicKey>()
    let onlineProfiles = List<OnlineProfile>()
    let diets = List<Diet>()
    let medicalConditions = List<MedicalCondition>()

    
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
            birthDate = try decoder.decodeIfPresent("birthDate") ?? birthDate
            gender = try decoder.decodeIfPresent("gender") ?? gender
            sexualOrientation = try decoder.decodeIfPresent("sexualOrientation") ?? sexualOrientation
            
            height.value = try decoder.decodeIfPresent("height") ?? height.value
            shoulderWidth.value = try decoder.decodeIfPresent("shoulderWidth") ?? shoulderWidth.value
            armLength.value = try decoder.decodeIfPresent("armLength") ?? armLength.value
            age.value = try decoder.decodeIfPresent("age") ?? age.value
            profilePicture = try decoder.decodeIfPresent("profilePicture") ?? profilePicture
            
            decodeIntoList(decoder, "relations", self.relations)
            decodeIntoList(decoder, "phoneNumbers", self.phoneNumbers)
            decodeIntoList(decoder, "websites", self.websites)
            decodeIntoList(decoder, "companies", self.companies)
            decodeIntoList(decoder, "addresses", self.addresses)
            decodeIntoList(decoder, "publicKeys", self.publicKeys)
            decodeIntoList(decoder, "onlineProfiles", self.onlineProfiles)
            decodeIntoList(decoder, "diets", self.diets)
            decodeIntoList(decoder, "medicalConditions", self.medicalConditions)
            
            try! self.superDecode(from: decoder)
        }
    }
}

class LogItem:DataItem {
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var genericType:String { "logitem" }
    
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
    override var genericType:String { "label" }
    
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
