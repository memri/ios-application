//
//  schema.swift
//  memri
//
//  Created by Ruben Daniels on 4/1/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

typealias List = RealmSwift.List

// The family of all data item classes
enum DataItemFamily: String, ClassFamily, CaseIterable {
    case note = "note"
    case label = "label"
    case photo = "photo"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case person = "person"
    case audititem = "audititem"
    case sessions = "sessions"
    case phonenumber = "phonenumber"
    case website = "website"
    case location = "location"
    case address = "address"
    case country = "country"
    case company = "company"
    case publickey = "publickey"
    case onlineprofile = "onlineprofile"
    case diet = "diet"
    case medicalcondition = "medicalcondition"
    case session = "session"
    case sessionview = "sessionview"
//    case dynamicview = "dynamicview"

    static var discriminator: Discriminator = .type
    
    var backgroundColor: Color {
        switch self{
        case .note: return Color(hex: "#93c47d")
        case .label: return Color(hex: "#93c47d")
        case .file: return Color(hex: "#93c47d")
        case .photo: return Color(hex: "#93c47d")
        case .video: return Color(hex: "#93c47d")
        case .audio: return Color(hex: "#93c47d")
        case .person: return Color(hex: "#3a5eb2")
        case .audititem: return Color(hex: "#93c47d")
        case .sessions: return Color(hex: "#93c47d")
        case .phonenumber: return Color(hex: "#eccf23")
        case .website: return Color(hex: "#3d57e2")
        case .location: return Color(hex: "#93c47d")
        case .address: return Color(hex: "#93c47d")
        case .country: return Color(hex: "#93c47d")
        case .company: return Color(hex: "#93c47d")
        case .publickey: return Color(hex: "#93c47d")
        case .onlineprofile: return Color(hex: "#93c47d")
        case .diet: return Color(hex: "#37af1c")
        case .medicalcondition: return Color(hex: "#3dc8e2")
        case .session: return Color(hex: "#93c47d")
        case .sessionview: return Color(hex: "#93c47d")
        }
    }
    
    var foregroundColor: Color {
        switch self{
        default:
            return Color(hex: "#fff")
        }
    }
    
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
        case .photo:
            (object as! RealmSwift.List<Photo>).forEach{ collection.append($0) }
        case .video:
            (object as! RealmSwift.List<Video>).forEach{ collection.append($0) }
        case .audio:
            (object as! RealmSwift.List<Audio>).forEach{ collection.append($0) }
        case .person:
            (object as! RealmSwift.List<Person>).forEach{ collection.append($0) }
        case .audititem:
            (object as! RealmSwift.List<AuditItem>).forEach{ collection.append($0) }
        case .phonenumber:
            (object as! RealmSwift.List<PhoneNumber>).forEach{ collection.append($0) }
        case .website:
            (object as! RealmSwift.List<Website>).forEach{ collection.append($0) }
        case .location:
            (object as! RealmSwift.List<Location>).forEach{ collection.append($0) }
        case .address:
            (object as! RealmSwift.List<Address>).forEach{ collection.append($0) }
        case .country:
            (object as! RealmSwift.List<Country>).forEach{ collection.append($0) }
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
//        case .dynamicview:
//            break
            //(object as! RealmSwift.List<DynamicView>).forEach{ collection.append($0) }
        }
        
        return collection
    }
    
    func getType() -> AnyObject.Type {
        switch self {
        case .note:
            return Note.self
        case .audititem:
            return AuditItem.self
        case .label:
            return Label.self
        case .file:
            return File.self
        case .photo:
            return Photo.self
        case .video:
            return Video.self
        case .audio:
            return Audio.self
        case .person:
            return Person.self
        case .phonenumber:
            return PhoneNumber.self
        case .website:
            return Website.self
        case .location:
            return Location.self
        case .address:
            return Address.self
        case .country:
            return Country.self
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
//        case .dynamicview:
//            return DynamicView.self
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
    @objc dynamic var attributedContent:String? = nil

    override var genericType:String { "note" }
    
    let writtenBy = List<DataItem>()
    let sharedWith = List<DataItem>()
    let comments = List<DataItem>()
    
    override var computedTitle:String {
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
            attributedContent = try decoder.decodeIfPresent("attributedContent") ?? attributedContent
            
            try! self.superDecode(from: decoder)
        }
    }
}

