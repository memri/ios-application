//
// schema.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

public typealias List = RealmSwift.List

// The family of all data item classes
enum ItemFamily: String, ClassFamily, CaseIterable {
    case typeAuditItem = "AuditItem"
    case typeCVUStateDefinition = "CVUStateDefinition"
    case typeCVUStoredDefinition = "CVUStoredDefinition"
    case typeCompany = "Company"
    case typeCreativeWork = "CreativeWork"
    case typeDigitalDocument = "DigitalDocument"
    case typeChat = "Chat"
    case typeComment = "Comment"
    case typeMessage = "Message"
    case typeNote = "Note"
    case typeMediaObject = "MediaObject"
    case typeAudio = "Audio"
    case typePhoto = "Photo"
    case typeVideo = "Video"
    case typeDatasource = "Datasource"
    case typeDevice = "Device"
    case typeDiet = "Diet"
    case typeDownloader = "Downloader"
    case typeEdge = "Edge"
    case typeFile = "File"
    case typeImporter = "Importer"
    case typeImporterRun = "ImporterRun"
    case typeIndexer = "Indexer"
    case typeIndexerRun = "IndexerRun"
    case typeLabel = "Label"
    case typeLocation = "Location"
    case typeAddress = "Address"
    case typeCountry = "Country"
    case typeMedicalCondition = "MedicalCondition"
    case typeNavigationItem = "NavigationItem"
    case typeOnlineProfile = "OnlineProfile"
    case typePerson = "Person"
    case typePhoneNumber = "PhoneNumber"
    case typePublicKey = "PublicKey"
    case typeSetting = "Setting"
    case typeUserState = "UserState"
    case typeViewArguments = "ViewArguments"
    case typeWebsite = "Website"

    static var discriminator: Discriminator = ._type

    var backgroundColor: Color {
        switch self {
        case .typeAuditItem: return Color(hex: "#93c47d")
        case .typeCVUStateDefinition: return Color(hex: "#93c47d")
        case .typeCVUStoredDefinition: return Color(hex: "#93c47d")
        case .typeCompany: return Color(hex: "#93c47d")
        case .typeCreativeWork: return Color(hex: "#93c47d")
        case .typeDigitalDocument: return Color(hex: "#93c47d")
        case .typeChat: return Color(hex: "#93c47d")
        case .typeComment: return Color(hex: "#93c47d")
        case .typeMessage: return Color(hex: "#93c47d")
        case .typeNote: return Color(hex: "#93c47d")
        case .typeMediaObject: return Color(hex: "#93c47d")
        case .typeAudio: return Color(hex: "#93c47d")
        case .typePhoto: return Color(hex: "#93c47d")
        case .typeVideo: return Color(hex: "#93c47d")
        case .typeDatasource: return Color(hex: "#93c47d")
        case .typeDevice: return Color(hex: "#93c47d")
        case .typeDiet: return Color(hex: "#37af1c")
        case .typeDownloader: return Color(hex: "#93c47d")
        case .typeEdge: return Color(hex: "#93c47d")
        case .typeFile: return Color(hex: "#93c47d")
        case .typeImporter: return Color(hex: "#93c47d")
        case .typeImporterRun: return Color(hex: "#93c47d")
        case .typeIndexer: return Color(hex: "#93c47d")
        case .typeIndexerRun: return Color(hex: "#93c47d")
        case .typeLabel: return Color(hex: "#93c47d")
        case .typeLocation: return Color(hex: "#93c47d")
        case .typeAddress: return Color(hex: "#93c47d")
        case .typeCountry: return Color(hex: "#93c47d")
        case .typeMedicalCondition: return Color(hex: "#3dc8e2")
        case .typeNavigationItem: return Color(hex: "#93c47d")
        case .typeOnlineProfile: return Color(hex: "#93c47d")
        case .typePerson: return Color(hex: "#3a5eb2")
        case .typePhoneNumber: return Color(hex: "#eccf23")
        case .typePublicKey: return Color(hex: "#93c47d")
        case .typeSetting: return Color(hex: "#93c47d")
        case .typeUserState: return Color(hex: "#93c47d")
        case .typeViewArguments: return Color(hex: "#93c47d")
        case .typeWebsite: return Color(hex: "#3d57e2")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .typeAuditItem: return Color(hex: "#ffffff")
        case .typeCVUStateDefinition: return Color(hex: "#ffffff")
        case .typeCVUStoredDefinition: return Color(hex: "#ffffff")
        case .typeCompany: return Color(hex: "#ffffff")
        case .typeCreativeWork: return Color(hex: "#ffffff")
        case .typeDigitalDocument: return Color(hex: "#ffffff")
        case .typeChat: return Color(hex: "#ffffff")
        case .typeComment: return Color(hex: "#ffffff")
        case .typeMessage: return Color(hex: "#ffffff")
        case .typeNote: return Color(hex: "#ffffff")
        case .typeMediaObject: return Color(hex: "#ffffff")
        case .typeAudio: return Color(hex: "#ffffff")
        case .typePhoto: return Color(hex: "#ffffff")
        case .typeVideo: return Color(hex: "#ffffff")
        case .typeDatasource: return Color(hex: "#ffffff")
        case .typeDevice: return Color(hex: "#ffffff")
        case .typeDiet: return Color(hex: "#ffffff")
        case .typeDownloader: return Color(hex: "#ffffff")
        case .typeEdge: return Color(hex: "#ffffff")
        case .typeFile: return Color(hex: "#ffffff")
        case .typeImporter: return Color(hex: "#ffffff")
        case .typeImporterRun: return Color(hex: "#ffffff")
        case .typeIndexer: return Color(hex: "#ffffff")
        case .typeIndexerRun: return Color(hex: "#ffffff")
        case .typeLabel: return Color(hex: "#ffffff")
        case .typeLocation: return Color(hex: "#ffffff")
        case .typeAddress: return Color(hex: "#ffffff")
        case .typeCountry: return Color(hex: "#ffffff")
        case .typeMedicalCondition: return Color(hex: "#ffffff")
        case .typeNavigationItem: return Color(hex: "#ffffff")
        case .typeOnlineProfile: return Color(hex: "#ffffff")
        case .typePerson: return Color(hex: "#ffffff")
        case .typePhoneNumber: return Color(hex: "#ffffff")
        case .typePublicKey: return Color(hex: "#ffffff")
        case .typeSetting: return Color(hex: "#ffffff")
        case .typeUserState: return Color(hex: "#ffffff")
        case .typeViewArguments: return Color(hex: "#ffffff")
        case .typeWebsite: return Color(hex: "#ffffff")
        }
    }

