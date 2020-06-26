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
enum ItemFamily: String, ClassFamily, CaseIterable {
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
    case typeCVUStoredDefinition = "CVUStoredDefinition"
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
        case .typeCVUStoredDefinition: return Color(hex: "#93c47d")
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
        case .typeCVUStoredDefinition: return CVUStoredDefinition.self
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
//  pets = try container.decode(family: ItemFamily.self, forKey: .pets)
//}

// completion(try JSONDecoder().decode(family: ItemFamily.self, from: data))


class Note : Item {
    @objc dynamic var title:String? = ""
    /// HTML
    @objc dynamic var content:String? = nil
    /// Text string
    @objc dynamic var textContent:String? = nil

    override var genericType:String { "Note" }
    
    let writtenBy = List<Relationship>()
    let sharedWith = List<Relationship>()
    let comments = List<Item>()
    
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
                let plainString = htmlContent.replacingOccurrences(of: "<[^>]+>", with: "",
                                                                    options: .regularExpression,
                                                                    range: nil)
                title = plainString.firstLineString()
                textContent = plainString.withoutFirstLine()
            }
        }
    }
}

class PhoneNumber:Item{
    override var genericType:String { "PhoneNumber" }
    // mobile/landline
    @objc dynamic var type:String? = nil
    @objc dynamic var number:String? = nil
    
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

class Website:Item{
    override var genericType:String { "Website" }
    // blog portifolio website
    @objc dynamic var type:String? = nil
    @objc dynamic var url:String? = nil
    
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

class Location:Item{
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

class Country:Item {
    override var genericType:String { "Country" }
    
    @objc dynamic var name:String? = nil
    @objc dynamic var flag:File? = nil // or Image ??
    @objc dynamic var location:Location? = nil
    
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

class Address:Item {
    override var genericType:String { "Address" }
    
    @objc dynamic var type:String? = nil
    @objc dynamic var country:Country? = nil
    @objc dynamic var city:String? = nil
    @objc dynamic var street:String? = nil
    @objc dynamic var state:String? = nil
    @objc dynamic var postalCode:String? = nil
    @objc dynamic var location:Location? = nil
    
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

class Company: Item{
    override var genericType:String { "Company" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    
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

class PublicKey: Item{
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

class OnlineProfile: Item{
    override var genericType:String { "OnlineProfile" }
    @objc dynamic var type:String? = nil
    @objc dynamic var handle:String? = nil
    
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

class Diet: Item{
    override var genericType:String { "Diet" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    let additions = List<String>()

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

class MedicalCondition: Item{
    override var genericType:String { "MedicalCondition" }
    @objc dynamic var type:String? = nil
    @objc dynamic var name:String? = nil
    
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

class SchemaPerson : Item {
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
            
            decodeIntoList(decoder, "websites", self.websites)
            decodeIntoList(decoder, "relations", self.relations)
            decodeIntoList(decoder, "phoneNumbers", self.phoneNumbers)
            decodeIntoList(decoder, "companies", self.companies)
            decodeIntoList(decoder, "addresses", self.addresses)
            decodeIntoList(decoder, "publicKeys", self.publicKeys)
            decodeIntoList(decoder, "onlineProfiles", self.onlineProfiles)
            decodeIntoList(decoder, "diets",  self.diets)
            decodeIntoList(decoder, "medicalConditions", self.medicalConditions)
            
            try self.superDecode(from: decoder)
        }
    }
}

class AuditItem:Item {
    @objc dynamic var date:Date? = Date()
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil
    override var genericType:String { "AuditItem" }
    
    let appliesTo = List<Relationship>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            contents = try decoder.decodeIfPresent("contents") ?? contents
            action = try decoder.decodeIfPresent("action") ?? action
            
            decodeEdges(decoder, "appliesTo", Item.self, self.appliesTo, self)
            
            try self.superDecode(from: decoder)
        }
    }
}

class Label:Item {
    @objc dynamic var name:String = ""
    @objc dynamic var comment:String? = nil
    @objc dynamic var color:String? = nil
    override var genericType:String { "Label" }
    
    let appliesTo = List<Relationship>() // TODO make two-way binding in realm
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            comment = try decoder.decodeIfPresent("comment") ?? comment
            color = try decoder.decodeIfPresent("color") ?? color
            
            decodeEdges(decoder, "appliesTo", Item.self, self.appliesTo, self)

            try self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Photo:Item {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    
    //@objc dynamic var location: Location? = nil //To add
    
    override var genericType:String { "Photo" }
    
    let includes = List<Relationship>() // e.g. person, object, recipe, etc
    
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
class Video:Item {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    override var genericType:String { "Video" }
    
    let includes = List<Relationship>() // e.g. person, object, recipe, etc
    
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
            
            decodeEdges(decoder, "includes", Item.self, self.includes, self)

            
            try self.superDecode(from: decoder)
        }
    }
}

// TODO Refactor: can this inherit from a Media class?
class Audio:Item {
    @objc dynamic var name:String = ""
    @objc dynamic var file:File? = nil
    let bitrate = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    override var genericType:String { "Audio" }
    
    let includes = List<Relationship>() // e.g. person, object, recipe, etc
    
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
            
            decodeEdges(decoder, "includes", Item.self, self.includes, self)
            
            try self.superDecode(from: decoder)
        }
    }
}

class Importer:Item{
    override var genericType:String { "Importer" }
    @objc dynamic var name:String = ""
    @objc dynamic var datatype:String = "unknown"
    @objc dynamic var icon:String = ""
    @objc dynamic var bundleImage:String = ""
    
