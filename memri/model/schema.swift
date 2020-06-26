//
//  WARNING: THIS FILE IS AUTOGENERATED; DO NOT CHANGE.
//  Visit https://gitlab.memri.io/memri/schema to learn more
//
//  schema.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public typealias List = RealmSwift.List

// The family of all data item classes
enum DataItemFamily: String, ClassFamily, CaseIterable {
    case typeItem = "Item"
    case typeAuditItem = "AuditItem"
    case typeCVUStoredDefinition = "CVUStoredDefinition"
    case typeCompany = "Company"
    case typeCreativeWork = "CreativeWork"
    case typeDigitalDocument = "DigitalDocument"
    case typeComment = "Comment"
    case typeNote = "Note"
    case typeMediaObject = "MediaObject"
    case typeAudio = "Audio"
    case typePhoto = "Photo"
    case typeVideo = "Video"
    case typeDiet = "Diet"
    case typeDownloader = "Downloader"
    case typeFile = "File"
    case typeImporter = "Importer"
    case typeImporterInstance = "ImporterInstance"
    case typeIndexer = "Indexer"
    case typeIndexerInstance = "IndexerInstance"
    case typeLabel = "Label"
    case typeLocation = "Location"
    case typeAddress = "Address"
    case typeCountry = "Country"
    case typeGeoCoordinates = "GeoCoordinates"
    case typeLogItem = "LogItem"
    case typeMedicalCondition = "MedicalCondition"
    case typeNavigationItem = "NavigationItem"
    case typeOnlineProfile = "OnlineProfile"
    case typePerson = "Person"
    case typePhoneNumber = "PhoneNumber"
    case typePublicKey = "PublicKey"
    case typeSession = "Session"
    case typeSessionView = "SessionView"
    case typeSessions = "Sessions"
    case typeSetting = "Setting"
    case typeSettingsCollection = "SettingsCollection"
    case typeSyncState = "SyncState"
    case typeWebsite = "Website"

    static var discriminator: Discriminator = .type

    var backgroundColor: Color {
        switch self {
        case .typeItem: return Color(hex: "#93c47d")
        case .typeAuditItem: return Color(hex: "#93c47d")
        case .typeCVUStoredDefinition: return Color(hex: "#93c47d")
        case .typeCompany: return Color(hex: "#93c47d")
        case .typeCreativeWork: return Color(hex: "#93c47d")
        case .typeDigitalDocument: return Color(hex: "#93c47d")
        case .typeComment: return Color(hex: "#93c47d")
        case .typeNote: return Color(hex: "#93c47d")
        case .typeMediaObject: return Color(hex: "#93c47d")
        case .typeAudio: return Color(hex: "#93c47d")
        case .typePhoto: return Color(hex: "#93c47d")
        case .typeVideo: return Color(hex: "#93c47d")
        case .typeDiet: return Color(hex: "#93c47d")
        case .typeDownloader: return Color(hex: "#93c47d")
        case .typeFile: return Color(hex: "#93c47d")
        case .typeImporter: return Color(hex: "#93c47d")
        case .typeImporterInstance: return Color(hex: "#93c47d")
        case .typeIndexer: return Color(hex: "#93c47d")
        case .typeIndexerInstance: return Color(hex: "#93c47d")
        case .typeLabel: return Color(hex: "#93c47d")
        case .typeLocation: return Color(hex: "#93c47d")
        case .typeAddress: return Color(hex: "#93c47d")
        case .typeCountry: return Color(hex: "#93c47d")
        case .typeGeoCoordinates: return Color(hex: "#93c47d")
        case .typeLogItem: return Color(hex: "#93c47d")
        case .typeMedicalCondition: return Color(hex: "#93c47d")
        case .typeNavigationItem: return Color(hex: "#93c47d")
        case .typeOnlineProfile: return Color(hex: "#93c47d")
        case .typePerson: return Color(hex: "#93c47d")
        case .typePhoneNumber: return Color(hex: "#93c47d")
        case .typePublicKey: return Color(hex: "#93c47d")
        case .typeSession: return Color(hex: "#93c47d")
        case .typeSessionView: return Color(hex: "#93c47d")
        case .typeSessions: return Color(hex: "#93c47d")
        case .typeSetting: return Color(hex: "#93c47d")
        case .typeSettingsCollection: return Color(hex: "#93c47d")
        case .typeSyncState: return Color(hex: "#93c47d")
        case .typeWebsite: return Color(hex: "#93c47d")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .typeItem: return Color(hex: "#fff")
        case .typeAuditItem: return Color(hex: "#fff")
        case .typeCVUStoredDefinition: return Color(hex: "#fff")
        case .typeCompany: return Color(hex: "#fff")
        case .typeCreativeWork: return Color(hex: "#fff")
        case .typeDigitalDocument: return Color(hex: "#fff")
        case .typeComment: return Color(hex: "#fff")
        case .typeNote: return Color(hex: "#fff")
        case .typeMediaObject: return Color(hex: "#fff")
        case .typeAudio: return Color(hex: "#fff")
        case .typePhoto: return Color(hex: "#fff")
        case .typeVideo: return Color(hex: "#fff")
        case .typeDiet: return Color(hex: "#fff")
        case .typeDownloader: return Color(hex: "#fff")
        case .typeFile: return Color(hex: "#fff")
        case .typeImporter: return Color(hex: "#fff")
        case .typeImporterInstance: return Color(hex: "#fff")
        case .typeIndexer: return Color(hex: "#fff")
        case .typeIndexerInstance: return Color(hex: "#fff")
        case .typeLabel: return Color(hex: "#fff")
        case .typeLocation: return Color(hex: "#fff")
        case .typeAddress: return Color(hex: "#fff")
        case .typeCountry: return Color(hex: "#fff")
        case .typeGeoCoordinates: return Color(hex: "#fff")
        case .typeLogItem: return Color(hex: "#fff")
        case .typeMedicalCondition: return Color(hex: "#fff")
        case .typeNavigationItem: return Color(hex: "#fff")
        case .typeOnlineProfile: return Color(hex: "#fff")
        case .typePerson: return Color(hex: "#fff")
        case .typePhoneNumber: return Color(hex: "#fff")
        case .typePublicKey: return Color(hex: "#fff")
        case .typeSession: return Color(hex: "#fff")
        case .typeSessionView: return Color(hex: "#fff")
        case .typeSessions: return Color(hex: "#fff")
        case .typeSetting: return Color(hex: "#fff")
        case .typeSettingsCollection: return Color(hex: "#fff")
        case .typeSyncState: return Color(hex: "#fff")
        case .typeWebsite: return Color(hex: "#fff")
        }
    }