    func getPrimaryKey() -> String {
        getType().primaryKey() ?? ""
    }

    func getType() -> AnyObject.Type {
        switch self {
        case .typeAuditItem: return AuditItem.self
        case .typeCVUStateDefinition: return CVUStateDefinition.self
        case .typeCVUStoredDefinition: return CVUStoredDefinition.self
        case .typeCompany: return Company.self
        case .typeCreativeWork: return CreativeWork.self
        case .typeDigitalDocument: return DigitalDocument.self
        case .typeChat: return Chat.self
        case .typeComment: return Comment.self
        case .typeMessage: return Message.self
        case .typeNote: return Note.self
        case .typeMediaObject: return MediaObject.self
        case .typeAudio: return Audio.self
        case .typePhoto: return Photo.self
        case .typeVideo: return Video.self
        case .typeDatasource: return Datasource.self
        case .typeDevice: return Device.self
        case .typeDiet: return Diet.self
        case .typeDownloader: return Downloader.self
        case .typeEdge: return Edge.self
        case .typeFile: return File.self
        case .typeImporter: return Importer.self
        case .typeImporterRun: return ImporterRun.self
        case .typeIndexer: return Indexer.self
        case .typeIndexerRun: return IndexerRun.self
        case .typeLabel: return Label.self
        case .typeLocation: return Location.self
        case .typeAddress: return Address.self
        case .typeCountry: return Country.self
        case .typeMedicalCondition: return MedicalCondition.self
        case .typeNavigationItem: return NavigationItem.self
        case .typeOnlineProfile: return OnlineProfile.self
        case .typePerson: return Person.self
        case .typePhoneNumber: return PhoneNumber.self
        case .typePublicKey: return PublicKey.self
        case .typeSetting: return Setting.self
        case .typeUserState: return UserState.self
        case .typeViewArguments: return ViewArguments.self
        case .typeWebsite: return Website.self
        }
    }
}