class PhoneNumber:DataItem{
    override var genericType:String { "phonenumber" }
    // mobile/landline
    @objc dynamic var type:String? = nil
    @objc dynamic var number:String? = nil
    
    override var computedTitle:String {
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
    
    override var computedTitle:String {
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
    
    let latitude = RealmOptional<Double>()
    let longitude = RealmOptional<Double>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value

            try! self.superDecode(from: decoder)
        }
    }
}

class Country:DataItem {
    override var genericType:String { "country" }
    
    @objc dynamic var name:String? = nil
    @objc dynamic var flag:File? = nil // or Image ??
    @objc dynamic var location:Location? = nil
    
    override var computedTitle:String {
        return "\(name ?? "")"
    }
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            flag = try decoder.decodeIfPresent("flag") ?? flag
            location = try decoder.decodeIfPresent("location") ?? location

            try! self.superDecode(from: decoder)
        }
    }
}

class Address:DataItem {
    override var genericType:String { "address" }
    
    @objc dynamic var type:String? = nil
    @objc dynamic var country:Country? = nil
    @objc dynamic var city:String? = nil
    @objc dynamic var street:String? = nil
    @objc dynamic var state:String? = nil
    @objc dynamic var postalCode:String? = nil
    @objc dynamic var location:Location? = nil
    
    override var computedTitle:String {
        return """
        \(street ?? "")
        \(city ?? "")
        \(postalCode ?? ""), \(state ?? "")
        \(country?.computedTitle ?? "")
        """
    }
    
    required init () {
        super.init()
        
        // TODO:Refactor when any of the fields change, location should be reset
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            country = try decoder.decodeIfPresent("country") ?? country
            city = try decoder.decodeIfPresent("city") ?? city
            state = try decoder.decodeIfPresent("state") ?? state
            street = try decoder.decodeIfPresent("street") ?? street
            postalCode = try decoder.decodeIfPresent("postalCode") ?? postalCode
            location = try decoder.decodeIfPresent("location") ?? location

            try! self.superDecode(from: decoder)
        }
    }
}

class Company: DataItem{
    override var genericType:String { "company" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    
    override var computedTitle:String {
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
    
    override var computedTitle:String {
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

    override var computedTitle:String {
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
    
    override var computedTitle:String {
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
    let addresses = List<Address>()
    let publicKeys = List<PublicKey>()
    let onlineProfiles = List<OnlineProfile>()
    let diets = List<Diet>()
    let medicalConditions = List<MedicalCondition>()
    
    override var computedTitle:String {
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

class AuditItem:DataItem {
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var genericType:String { "audititem" }
    
    override var computedTitle:String {
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
    
    override var computedTitle:String {
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

// TODO Refactor: can this inherit from a Media class?
class Photo:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    override var genericType:String { "photo" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<Person>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            file = try decoder.decodeIfPresent("file") ?? file
            width.value = try decoder.decodeIfPresent("width") ?? width.value
            height.value = try decoder.decodeIfPresent("height") ?? height.value
            
            decodeIntoList(decoder, "includes", self.includes)
            
            try! self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Video:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    override var genericType:String { "video" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<DataItem>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            file = try decoder.decodeIfPresent("file") ?? file
            width.value = try decoder.decodeIfPresent("width") ?? width.value
            height.value = try decoder.decodeIfPresent("height") ?? height.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            
            decodeIntoList(decoder, "includes", self.includes)
            
            try! self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Audio:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let bitrate = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    override var genericType:String { "video" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<DataItem>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            file = try decoder.decodeIfPresent("file") ?? file
            bitrate.value = try decoder.decodeIfPresent("bitrate") ?? bitrate.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            
            decodeIntoList(decoder, "includes", self.includes)
            
            try! self.superDecode(from: decoder)
        }
    }
}