    func getPrimaryKey() -> String {
        return self.getType().primaryKey() ?? ""
    }

    func getType() -> AnyObject.Type {
        switch self {
        case .typeItem: return Item.self
        case .typeAuditItem: return AuditItem.self
        case .typeCVUStoredDefinition: return CVUStoredDefinition.self
        case .typeCompany: return Company.self
        case .typeCreativeWork: return CreativeWork.self
        case .typeDigitalDocument: return DigitalDocument.self
        case .typeComment: return Comment.self
        case .typeNote: return Note.self
        case .typeMediaObject: return MediaObject.self
        case .typeAudio: return Audio.self
        case .typePhoto: return Photo.self
        case .typeVideo: return Video.self
        case .typeDiet: return Diet.self
        case .typeDownloader: return Downloader.self
        case .typeFile: return File.self
        case .typeImporter: return Importer.self
        case .typeImporterInstance: return ImporterInstance.self
        case .typeIndexer: return Indexer.self
        case .typeIndexerInstance: return IndexerInstance.self
        case .typeLabel: return Label.self
        case .typeLocation: return Location.self
        case .typeAddress: return Address.self
        case .typeCountry: return Country.self
        case .typeGeoCoordinates: return GeoCoordinates.self
        case .typeLogItem: return LogItem.self
        case .typeMedicalCondition: return MedicalCondition.self
        case .typeNavigationItem: return NavigationItem.self
        case .typeOnlineProfile: return OnlineProfile.self
        case .typePerson: return Person.self
        case .typePhoneNumber: return PhoneNumber.self
        case .typePublicKey: return PublicKey.self
        case .typeSession: return Session.self
        case .typeSessionView: return SessionView.self
        case .typeSessions: return Sessions.self
        case .typeSetting: return Setting.self
        case .typeSettingsCollection: return SettingsCollection.self
        case .typeSyncState: return SyncState.self
        case .typeWebsite: return Website.self
        }
    }
}

