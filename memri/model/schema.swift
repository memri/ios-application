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

public typealias List = RealmSwift.List

// The family of all data item classes
enum DataItemFamily: String, ClassFamily, CaseIterable {
    case typeNote = "Note"
    case typeLabel = "Label"
    case typePhoto = "Photo"
    case typeVideo = "Video"
    case typeAudio = "Audio"
    case typeFile = "File"
    case typePerson = "Person"
    case typeAuditItem = "AuditItem"
    case typeSessions = "Sessions"
    case typePhoneNumber = "PhoneNumber"
    case typeWebsite = "Website"
    case typeLocation = "Location"
    case typeAddress = "Address"
    case typeCountry = "Country"
    case typeCompany = "Company"
    case typePublicKey = "PublicKey"
    case typeOnlineProfile = "OnlineProfile"
    case typeDiet = "Diet"
    case typeMedicalCondition = "MedicalCondition"
    case typeSession = "Session"
    case typeSessionView = "SessionView"
    case typeStoredCVUDefinition = "ViewDSLDefinition"
    case typeImporter = "Importer"
    case typeIndexer = "Indexer"
    case typeImporterInstance = "ImporterInstance"
    case typeIndexerInstance = "IndexerInstance"

    static var discriminator: Discriminator = .type
    
    var backgroundColor: Color {
        switch self{
        case .typeNote: return Color(hex: "#93c47d")
        case .typeLabel: return Color(hex: "#93c47d")
        case .typePhoto: return Color(hex: "#93c47d")
        case .typeVideo: return Color(hex: "#93c47d")
        case .typeAudio: return Color(hex: "#93c47d")
        case .typeFile: return Color(hex: "#93c47d")
        case .typePerson: return Color(hex: "#3a5eb2")
        case .typeAuditItem: return Color(hex: "#93c47d")
        case .typeSessions: return Color(hex: "#93c47d")
        case .typePhoneNumber: return Color(hex: "#eccf23")
        case .typeWebsite: return Color(hex: "#3d57e2")
        case .typeLocation: return Color(hex: "#93c47d")
        case .typeAddress: return Color(hex: "#93c47d")
        case .typeCountry: return Color(hex: "#93c47d")
        case .typeCompany: return Color(hex: "#93c47d")
        case .typePublicKey: return Color(hex: "#93c47d")
        case .typeOnlineProfile: return Color(hex: "#93c47d")
        case .typeDiet: return Color(hex: "#37af1c")
        case .typeMedicalCondition: return Color(hex: "#3dc8e2")
        case .typeSession: return Color(hex: "#93c47d")
        case .typeSessionView: return Color(hex: "#93c47d")
        case .typeStoredCVUDefinition: return Color(hex: "#93c47d")
        case .typeImporter: return Color(hex: "#93c47d")
        case .typeIndexer: return Color(hex: "#93c47d")
        case .typeImporterInstance: return Color(hex: "#93c47d")
        case .typeIndexerInstance: return Color(hex: "#93c47d")
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
        
        if let list = object as? List<Note> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Label> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Photo> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Video> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Audio> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<File> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Person> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<AuditItem> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Sessions> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<PhoneNumber> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Website> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Location> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Address> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Country> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Company> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<PublicKey> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<OnlineProfile> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Diet> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<MedicalCondition> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Session> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<SessionView> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<CVUStoredDefinition> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Importer> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<Indexer> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<ImporterInstance> { list.forEach{ collection.append($0) } }
        else if let list = object as? List<IndexerInstance> { list.forEach{ collection.append($0) } }

        return collection
    }
    
    func getType() -> AnyObject.Type {
        switch self {
        case .typeNote: return Note.self
        case .typeLabel: return Label.self
        case .typePhoto: return Photo.self
        case .typeVideo: return Video.self
        case .typeAudio: return Audio.self
        case .typeFile: return File.self
        case .typePerson: return Person.self
        case .typeAuditItem: return AuditItem.self
        case .typeSessions: return Sessions.self
        case .typePhoneNumber: return PhoneNumber.self
        case .typeWebsite: return Website.self
        case .typeLocation: return Location.self
        case .typeAddress: return Address.self
        case .typeCountry: return Country.self
        case .typeCompany: return Company.self
        case .typePublicKey: return PublicKey.self
        case .typeOnlineProfile: return OnlineProfile.self
        case .typeDiet: return Diet.self
        case .typeMedicalCondition: return MedicalCondition.self
        case .typeSession: return Session.self
        case .typeSessionView: return SessionView.self
        case .typeStoredCVUDefinition: return CVUStoredDefinition.self
        case .typeImporter: return Importer.self
        case .typeIndexer: return Indexer.self
        case .typeImporterInstance: return ImporterInstance.self
        case .typeIndexerInstance: return IndexerInstance.self
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
    @objc dynamic var title:String? = ""
    /// HTML
    @objc dynamic var content:String? = nil
    /// Text string
    @objc dynamic var textContent:String? = nil


    override var genericType:String { "Note" }
    
    let writtenBy = List<Edge>()
    let sharedWith = List<Edge>()
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
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            try self.superDecode(from: decoder)
            if let htmlContent = content, textContent == nil || textContent == "" {
                self.textContent = htmlContent.replacingOccurrences(of: "<[^>]+>", with: "",
                                                                    options: .regularExpression,
                                                                    range: nil)
            }
        }
    }
}

class PhoneNumber:DataItem{
    override var genericType:String { "PhoneNumber" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class Website:DataItem{
    override var genericType:String { "Website" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class Location:DataItem{
    override var genericType:String { "Location" }
    
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

            try self.superDecode(from: decoder)
        }
    }
}

class Country:DataItem {
    override var genericType:String { "Country" }
    
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

            try self.superDecode(from: decoder)
        }
    }
}

class Address:DataItem {
    override var genericType:String { "Address" }
    
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