    let runs = List<ImporterInstance>()
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            datatype = try decoder.decodeIfPresent("datatype") ?? datatype
            icon = try decoder.decodeIfPresent("icon") ?? icon
            bundleImage = try decoder.decodeIfPresent("bundleImage") ?? bundleImage
            
            decodeIntoList(decoder, "runs", self.runs)
            
            try self.superDecode(from: decoder)
        }
    }
}


class ImporterInstance:Item{
    override var genericType:String { "ImporterInstance" }
    @objc dynamic var name:String = "unknown importer run"
    @objc dynamic var datatype:String = "unknown"
    @objc dynamic var importer:Importer? = nil
    
//    let runs = List<Importer>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            datatype = try decoder.decodeIfPresent("datatype") ?? datatype
            importer = try decoder.decodeIfPresent("importer") ?? importer
            
            try self.superDecode(from: decoder)
        }
    }
}


class Indexer:Item{
    override var genericType:String { "Indexer" }
    @objc dynamic var name:String = ""
    @objc dynamic var indexerDescription:String = ""
    @objc dynamic var query:String = ""
    @objc dynamic var icon:String = ""
    @objc dynamic var bundleImage:String = ""
    
    let runs = List<IndexerInstance>() // e.g. person, object, recipe, etc
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            indexerDescription = try decoder.decodeIfPresent("indexerDescription") ?? indexerDescription
            icon = try decoder.decodeIfPresent("icon") ?? icon
            bundleImage = try decoder.decodeIfPresent("bundleImage") ?? bundleImage
            
            decodeIntoList(decoder, "runs", self.runs)
            
            try self.superDecode(from: decoder)
        }
    }
    
}

class IndexerInstance:Item{
    override var genericType:String { "IndexerInstance" }
    @objc dynamic var name:String = "unknown indexer instance"
    @objc dynamic var query:String = ""
    @objc dynamic var indexer:Indexer? = nil
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query

            indexer = try decoder.decodeIfPresent("indexer") ?? indexer

            try self.superDecode(from: decoder)
        }
    }
    
}

public class NavigationItem : Item {

    /// Used as the caption in the navigation
    @objc dynamic var title: String = ""
    /// Name of the view it opens
    @objc dynamic var view: String? = nil
    /// Defines the position in the navigation
    @objc dynamic var order: Int = 0
    
    ///     0 = Item
    ///     1 = Heading
    ///     2 = Line
    @objc dynamic var type: String = "item"
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.view = try decoder.decodeIfPresent("view") ?? self.view
            self.order = try decoder.decodeIfPresent("order") ?? self.order
            self.type = try decoder.decodeIfPresent("type") ?? self.type
        }
    }
}