/// The most generic type of item.
class Item {
    @objc dynamic var dateAccessed:Date? = Date()
    @objc dynamic var dateCreated:Date? = Date()
    @objc dynamic var dateModified:Date? = Date()
    @objc dynamic var description:String? = nil
    @objc dynamic var functions:String? = nil
    @objc dynamic var genericType:String? = nil
    @objc dynamic var name:String? = nil
    @objc dynamic var syncState:SyncState? = SyncState()

    let memriID = Item.generateUUID()
    let version = 0

    let changelog = List<AuditItem>()
    let deleted = List<bool>()
    let labels = List<Label>()
    let starred = List<bool>()

    override var genericType:String { "Item" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            dateAccessed = try decoder.decodeIfPresent("dateAccessed") ?? dateAccessed
            dateCreated = try decoder.decodeIfPresent("dateCreated") ?? dateCreated
            dateModified = try decoder.decodeIfPresent("dateModified") ?? dateModified
            description = try decoder.decodeIfPresent("description") ?? description
            functions = try decoder.decodeIfPresent("functions") ?? functions
            genericType = try decoder.decodeIfPresent("genericType") ?? genericType
            name = try decoder.decodeIfPresent("name") ?? name
            one_syncState = try decoder.decodeIfPresent("one_syncState") ?? one_syncState

            memriID.value = try decoder.decodeIfPresent("memriID") ?? memriID.value
            version.value = try decoder.decodeIfPresent("version") ?? version.value

            decodeIntoList(decoder, "changelog", self.changelog)
            decodeIntoList(decoder, "deleted", self.deleted)
            decodeIntoList(decoder, "labels", self.labels)
            decodeIntoList(decoder, "starred", self.starred)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class AuditItem:Item {
    @objc dynamic var date:Date? = nil
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil

    let appliesTo = List<Relationship>()

    override var genericType:String { "AuditItem" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            contents = try decoder.decodeIfPresent("contents") ?? contents
            action = try decoder.decodeIfPresent("action") ?? action

    decodeRelationships(decoder, "appliesTo", Item.self, self.appliesTo, self)
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class CVUStoredDefinition:Item {
    @objc dynamic var definition:String? = nil
    @objc dynamic var domain:String? = nil
    @objc dynamic var query:String? = nil
    @objc dynamic var selector:String? = nil
    @objc dynamic var type:String? = nil

    override var genericType:String { "CVUStoredDefinition" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            definition = try decoder.decodeIfPresent("definition") ?? definition
            domain = try decoder.decodeIfPresent("domain") ?? domain
            query = try decoder.decodeIfPresent("query") ?? query
            selector = try decoder.decodeIfPresent("selector") ?? selector
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// A business corporation.
class Company:Item {
    @objc dynamic var type:String? = nil

    override var genericType:String { "Company" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// The most generic kind of creative work, including books, movies, photographs, software programs, etc.
class CreativeWork:Item {
    @objc dynamic var abstract:String? = nil
    @objc dynamic var datePublished:Date? = nil
    @objc dynamic var keywords:String? = nil
    @objc dynamic var license:String? = nil
    @objc dynamic var text:String? = nil

    let associatedMedia = List<MediaObject>()
    let audio = List<Audio>()
    let citation = List<CreativeWork>()
    let contentLocation = List<Location>()
    let locationCreated = List<Location>()
    let video = List<Video>()
    let writtenBy = List<Person>()

    override var genericType:String { "CreativeWork" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keywords = try decoder.decodeIfPresent("keywords") ?? keywords
            license = try decoder.decodeIfPresent("license") ?? license
            text = try decoder.decodeIfPresent("text") ?? text

            decodeIntoList(decoder, "associatedMedia", self.associatedMedia)
            decodeIntoList(decoder, "audio", self.audio)
            decodeIntoList(decoder, "citation", self.citation)
            decodeIntoList(decoder, "contentLocation", self.contentLocation)
            decodeIntoList(decoder, "locationCreated", self.locationCreated)
            decodeIntoList(decoder, "video", self.video)
            decodeIntoList(decoder, "writtenBy", self.writtenBy)

            try self.superDecode(from: decoder)
        }
    }
}

/// An electronic file or document.
class DigitalDocument:Item {
    override var genericType:String { "DigitalDocument" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// A comment.
class Comment:Item {
    override var genericType:String { "Comment" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// A file containing a note.
class Note:Item {
    @objc dynamic var title:String? = nil
    @objc dynamic var content:String? = nil

    let comments = List<Comment>()

    override var genericType:String { "Note" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            content = try decoder.decodeIfPresent("content") ?? content

            decodeIntoList(decoder, "comments", self.comments)

            try self.superDecode(from: decoder)
        }
    }
}

/// A media object, such as an image, video, or audio object embedded in a web page or a downloadable dataset i.e. DataDownload. Note that a creative work may have many media objects associated with it on the same web page. For example, a page about a single song (MusicRecording) may have a music video (VideoObject), and a high and low bandwidth audio stream (2 AudioObject's).
class MediaObject:Item {
    @objc dynamic var endTime:Date? = nil
    @objc dynamic var file:File? = nil
    @objc dynamic var fileLocation:String? = nil
    @objc dynamic var fileSize:String? = nil
    @objc dynamic var startTime:Date? = nil

    let bitrate = RealmOptional<Int>()
    let duration = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    let includes = List<Relationship>()
    let width = RealmOptional<Int>()

    override var genericType:String { "MediaObject" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime
            one_file = try decoder.decodeIfPresent("one_file") ?? one_file
            fileLocation = try decoder.decodeIfPresent("fileLocation") ?? fileLocation
            fileSize = try decoder.decodeIfPresent("fileSize") ?? fileSize
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime

            bitrate.value = try decoder.decodeIfPresent("bitrate") ?? bitrate.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            height.value = try decoder.decodeIfPresent("height") ?? height.value
    decodeRelationships(decoder, "includes", Item.self, self.includes, self)            width.value = try decoder.decodeIfPresent("width") ?? width.value

            try self.superDecode(from: decoder)
        }
    }
}

/// An audio file.
class Audio:Item {
    @objc dynamic var caption:String? = nil
    @objc dynamic var transcript:String? = nil

    override var genericType:String { "Audio" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript

            try self.superDecode(from: decoder)
        }
    }
}

/// An image file.
class Photo:Item {
    @objc dynamic var caption:String? = nil
    @objc dynamic var exifData:String? = nil
    @objc dynamic var thumbnail:String? = nil

    override var genericType:String { "Photo" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            thumbnail = try decoder.decodeIfPresent("thumbnail") ?? thumbnail

            try self.superDecode(from: decoder)
        }
    }
}

/// A video file.
class Video:Item {
    @objc dynamic var caption:String? = nil
    @objc dynamic var exifData:String? = nil
    @objc dynamic var thumbnail:String? = nil

    override var genericType:String { "Video" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            thumbnail = try decoder.decodeIfPresent("thumbnail") ?? thumbnail

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Diet:Item {
    @objc dynamic var type:String? = nil
    @objc dynamic var additions:String? = nil

    override var genericType:String { "Diet" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            additions = try decoder.decodeIfPresent("additions") ?? additions

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Downloader:Item {
    override var genericType:String { "Downloader" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class File:Item {
    @objc dynamic var uri:String? = nil

    let usedBy = List<Relationship>()

    override var genericType:String { "File" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            uri = try decoder.decodeIfPresent("uri") ?? uri

    decodeRelationships(decoder, "usedBy", Item.self, self.usedBy, self)
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Importer:Item {
    @objc dynamic var dataType:String? = nil
    @objc dynamic var icon:String? = nil
    @objc dynamic var bundleImage:String? = nil
    @objc dynamic var runs:String? = nil

    override var genericType:String { "Importer" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            dataType = try decoder.decodeIfPresent("dataType") ?? dataType
            icon = try decoder.decodeIfPresent("icon") ?? icon
            bundleImage = try decoder.decodeIfPresent("bundleImage") ?? bundleImage
            runs = try decoder.decodeIfPresent("runs") ?? runs

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class ImporterInstance:Item {
    @objc dynamic var dataType:String? = nil

    let importer = List<Importer>()

    override var genericType:String { "ImporterInstance" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            dataType = try decoder.decodeIfPresent("dataType") ?? dataType

            decodeIntoList(decoder, "importer", self.importer)

            try self.superDecode(from: decoder)
        }
    }
}

/// An indexer enhances your personal data by inferring facts over existing data and adding those to the database.
class Indexer:Item {
    override var genericType:String { "Indexer" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// A run of a certain Indexer.
class IndexerInstance:Item {
    override var genericType:String { "IndexerInstance" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Label:Item {
    @objc dynamic var comment:String? = nil
    @objc dynamic var color:String? = nil

    let appliesTo = List<Relationship>()

    override var genericType:String { "Label" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            comment = try decoder.decodeIfPresent("comment") ?? comment
            color = try decoder.decodeIfPresent("color") ?? color

    decodeRelationships(decoder, "appliesTo", Item.self, self.appliesTo, self)
            try self.superDecode(from: decoder)
        }
    }
}

/// The location of something.
class Location:Item {
    let latitude = RealmOptional<Double>()
    let longitude = RealmOptional<Double>()

    override var genericType:String { "Location" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value

            try self.superDecode(from: decoder)
        }
    }
}

/// A postal address.
class Address:Item {
    @objc dynamic var city:String? = nil
    @objc dynamic var country:Country? = nil
    @objc dynamic var location:Location? = nil
    @objc dynamic var postalCode:String? = nil
    @objc dynamic var state:String? = nil
    @objc dynamic var street:String? = nil
    @objc dynamic var type:String? = nil

    override var genericType:String { "Address" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            city = try decoder.decodeIfPresent("city") ?? city
            one_country = try decoder.decodeIfPresent("one_country") ?? one_country
            one_location = try decoder.decodeIfPresent("one_location") ?? one_location
            postalCode = try decoder.decodeIfPresent("postalCode") ?? postalCode
            state = try decoder.decodeIfPresent("state") ?? state
            street = try decoder.decodeIfPresent("street") ?? street
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Country:Item {
    @objc dynamic var flag:File? = nil
    @objc dynamic var location:Location? = nil

    override var genericType:String { "Country" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            one_flag = try decoder.decodeIfPresent("one_flag") ?? one_flag
            one_location = try decoder.decodeIfPresent("one_location") ?? one_location

            try self.superDecode(from: decoder)
        }
    }
}

/// The geographic coordinates of a place or event.
class GeoCoordinates:Item {
    let latitude = RealmOptional<Double>()
    let longitude = RealmOptional<Double>()

    override var genericType:String { "GeoCoordinates" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class LogItem:Item {
    @objc dynamic var date:Date? = nil
    @objc dynamic var contents:String? = nil
    @objc dynamic var action:String? = nil

    let appliesTo = List<Relationship>()

    override var genericType:String { "LogItem" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            contents = try decoder.decodeIfPresent("contents") ?? contents
            action = try decoder.decodeIfPresent("action") ?? action

    decodeRelationships(decoder, "appliesTo", Item.self, self.appliesTo, self)
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class MedicalCondition:Item {
    @objc dynamic var type:String? = nil

    override var genericType:String { "MedicalCondition" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class NavigationItem:Item {
    @objc dynamic var title:String? = nil
    @objc dynamic var view:String? = nil
    @objc dynamic var type:String? = nil

    let order = RealmOptional<Int>()

    override var genericType:String { "NavigationItem" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            view = try decoder.decodeIfPresent("view") ?? view
            type = try decoder.decodeIfPresent("type") ?? type

            order.value = try decoder.decodeIfPresent("order") ?? order.value

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class OnlineProfile:Item {
    @objc dynamic var type:String? = nil
    @objc dynamic var handle:String? = nil

    override var genericType:String { "OnlineProfile" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            handle = try decoder.decodeIfPresent("handle") ?? handle

            try self.superDecode(from: decoder)
        }
    }
}

/// A person (alive, dead, undead, or fictional).
class Person:Item {
    @objc dynamic var birthDate:Date? = nil
    @objc dynamic var email:String? = nil
    @objc dynamic var deathDate:Date? = nil
    @objc dynamic var firstName:String? = nil
    @objc dynamic var lastName:String? = nil
    @objc dynamic var gender:String? = nil
    @objc dynamic var sexualOrientation:String? = nil
    @objc dynamic var profilePicture:Photo? = nil

    let height = RealmOptional<Int>()
    let shoulderWidth = RealmOptional<Double>()
    let armLength = RealmOptional<Double>()
    let age = RealmOptional<Double>()

    let addresses = List<Address>()
    let interpersonalRelation = List<Person>()
    let birthPlace = List<Location>()
    let deathPlace = List<Location>()
    let relations = List<Person>()
    let phoneNumbers = List<PhoneNumber>()
    let websites = List<Website>()
    let companies = List<Company>()
    let publicKeys = List<PublicKey>()
    let onlineProfiles = List<OnlineProfile>()
    let diets = List<Diet>()
    let medicalConditions = List<MedicalCondition>()

    override var genericType:String { "Person" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            birthDate = try decoder.decodeIfPresent("birthDate") ?? birthDate
            email = try decoder.decodeIfPresent("email") ?? email
            deathDate = try decoder.decodeIfPresent("deathDate") ?? deathDate
            firstName = try decoder.decodeIfPresent("firstName") ?? firstName
            lastName = try decoder.decodeIfPresent("lastName") ?? lastName
            gender = try decoder.decodeIfPresent("gender") ?? gender
            sexualOrientation = try decoder.decodeIfPresent("sexualOrientation") ?? sexualOrientation
            one_profilePicture = try decoder.decodeIfPresent("one_profilePicture") ?? one_profilePicture

            height.value = try decoder.decodeIfPresent("height") ?? height.value
            shoulderWidth.value = try decoder.decodeIfPresent("shoulderWidth") ?? shoulderWidth.value
            armLength.value = try decoder.decodeIfPresent("armLength") ?? armLength.value
            age.value = try decoder.decodeIfPresent("age") ?? age.value

            decodeIntoList(decoder, "addresses", self.addresses)
            decodeIntoList(decoder, "interpersonalRelation", self.interpersonalRelation)
            decodeIntoList(decoder, "birthPlace", self.birthPlace)
            decodeIntoList(decoder, "deathPlace", self.deathPlace)
            decodeIntoList(decoder, "relations", self.relations)
            decodeIntoList(decoder, "phoneNumbers", self.phoneNumbers)
            decodeIntoList(decoder, "websites", self.websites)
            decodeIntoList(decoder, "companies", self.companies)
            decodeIntoList(decoder, "publicKeys", self.publicKeys)
            decodeIntoList(decoder, "onlineProfiles", self.onlineProfiles)
            decodeIntoList(decoder, "diets", self.diets)
            decodeIntoList(decoder, "medicalConditions", self.medicalConditions)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class PhoneNumber:Item {
    let phoneNumber = List<PhoneNumber>()
    let phoneNumberType = List<PhoneNumber>()

    override var genericType:String { "PhoneNumber" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            decodeIntoList(decoder, "phoneNumber", self.phoneNumber)
            decodeIntoList(decoder, "phoneNumberType", self.phoneNumberType)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class PublicKey:Item {
    @objc dynamic var type:String? = nil
    @objc dynamic var key:String? = nil

    override var genericType:String { "PublicKey" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            key = try decoder.decodeIfPresent("key") ?? key

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class SchemaSession:Item {
    let currentViewIndex = RealmOptional<Int>()

    let editMode = List<bool>()
    let screenshot = List<File>()
    let showContextPane = List<bool>()
    let showFilterPane = List<bool>()

    override var genericType:String { "Session" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            currentViewIndex.value = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex.value

            decodeIntoList(decoder, "editMode", self.editMode)
            decodeIntoList(decoder, "screenshot", self.screenshot)
            decodeIntoList(decoder, "showContextPane", self.showContextPane)
            decodeIntoList(decoder, "showFilterPane", self.showFilterPane)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class SessionView:Item {
    override var genericType:String { "SessionView" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class SchemaSessionsItem {
    let currentSessionIndex = RealmOptional<Int>()

    let sessions = List<Session>()

    override var genericType:String { "Sessions" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            currentSessionIndex.value = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex.value

            decodeIntoList(decoder, "sessions", self.sessions)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Setting:Item {
    @objc dynamic var key:String? = nil
    @objc dynamic var json:String? = nil

    override var genericType:String { "Setting" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            key = try decoder.decodeIfPresent("key") ?? key
            json = try decoder.decodeIfPresent("json") ?? json

            try self.superDecode(from: decoder)
        }
    }
}

/// settings
type
class SettingsCollection:Item {
    @objc dynamic var type:String? = nil

    let settings = List<Setting>()

    override var genericType:String { "SettingsCollection" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type

            decodeIntoList(decoder, "settings", self.settings)

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class SyncState:Item {
    @objc dynamic var type:String? = nil
    @objc dynamic var url:String? = nil

    override var genericType:String { "SyncState" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            url = try decoder.decodeIfPresent("url") ?? url

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
class Website:Item {
    @objc dynamic var type:String? = nil
    @objc dynamic var url:String? = nil

    override var genericType:String { "Website" }

    required init () {
        super.init()
    }

    public convenience required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            url = try decoder.decodeIfPresent("url") ?? url

            try self.superDecode(from: decoder)
        }
    }
}
}