public class SyncableItem: Object {
    let _updated = List<String>()
    /// TBD
    @objc dynamic var _partial: Bool = false
    /// TBD
    @objc dynamic var _action: String?
    /// TBD
    @objc dynamic var _changedInSession: Bool = false
}

public class CVUStateDefinition: CVUStoredDefinition {
    required init() {
        super.init()
    }
}

/// Item is the baseclass for all of the data classes.
public class SchemaItem: SyncableItem, Codable, Identifiable {
    /// Last access date of the Item.
    @objc dynamic var dateAccessed: Date? = nil
    /// Creation date of the Item.
    @objc dynamic var dateCreated: Date? = nil
    /// Last modification date of the Item.
    @objc dynamic var dateModified: Date? = nil
    /// Whether the Item is deleted.
    @objc dynamic var deleted: Bool = false
    /// The identifier of an external source.
    @objc dynamic var externalId: String? = nil
    /// A description of the item.
    @objc dynamic var itemDescription: String? = nil
    /// Whether the Item is starred.
    @objc dynamic var starred: Bool = false
    /// The last version loaded from the server.
    @objc dynamic var version: Int = 1
    /// The unique identifier of the Item set by the pod.
    let uid = RealmOptional<Int>()
    /// A collection of all edges of an Item.
    let allEdges = List<Edge>()

    public func superDecode(from decoder: Decoder) throws {
        dateAccessed = try decoder.decodeIfPresent("dateAccessed") ?? dateAccessed
        dateCreated = try decoder.decodeIfPresent("dateCreated") ?? dateCreated
        dateModified = try decoder.decodeIfPresent("dateModified") ?? dateModified
        deleted = try decoder.decodeIfPresent("deleted") ?? deleted
        externalId = try decoder.decodeIfPresent("externalId") ?? externalId
        itemDescription = try decoder.decodeIfPresent("itemDescription") ?? itemDescription
        starred = try decoder.decodeIfPresent("starred") ?? starred
        version = try decoder.decodeIfPresent("version") ?? version
        uid.value = try decoder.decodeIfPresent("uid") ?? uid.value
        decodeEdges(decoder, "allEdges", self as! Item)
    }

    private enum CodingKeys: String, CodingKey {
        case dateAccessed, dateCreated, dateModified, deleted, externalId, itemDescription, starred,
            version, uid, allEdges
    }
}

/// TBD
public class AuditItem: Item {
    /// The date related to an Item.
    @objc dynamic var date: Date?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// TBD
    @objc dynamic var action: String?

    /// The Item this Item applies to.
    var appliesTo: [Item]? {
        edges("appliesTo")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            date = try decoder.decodeIfPresent("date") ?? date
            content = try decoder.decodeIfPresent("content") ?? content
            action = try decoder.decodeIfPresent("action") ?? action

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class CVUStoredDefinition: Item {
    /// The definition of an Item.
    @objc dynamic var definition: String?
    /// An identification string that defines a realm of administrative autonomy, authority or
    /// control within the internet.
    @objc dynamic var domain: String?
    /// The name of the item.
    @objc dynamic var name: String?
    /// A Memri query that retrieves a set of Items from the Pod database.
    @objc dynamic var query: String?
    /// TBD
    @objc dynamic var selector: String?
    /// TBD
    @objc dynamic var type: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            definition = try decoder.decodeIfPresent("definition") ?? definition
            domain = try decoder.decodeIfPresent("domain") ?? domain
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            selector = try decoder.decodeIfPresent("selector") ?? selector
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// A business corporation.
public class Company: Item {
    /// TBD
    @objc dynamic var type: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// The most generic kind of creative work, including books, movies, photographs, software programs,
/// etc.
public class CreativeWork: Item {
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// A text that belongs to this item.
    @objc dynamic var text: String?

    /// A media object that encodes this Item.
    var associatedMedia: Results<MediaObject>? {
        edges("associatedMedia")?.items(type: MediaObject.self)
    }

    /// An audio object.
    var audio: Results<Audio>? {
        edges("audio")?.items(type: Audio.self)
    }

    /// A citation or reference to another creative work, such as another publication, web page,
    /// scholarly article, etc.
    var citation: Results<CreativeWork>? {
        edges("citation")?.items(type: CreativeWork.self)
    }

    /// The location depicted or described in the content. For example, the location in a
    /// photograph or painting.
    var contentLocation: Results<Location>? {
        edges("contentLocation")?.items(type: Location.self)
    }

    /// The location where the Item was created, which may not be the same as the location
    /// depicted in the Item.
    var locationCreated: Results<Location>? {
        edges("locationCreated")?.items(type: Location.self)
    }

    /// A video object.
    var video: Results<Video>? {
        edges("video")?.items(type: Video.self)
    }

    /// The author of this content or rating.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            text = try decoder.decodeIfPresent("text") ?? text

            try self.superDecode(from: decoder)
        }
    }
}

/// An electronic file or document.
public class DigitalDocument: Item {
    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// A chat is a collection of messages.
public class Chat: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// The topic of an item, for instance a Chat.
    @objc dynamic var topic: String?
    /// The Person that received, or is to receive, this Item.
    @objc dynamic var receiver: String?
    /// Whether the item is encrypted.
    @objc dynamic var encrypted: Bool = false

    /// A photo object.
    var photo: Results<Photo>? {
        edges("photo")?.items(type: Photo.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            topic = try decoder.decodeIfPresent("topic") ?? topic
            receiver = try decoder.decodeIfPresent("receiver") ?? receiver
            encrypted = try decoder.decodeIfPresent("encrypted") ?? encrypted

            try self.superDecode(from: decoder)
        }
    }
}

/// A comment.
public class Comment: Item {
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent

            try self.superDecode(from: decoder)
        }
    }
}