            try self.superDecode(from: decoder)
        }
    }
}

class Company: DataItem{
    override var genericType:String { "Company" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class PublicKey: DataItem{
    override var genericType:String { "PublicKey" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class OnlineProfile: DataItem{
    override var genericType:String { "OnlineProfile" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class Diet: DataItem{
    override var genericType:String { "Diet" }
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

            try self.superDecode(from: decoder)
        }
    }
}

class MedicalCondition: DataItem{
    override var genericType:String { "MedicalCondition" }
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

            try self.superDecode(from: decoder)
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
    override var genericType:String { "Person" }
    @objc dynamic var profilePicture:File? = nil
    
    let relations = List<Edge>()
    let phoneNumbers = List<Edge>()
    
    
    let websites = List<Edge>()
    //TODO
//    let placeOfBirth = List<Location>()
    let companies = List<Edge>()
    let addresses = List<Edge>()
    let publicKeys = List<Edge>()
    let onlineProfiles = List<Edge>()
    let diets = List<Edge>()
    let medicalConditions = List<Edge>()
    
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
            
            decodeEdges(decoder, "websites", Website.self, self.websites, self)
            
            decodeEdges(decoder, "relations", Person.self, self.relations, self)
            decodeEdges(decoder, "phoneNumbers", PhoneNumber.self, self.phoneNumbers, self)
            decodeEdges(decoder, "companies", Company.self, self.companies, self)
            decodeEdges(decoder, "addresses", Address.self, self.addresses, self)
            decodeEdges(decoder, "publicKeys", PublicKey.self, self.publicKeys, self)
            decodeEdges(decoder, "onlineProfiles", OnlineProfile.self, self.onlineProfiles, self)
            decodeEdges(decoder, "diets",  Diet.self, self.diets, self)
            decodeEdges(decoder, "medicalConditions", MedicalCondition.self, self.medicalConditions, self)
            
            try self.superDecode(from: decoder)
        }
    }
}

class AuditItem:DataItem {
    
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var genericType:String { "AuditItem" }
    
    override var computedTitle:String {
        return "Logged \(action ?? "unknown action") on \(date?.description ?? "")"
    }
    
    let appliesTo = List<Edge>()
    
    required init () {
        super.init()
    }
    
    convenience init(date: Date? = nil,contents: String? = nil, action: String? = nil,
                     appliesTo: [DataItem]? = nil) {
        self.init()
        self.date = date ?? self.date
        self.contents = contents ?? self.contents
        self.action = action ?? self.action
                
        if let appliesTo = appliesTo{
            let edges = appliesTo.map{ Edge(self.memriID, $0.memriID, self.genericType, $0.genericType) }
            
            let edgeName = "appliesTo"
            
//            item["~appliesTo"] =  edges
            // TODO
            self.appliesTo.append(objectsIn: edges)
//            for item in appliesTo{
//                item.changelog.append(objectsIn: edges)
//            }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            contents = try decoder.decodeIfPresent("contents") ?? contents
            action = try decoder.decodeIfPresent("action") ?? action
            
            decodeEdges(decoder, "appliesTo", DataItem.self, self.appliesTo, self)
            
            try self.superDecode(from: decoder)
        }
    }
}

class Label:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var comment:String? = nil
    @objc dynamic var color:String? = nil
    override var genericType:String { "Label" }
    
    override var computedTitle:String {
        return name
    }
    
    let appliesTo = List<Edge>() // TODO make two-way binding in realm
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            comment = try decoder.decodeIfPresent("comment") ?? comment
            color = try decoder.decodeIfPresent("color") ?? color
            
            decodeEdges(decoder, "includes", DataItem.self, self.appliesTo, self)

            
            try self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Photo:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    override var genericType:String { "Photo" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<Edge>() // e.g. person, object, recipe, etc
    
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
            
            decodeEdges(decoder, "includes", Person.self, self.includes, self)

            
            try self.superDecode(from: decoder)
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
    override var genericType:String { "Video" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<Edge>() // e.g. person, object, recipe, etc
    
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
            
            decodeEdges(decoder, "includes", DataItem.self, self.includes, self)

            
            try self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Audio:DataItem {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let bitrate = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    override var genericType:String { "Audio" }
    
    override var computedTitle:String {
        return name
    }
    
    let includes = List<Edge>() // e.g. person, object, recipe, etc
    
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
            
            decodeEdges(decoder, "includes", DataItem.self, self.includes, self)
            
            try self.superDecode(from: decoder)
        }
    }
}

class Importer:DataItem{
    override var genericType:String { "Importer" }
    @objc dynamic var name:String = ""
    @objc dynamic var datatype:String = "unknown"
    @objc dynamic var icon:String = ""
    
    let runs = List<Edge>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            datatype = try decoder.decodeIfPresent("datatype") ?? datatype
            icon = try decoder.decodeIfPresent("icon") ?? icon
            
            decodeEdges(decoder, "runs", DataItem.self, self.runs, self)
            
            try self.superDecode(from: decoder)
        }
    }
}