public class CVUStoredDefinition : Item {
    override var genericType:String { "CVUStoredDefinition" }
    
    @objc dynamic var type: String? = nil
    @objc dynamic var name: String? = nil
    @objc dynamic var selector: String? = nil
    @objc dynamic var definition: String? = nil
    @objc dynamic var query: String? = nil
    @objc dynamic var domain: String = "user"
}

public class SessionView : Item {
   override var genericType:String { "SessionView" }

   @objc dynamic var name: String? = nil
   @objc dynamic var viewDefinition: CVUStoredDefinition? = nil
   @objc dynamic var userState: UserState? = nil
   @objc dynamic var viewArguments: ViewArguments? = nil
   @objc dynamic var datasource: Datasource? = nil // TODO refactor: fix cascading
   @objc dynamic var session: Session? = nil
}

/// Single setting object, persisted to disk
public class Setting : Item {
    /// key of the setting
    @objc dynamic var key:String = ""
    /// json value of the setting
    @objc dynamic var json:String = ""
}

/// Collection of settings that are grouped based on who defined them
class SettingCollection : Item {
    /// Type that represent who created the setting: Default/User/Device
    @objc dynamic var type:String = ""
    
    /// Setting in this collection
    let settings = List<Setting>()
}

public class SchemaSessions : Item {
    override var genericType:String { "Sessions" }
    @objc dynamic var currentSessionIndex: Int = 0
    let sessions = RealmSwift.List<Session>()
    
    required init() {
        super.init()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
            decodeIntoList(decoder, "sessions", self.sessions)
            
            try super.superDecode(from:decoder)
        }
    }
}

public class SchemaSession : Item {
    override var genericType:String { "Session" }
    @objc dynamic var name: String = ""
    @objc dynamic var currentViewIndex: Int = 0
    let views = RealmSwift.List<SessionView>() // @Published
    @objc dynamic var showFilterPanel:Bool = false
    @objc dynamic var showContextPane:Bool = false
    @objc dynamic var editMode:Bool = false
    @objc dynamic var screenshot:File? = nil
    
    required init() {
        super.init()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentViewIndex = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex
            showFilterPanel = try decoder.decodeIfPresent("showFilterPanel") ?? showFilterPanel
            showContextPane = try decoder.decodeIfPresent("showContextPane") ?? showContextPane
            editMode = try decoder.decodeIfPresent("editMode") ?? editMode
            
            decodeIntoList(decoder, "views", self.views)
            
            try super.superDecode(from: decoder)
        }
    }
}

class File : Item {
    @objc dynamic var uri:String = ""
    override var genericType:String { "File" }

    let usedBy = RealmSwift.List<Item>() // TODO make two-way binding in realm
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            uri = try decoder.decodeIfPresent("uri") ?? uri
            
            decodeIntoList(decoder, "usedBy", self.usedBy)
            
            try self.superDecode(from: decoder)
        }
    }
}

/// Item is the baseclass for all of the data clases, all functions
public class SchemaItem: Object, Codable, Identifiable, ObservableObject {
 
    /// name of the Item implementation class (E.g. "note" or "person")
    var genericType:String { "unknown" }
    
    /// uid of the Item set by the pod
    @objc dynamic var uid:Int = 0
    /// memriID of the Item
    @objc dynamic var memriID:String = Item.generateUUID()
    /// Boolean whether the Item has been deleted
    @objc dynamic var deleted:Bool = false
    /// The last version loaded from the server
    @objc dynamic var version:Int = 0
    /// Boolean whether the Item has been starred
    @objc dynamic var starred:Bool = false
    /// Creation date of the Item
    @objc dynamic var dateCreated:Date? = Date()
    /// Last modification date of the Item
    @objc dynamic var dateModified:Date? = Date()
    /// Last access date of the Item
    @objc dynamic var dateAccessed:Date? = nil
    /// Array AuditItems describing the log history of the Item
    let changelog = List<AuditItem>()
    /// Labels assigned to / associated with this Item
    let labels = List<memri.Label>()
    
    /// Object descirbing syncing information about this object like loading state, versioning, etc.
    @objc dynamic var syncState:SyncState? = SyncState()
}