/// A single message.
public class Message: Item {
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// The sender of an Item.
    @objc dynamic var sender: String?
    /// The Synapse jid of a chat.
    @objc dynamic var chatJid: String?
    /// The Synapse reciever id.
    @objc dynamic var chatReceiver: String?

    /// A Chat this Item belongs to.
    var chat: Results<Chat>? {
        edges("chat")?.items(type: Chat.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            sender = try decoder.decodeIfPresent("sender") ?? sender
            chatJid = try decoder.decodeIfPresent("chatJid") ?? chatJid
            chatReceiver = try decoder.decodeIfPresent("chatReceiver") ?? chatReceiver

            try self.superDecode(from: decoder)
        }
    }
}

/// A file containing a note.
public class Note: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?

    /// A comment on this Item.
    var comment: Results<Comment>? {
        edges("comment")?.items(type: Comment.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent

            try self.superDecode(from: decoder)
        }
    }
}

/// A media object, such as an image, video, or audio object embedded in a web page or a
/// downloadable dataset i.e. DataDownload. Note that a creative work may have many media objects
/// associated with it on the same web page. For example, a page about a single song (MusicRecording)
/// may have a music video (VideoObject), and a high and low bandwidth audio stream (2 AudioObject's).
public class MediaObject: Item {
    /// The bitrate of a media object.
    let bitrate = RealmOptional<Int>()
    /// The duration of an Item, for instance an event or an Audio file.
    let duration = RealmOptional<Int>()
    /// The endTime of something. For a reserved event or service, the time that it is expected
    /// to end. For actions that span a period of time, when the action was performed. e.g. John wrote a
    /// book from January to December. For media, including audio and video, it's the time offset of the
    /// end of a clip within a larger file.
    @objc dynamic var endTime: Date?
    /// Location of the actual bytes of a File.
    @objc dynamic var fileLocation: String?
    /// Size of the application / package (e.g. 18MB). In the absence of a unit (MB, KB etc.),
    /// KB will be assumed.
    @objc dynamic var fileSize: String?
    /// The height of the item.
    let height = RealmOptional<Int>()
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The width of the item.
    let width = RealmOptional<Int>()

    /// Any type of file that can be stored on disk.
    var file: File? {
        edge("file")?.target(type: File.self)
    }

    /// Items included within this Item. Included Items can be of any type.
    var includes: [Item]? {
        edges("includes")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            bitrate.value = try decoder.decodeIfPresent("bitrate") ?? bitrate.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime
            fileLocation = try decoder.decodeIfPresent("fileLocation") ?? fileLocation
            fileSize = try decoder.decodeIfPresent("fileSize") ?? fileSize
            height.value = try decoder.decodeIfPresent("height") ?? height.value
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            width.value = try decoder.decodeIfPresent("width") ?? width.value

            try self.superDecode(from: decoder)
        }
    }
}

/// An audio file.
public class Audio: Item {
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// An image file.
public class Photo: Item {
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// Exif data of an image file.
    @objc dynamic var exifData: String?
    /// The name of the item.
    @objc dynamic var name: String?