class ImporterInstance:DataItem{
    override var genericType:String { "ImporterInstance" }
    @objc dynamic var name:String = "unknown importer run"
    @objc dynamic var datatype:String = "unknown"

    let importer = List<Edge>()
    
//    let runs = List<Importer>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            datatype = try decoder.decodeIfPresent("datatype") ?? datatype
            decodeEdges(decoder, "importer", DataItem.self, self.importer, self)
            
            try self.superDecode(from: decoder)
        }
    }
}


class Indexer:DataItem{
    override var genericType:String { "Indexer" }
    @objc dynamic var name:String = ""
    @objc dynamic var indexerDescription:String = ""
    @objc dynamic var query:String = ""
    
    let runs = List<Edge>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            indexerDescription = try decoder.decodeIfPresent("indexerDescription") ?? indexerDescription
            
            decodeEdges(decoder, "runs", DataItem.self, self.runs, self)
            
            try self.superDecode(from: decoder)
        }
    }
    
}

class IndexerInstance:DataItem{
    override var genericType:String { "IndexerInstance" }
    @objc dynamic var name:String = "unknown indexer instance"
    @objc dynamic var indexerDescription:String = ""
    @objc dynamic var query:String = ""

    let indexer = List<Edge>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            indexerDescription = try decoder.decodeIfPresent("indexerDescription") ?? indexerDescription
            
            decodeEdges(decoder, "indexer", DataItem.self, self.indexer, self)
            
            try self.superDecode(from: decoder)
        }
    }
    
}