    /// Thumbnail image for an Item, typically an image or video.
    var thumbnail: File? {
        edge("thumbnail")?.target(type: File.self)
    }

    var file: File? {
        edge("file")?.target(type: File.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A video file.
public class Video: Item {
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// Exif data of an image file.
    @objc dynamic var exifData: String?
    /// The name of the item.
    @objc dynamic var name: String?

    /// Thumbnail image for an Item, typically an image or video.
    var thumbnail: Results<File>? {
        edges("thumbnail")?.items(type: File.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A business corporation.
public class Device: Item {
    /// The Device ID, used for smartphones and tablets.
    @objc dynamic var deviceID: String?
    /// The make number of a device, for instance a mobile phone.
    @objc dynamic var make: String?
    /// The manufacturer of the Item
    @objc dynamic var manufacturer: String?
    /// The model number or name of an Item, for instance of a mobile phone.
    @objc dynamic var model: String?
    /// The name of the item.
    @objc dynamic var name: String?
    /// The date this item was acquired.
    @objc dynamic var dateAcquired: Date?
    /// The date this Item was lost.
    @objc dynamic var dateLost: Date?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            deviceID = try decoder.decodeIfPresent("deviceID") ?? deviceID
            make = try decoder.decodeIfPresent("make") ?? make
            manufacturer = try decoder.decodeIfPresent("manufacturer") ?? manufacturer
            model = try decoder.decodeIfPresent("model") ?? model
            name = try decoder.decodeIfPresent("name") ?? name
            dateAcquired = try decoder.decodeIfPresent("dateAcquired") ?? dateAcquired
            dateLost = try decoder.decodeIfPresent("dateLost") ?? dateLost

            try self.superDecode(from: decoder)
        }
    }
}

/// A strategy of regulating the intake of food to achieve or maintain a specific health-related
/// goal.
public class Diet: Item {
    /// TBD
    @objc dynamic var type: String?
    /// TBD
    @objc dynamic var addition: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            addition = try decoder.decodeIfPresent("addition") ?? addition
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A Downloader is used to download data from an external source, to be imported using an Importer.
public class Downloader: Item {
    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// Edge is the Item that stores the specifics of an edge, used by front ends.
public class Edge: SyncableItem, Codable {
    /// TBD
    @objc dynamic var type: String? = nil
    /// The type of the target Item, or Item to where an edge points. Opposite of
    /// sourceItemType.
    @objc dynamic var targetItemType: String? = nil
    /// The uid of the target Item, or Item to where an Edge points. Opposite of sourceItemID
    let targetItemID = RealmOptional<Int>()
    /// The type of the source Item, or Item from where an edge points. Opposite of
    /// targetItemType.
    @objc dynamic var sourceItemType: String? = nil
    /// The uid of the source Item, or Item from where an Edge points. Opposite of targetItemID
    let sourceItemID = RealmOptional<Int>()
    /// Used to define position in a sequence, enables ordering based on this number.
    let sequence = RealmOptional<Int>()
    /// Whether the Item is deleted.
    @objc dynamic var deleted: Bool = false
    /// The last version loaded from the server.
    @objc dynamic var version: Int = 1
    /// A label of an edge.
    @objc dynamic var edgeLabel: String? = nil

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("_type") ?? type
            targetItemType = try decoder.decodeIfPresent("itemType") ?? targetItemType
            targetItemID.value = try decoder.decodeIfPresent("uid") ?? targetItemID.value
            sequence.value = try decoder.decodeIfPresent("sequence") ?? sequence.value
            deleted = try decoder.decodeIfPresent("deleted") ?? deleted
            version = try decoder.decodeIfPresent("version") ?? version
            edgeLabel = try decoder.decodeIfPresent("edgeLabel") ?? edgeLabel

            try parseTargetDict(try decoder.decodeIfPresent("_target"))
        }
    }
}

/// Any type of file that can be stored on disk.
public class File: Item {
    /// The uri property represents the Uniform Resource Identifier (URI) of a resource.
    @objc dynamic var uri: String? = UUID().uuidString

    /// An Item this Item is used by.
    var usedBy: [Item]? {
        edges("usedBy")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            uri = try decoder.decodeIfPresent("uri") ?? uri

            try self.superDecode(from: decoder)
        }
    }
}

/// An Importer is used to import data from an external source to the Pod database.
public class Importer: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// The type of the data this Item acts on.
    @objc dynamic var dataType: String?
    /// TBD
    @objc dynamic var icon: String?
    /// TBD
    @objc dynamic var bundleImage: String?

    /// A run of a certain Importer, that defines the details of the specific import.
    var importerRun: Results<ImporterRun>? {
        edges("importerRun")?.items(type: ImporterRun.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            dataType = try decoder.decodeIfPresent("dataType") ?? dataType
            icon = try decoder.decodeIfPresent("icon") ?? icon
            bundleImage = try decoder.decodeIfPresent("bundleImage") ?? bundleImage

            try self.superDecode(from: decoder)
        }
    }
}

/// A run of a certain Importer, that defines the details of the specific import.
public class ImporterRun: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// The type of the data this Item acts on.
    @objc dynamic var dataType: String?

    /// An Importer is used to import data from an external source to the Pod database.
    var importer: Importer? {
        edge("importer")?.target(type: Importer.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            dataType = try decoder.decodeIfPresent("dataType") ?? dataType

            try self.superDecode(from: decoder)
        }
    }
}

/// An indexer enhances your personal data by inferring facts over existing data and adding those to
/// the database.
public class Indexer: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// TBD
    @objc dynamic var icon: String?
    /// A Memri query that retrieves a set of Items from the Pod database.
    @objc dynamic var query: String?
    /// TBD
    @objc dynamic var bundleImage: String?
    /// The destination of a run.
    @objc dynamic var runDestination: String?
    /// The type of an Indexer.
    @objc dynamic var indexerClass: String?

    /// A run of a certain Indexer, that defines the details of the specific indexing.
    var indexerRun: Results<IndexerRun>? {
        edges("indexerRun")?.items(type: IndexerRun.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            icon = try decoder.decodeIfPresent("icon") ?? icon
            query = try decoder.decodeIfPresent("query") ?? query
            bundleImage = try decoder.decodeIfPresent("bundleImage") ?? bundleImage
            runDestination = try decoder.decodeIfPresent("runDestination") ?? runDestination
            indexerClass = try decoder.decodeIfPresent("indexerClass") ?? indexerClass

            try self.superDecode(from: decoder)
        }
    }
}

/// A run of a certain Indexer.
public class IndexerRun: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// A Memri query that retrieves a set of Items from the Pod database.
    @objc dynamic var query: String?
    /// The progress an Item made. The number could be a (rounded) percentage or a count of a
    /// (potentially unknown) total.
    let progress = RealmOptional<Int>()
    /// The type of data this Item targets.
    @objc dynamic var targetDataType: String?

    /// An Indexer is used to enrich data in the Pod database.
    var indexer: Indexer? {
        edge("indexer")?.target(type: Indexer.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            progress.value = try decoder.decodeIfPresent("progress") ?? progress.value
            targetDataType = try decoder.decodeIfPresent("targetDataType") ?? targetDataType

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class Label: Item {
    /// The color of this Item.
    @objc dynamic var color: String?
    /// The name of the item.
    @objc dynamic var name: String?

    /// A comment on this Item.
    var comment: Results<Comment>? {
        edges("comment")?.items(type: Comment.self)
    }

    /// The Item this Item applies to.
    var appliesTo: [Item]? {
        edges("appliesTo")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            color = try decoder.decodeIfPresent("color") ?? color
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// The location of something.
public class Location: Item {
    /// The latitude of a location in WGS84 format.
    let latitude = RealmOptional<Double>()
    /// The longitude of a location in WGS84 format.
    let longitude = RealmOptional<Double>()

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value

            try self.superDecode(from: decoder)
        }
    }
}

/// A postal address.
public class Address: Item {
    /// A city or town.
    @objc dynamic var city: String?
    /// The postal code. For example, 94043.
    @objc dynamic var postalCode: String?
    /// A state or province of a country.
    @objc dynamic var state: String?
    /// The street address. For example, 1600 Amphitheatre Pkwy.
    @objc dynamic var street: String?
    /// TBD
    @objc dynamic var type: String?
    /// TBD
    @objc dynamic var locationAutoLookupHash: String?

    /// A country.
    var country: Country? {
        edge("country")?.target(type: Country.self)
    }

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Location? {
        edge("location")?.target(type: Location.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            city = try decoder.decodeIfPresent("city") ?? city
            postalCode = try decoder.decodeIfPresent("postalCode") ?? postalCode
            state = try decoder.decodeIfPresent("state") ?? state
            street = try decoder.decodeIfPresent("street") ?? street
            type = try decoder.decodeIfPresent("type") ?? type
            locationAutoLookupHash = try decoder
                .decodeIfPresent("locationAutoLookupHash") ?? locationAutoLookupHash

            try self.superDecode(from: decoder)
        }
    }
}

/// A country.
public class Country: Item {
    /// The name of the item.
    @objc dynamic var name: String?

    /// TBD
    var flag: File? {
        edge("flag")?.target(type: File.self)
    }

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Location? {
        edge("location")?.target(type: Location.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// Any condition of the human body that affects the normal functioning of a person, whether
/// physically or mentally. Includes diseases, injuries, disabilities, disorders, syndromes, etc.
public class MedicalCondition: Item {
    /// TBD
    @objc dynamic var type: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class NavigationItem: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// TBD
    @objc dynamic var sessionName: String?
    /// Used to define position in a sequence, enables ordering based on this number.
    let sequence = RealmOptional<Int>()
    /// TBD
    @objc dynamic var type: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            sessionName = try decoder.decodeIfPresent("sessionName") ?? sessionName
            sequence.value = try decoder.decodeIfPresent("sequence") ?? sequence.value
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// An online profile, typically on social media.
public class OnlineProfile: Item {
    /// TBD
    @objc dynamic var type: String?
    /// TBD
    @objc dynamic var handle: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            handle = try decoder.decodeIfPresent("handle") ?? handle

            try self.superDecode(from: decoder)
        }
    }
}

/// A person (alive, dead, undead, or fictional).
public class SchemaPerson: Item {
    /// Date of birth.
    @objc dynamic var birthDate: Date?
    /// Email address.
    @objc dynamic var email: String?
    /// Date of death.
    @objc dynamic var deathDate: Date?
    /// Family name. In the U.S., the last name of an Person. This can be used along with
    /// givenName instead of the name property.
    @objc dynamic var firstName: String?
    /// Given name. In the U.S., the first name of a Person. This can be used along with
    /// familyName instead of the name property.
    @objc dynamic var lastName: String?
    /// Gender of something, typically a Person, but possibly also fictional characters,
    /// animals, etc.
    @objc dynamic var gender: String?
    /// The sexual orientation of a person.
    @objc dynamic var sexualOrientation: String?
    /// The height of the item.
    let height = RealmOptional<Int>()
    /// The shoulder width of an Item.
    let shoulderWidth = RealmOptional<Double>()
    /// The arm length of an Item.
    let armLength = RealmOptional<Double>()
    /// The name to display, for Persons this could be a first or last name, both, or a
    /// phonenumber.
    @objc dynamic var displayName: String?
    /// The name quality used by Synapse.
    let nameQuality = RealmOptional<Int>()
    /// Whether the Item should be displayed in the interfaces.
    @objc dynamic var enablePresence: Bool = false
    ///
    @objc dynamic var enableReceipts: Bool = false

    /// Physical address of the event or place.
    var address: Results<Address>? {
        edges("address")?.items(type: Address.self)
    }

    /// The place where the person was born.
    var birthPlace: Location? {
        edge("birthPlace")?.target(type: Location.self)
    }

    /// The place where someone or something died, typically a Person.
    var deathPlace: Location? {
        edge("deathPlace")?.target(type: Location.self)
    }

    /// A photo that corresponds to some Person or other kind of profile.
    var profilePicture: Photo? {
        edge("profilePicture")?.target(type: Photo.self)
    }

    /// A relation between two persons.
    var relationship: Results<Person>? {
        edges("relationship")?.items(type: Person.self)
    }

    /// A phone number that belongs to an Item.
    var hasPhoneNumber: Results<PhoneNumber>? {
        edges("hasPhoneNumber")?.items(type: PhoneNumber.self)
    }

    /// A WebSite is a set of related web pages and other items typically served from a single
    /// web domain and accessible via URLs.
    var website: Results<Website>? {
        edges("website")?.items(type: Website.self)
    }

    /// A business or similar type of organization.
    var company: Results<Company>? {
        edges("company")?.items(type: Company.self)
    }

    /// A public key used in an asymmetric cryptography protocol.
    var publicKey: Results<PublicKey>? {
        edges("publicKey")?.items(type: PublicKey.self)
    }

    /// An online profile, typically on social media.
    var onlineProfile: Results<OnlineProfile>? {
        edges("onlineProfile")?.items(type: OnlineProfile.self)
    }

    /// A strategy of regulating the intake of food to achieve or maintain a specific
    /// health-related goal.
    var diet: Results<Diet>? {
        edges("diet")?.items(type: Diet.self)
    }

    /// Any condition of the human body that affects the normal functioning of a person, whether
    /// physically or mentally. Includes diseases, injuries, disabilities, disorders, syndromes, etc.
    var medicalCondition: Results<MedicalCondition>? {
        edges("medicalCondition")?.items(type: MedicalCondition.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            birthDate = try decoder.decodeIfPresent("birthDate") ?? birthDate
            email = try decoder.decodeIfPresent("email") ?? email
            deathDate = try decoder.decodeIfPresent("deathDate") ?? deathDate
            firstName = try decoder.decodeIfPresent("firstName") ?? firstName
            lastName = try decoder.decodeIfPresent("lastName") ?? lastName
            gender = try decoder.decodeIfPresent("gender") ?? gender
            sexualOrientation = try decoder
                .decodeIfPresent("sexualOrientation") ?? sexualOrientation
            height.value = try decoder.decodeIfPresent("height") ?? height.value
            shoulderWidth.value = try decoder.decodeIfPresent("shoulderWidth") ?? shoulderWidth
                .value
            armLength.value = try decoder.decodeIfPresent("armLength") ?? armLength.value
            displayName = try decoder.decodeIfPresent("displayName") ?? displayName
            nameQuality.value = try decoder.decodeIfPresent("nameQuality") ?? nameQuality.value
            enablePresence = try decoder.decodeIfPresent("enablePresence") ?? enablePresence
            enableReceipts = try decoder.decodeIfPresent("enableReceipts") ?? enableReceipts

            try self.superDecode(from: decoder)
        }
    }
}

/// A telephone number.
public class PhoneNumber: Item {
    /// A phone number with an area code.
    @objc dynamic var phoneNumber: String?
    /// TBD
    @objc dynamic var type: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            phoneNumber = try decoder.decodeIfPresent("phoneNumber") ?? phoneNumber
            type = try decoder.decodeIfPresent("type") ?? type

            try self.superDecode(from: decoder)
        }
    }
}

/// A public key used in an asymmetric cryptography protocol.
public class PublicKey: Item {
    /// TBD
    @objc dynamic var type: String?
    /// A piece of information that determines the functional output of a cryptographic
    /// algorithm.
    @objc dynamic var key: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            key = try decoder.decodeIfPresent("key") ?? key
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class Setting: Item {
    /// A piece of information that determines the functional output of a cryptographic
    /// algorithm.
    @objc dynamic var key: String?
    /// TBD
    @objc dynamic var json: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            key = try decoder.decodeIfPresent("key") ?? key
            json = try decoder.decodeIfPresent("json") ?? json

            try self.superDecode(from: decoder)
        }
    }
}

/// A Website is a set of related web pages and other items typically served from a single web
/// domain and accessible via URLs.
public class Website: Item {
    /// TBD
    @objc dynamic var type: String?
    /// The URL of an Item.
    @objc dynamic var url: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            type = try decoder.decodeIfPresent("type") ?? type
            url = try decoder.decodeIfPresent("url") ?? url

            try self.superDecode(from: decoder)
        }
    }
}

func dataItemListToArray(_ object: Any) -> [Item] {
    var collection: [Item] = []

    if let list = object as? Results<Item> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<AuditItem> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<CVUStateDefinition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<CVUStoredDefinition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<Company> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<CreativeWork> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<DigitalDocument> { list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<Chat> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Comment> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Message> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Note> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<MediaObject> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Audio> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Photo> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Video> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Device> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Diet> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Downloader> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Edge> { return list.itemsArray() }
    else if let list = object as? Results<File> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Importer> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<ImporterRun> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Indexer> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<IndexerRun> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Label> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Location> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Address> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Country> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<MedicalCondition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<NavigationItem> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<OnlineProfile> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Person> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<PhoneNumber> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<PublicKey> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Setting> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Website> { list.forEach { collection.append($0) } }

    return collection
}
