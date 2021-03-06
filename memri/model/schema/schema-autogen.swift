//
// schema-autogen.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

public typealias List = RealmSwift.List

// The family of all data item classes
enum ItemFamily: String, ClassFamily, CaseIterable {
    case typeAccount = "Account"
    case typeAddress = "Address"
    case typeArticle = "Article"
    case typeAudio = "Audio"
    case typeAuditItem = "AuditItem"
    case typeCVUStateDefinition = "CVUStateDefinition"
    case typeCVUStoredDefinition = "CVUStoredDefinition"
    case typeComment = "Comment"
    case typeCountry = "Country"
    case typeCreativeWork = "CreativeWork"
    case typeCryptoKey = "CryptoKey"
    case typeDevice = "Device"
    case typeDiet = "Diet"
    case typeDownloader = "Downloader"
    case typeEmailMessage = "EmailMessage"
    case typeEvent = "Event"
    case typeExercisePlan = "ExercisePlan"
    case typeFile = "File"
    case typeFrequency = "Frequency"
    case typeGame = "Game"
    case typeGenericAttribute = "GenericAttribute"
    case typeHowTo = "HowTo"
    case typeImporter = "Importer"
    case typeImporterRun = "ImporterRun"
    case typeIndexer = "Indexer"
    case typeIndexerRun = "IndexerRun"
    case typeIndustry = "Industry"
    case typeIntegrator = "Integrator"
    case typeInvoice = "Invoice"
    case typeLabel = "Label"
    case typeLead = "Lead"
    case typeLocation = "Location"
    case typeMaterial = "Material"
    case typeMeasure = "Measure"
    case typeMediaObject = "MediaObject"
    case typeMedicalCondition = "MedicalCondition"
    case typeMessage = "Message"
    case typeMessageChannel = "MessageChannel"
    case typeModeOfTransport = "ModeOfTransport"
    case typeMovingImage = "MovingImage"
    case typeNavigationItem = "NavigationItem"
    case typeNetwork = "Network"
    case typeNote = "Note"
    case typeNoteList = "NoteList"
    case typeOffer = "Offer"
    case typeOpeningHours = "OpeningHours"
    case typeOption = "Option"
    case typeOrganization = "Organization"
    case typePerformingArt = "PerformingArt"
    case typePerson = "Person"
    case typePhoneNumber = "PhoneNumber"
    case typePhoto = "Photo"
    case typePhysicalEntity = "PhysicalEntity"
    case typeProduct = "Product"
    case typeProductCode = "ProductCode"
    case typeReceipt = "Receipt"
    case typeRecipe = "Recipe"
    case typeRecording = "Recording"
    case typeReservation = "Reservation"
    case typeResource = "Resource"
    case typeReview = "Review"
    case typeRoute = "Route"
    case typeSetting = "Setting"
    case typeSpan = "Span"
    case typeTimeFrame = "TimeFrame"
    case typeTransaction = "Transaction"
    case typeTrip = "Trip"
    case typeUnit = "Unit"
    case typeVideo = "Video"
    case typeVisualArt = "VisualArt"
    case typeVote = "Vote"
    case typeVoteAction = "VoteAction"
    case typeWebsite = "Website"
    case typeWrittenWork = "WrittenWork"
    case typeLabelAnnotation = "LabelAnnotation"
    case typeLabelAnnotationCollection = "LabelAnnotationCollection"
    case typePhotoAnnotation = "PhotoAnnotation"
    case typeReceiptDemo = "ReceiptDemo"

    static var discriminator: Discriminator = ._type

    var backgroundColor: Color {
        switch self {
        case .typeAccount: return Color(hex: "#93c47d")
        case .typeAddress: return Color(hex: "#93c47d")
        case .typeArticle: return Color(hex: "#93c47d")
        case .typeAudio: return Color(hex: "#93c47d")
        case .typeAuditItem: return Color(hex: "#93c47d")
        case .typeCVUStateDefinition: return Color(hex: "#93c47d")
        case .typeCVUStoredDefinition: return Color(hex: "#93c47d")
        case .typeComment: return Color(hex: "#93c47d")
        case .typeCountry: return Color(hex: "#93c47d")
        case .typeCreativeWork: return Color(hex: "#93c47d")
        case .typeCryptoKey: return Color(hex: "#93c47d")
        case .typeDevice: return Color(hex: "#93c47d")
        case .typeDiet: return Color(hex: "#37af1c")
        case .typeDownloader: return Color(hex: "#93c47d")
        case .typeEmailMessage: return Color(hex: "#93c47d")
        case .typeEvent: return Color(hex: "#93c47d")
        case .typeExercisePlan: return Color(hex: "#93c47d")
        case .typeFile: return Color(hex: "#93c47d")
        case .typeFrequency: return Color(hex: "#93c47d")
        case .typeGame: return Color(hex: "#93c47d")
        case .typeGenericAttribute: return Color(hex: "#93c47d")
        case .typeHowTo: return Color(hex: "#93c47d")
        case .typeImporter: return Color(hex: "#93c47d")
        case .typeImporterRun: return Color(hex: "#93c47d")
        case .typeIndexer: return Color(hex: "#93c47d")
        case .typeIndexerRun: return Color(hex: "#93c47d")
        case .typeIndustry: return Color(hex: "#93c47d")
        case .typeIntegrator: return Color(hex: "#93c47d")
        case .typeInvoice: return Color(hex: "#93c47d")
        case .typeLabel: return Color(hex: "#93c47d")
        case .typeLead: return Color(hex: "#93c47d")
        case .typeLocation: return Color(hex: "#93c47d")
        case .typeMaterial: return Color(hex: "#3d57e2")
        case .typeMeasure: return Color(hex: "#3d57e2")
        case .typeMediaObject: return Color(hex: "#93c47d")
        case .typeMedicalCondition: return Color(hex: "#3dc8e2")
        case .typeMessage: return Color(hex: "#93c47d")
        case .typeMessageChannel: return Color(hex: "#93c47d")
        case .typeModeOfTransport: return Color(hex: "#93c47d")
        case .typeMovingImage: return Color(hex: "#93c47d")
        case .typeNavigationItem: return Color(hex: "#93c47d")
        case .typeNetwork: return Color(hex: "#93c47d")
        case .typeNote: return Color(hex: "#93c47d")
        case .typeNoteList: return Color(hex: "#93c47d")
        case .typeOffer: return Color(hex: "#93c47d")
        case .typeOpeningHours: return Color(hex: "#93c47d")
        case .typeOption: return Color(hex: "#93c47d")
        case .typeOrganization: return Color(hex: "#93c47d")
        case .typePerformingArt: return Color(hex: "#93c47d")
        case .typePerson: return Color(hex: "#3a5eb2")
        case .typePhoneNumber: return Color(hex: "#eccf23")
        case .typePhoto: return Color(hex: "#93c47d")
        case .typePhysicalEntity: return Color(hex: "#93c47d")
        case .typeProduct: return Color(hex: "#93c47d")
        case .typeProductCode: return Color(hex: "#93c47d")
        case .typeReceipt: return Color(hex: "#93c47d")
        case .typeRecipe: return Color(hex: "#93c47d")
        case .typeRecording: return Color(hex: "#93c47d")
        case .typeReservation: return Color(hex: "#93c47d")
        case .typeResource: return Color(hex: "#93c47d")
        case .typeReview: return Color(hex: "#93c47d")
        case .typeRoute: return Color(hex: "#93c47d")
        case .typeSetting: return Color(hex: "#93c47d")
        case .typeSpan: return Color(hex: "#93c47d")
        case .typeTimeFrame: return Color(hex: "#93c47d")
        case .typeTransaction: return Color(hex: "#3a5eb2")
        case .typeTrip: return Color(hex: "#93c47d")
        case .typeUnit: return Color(hex: "#93c47d")
        case .typeVideo: return Color(hex: "#93c47d")
        case .typeVisualArt: return Color(hex: "#93c47d")
        case .typeVote: return Color(hex: "#93c47d")
        case .typeVoteAction: return Color(hex: "#93c47d")
        case .typeWebsite: return Color(hex: "#3d57e2")
        case .typeWrittenWork: return Color(hex: "#93c47d")
        default: return Color(hex: "#93c47d")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .typeAccount: return Color(hex: "#ffffff")
        case .typeAddress: return Color(hex: "#ffffff")
        case .typeArticle: return Color(hex: "#ffffff")
        case .typeAudio: return Color(hex: "#ffffff")
        case .typeAuditItem: return Color(hex: "#ffffff")
        case .typeCVUStateDefinition: return Color(hex: "#ffffff")
        case .typeCVUStoredDefinition: return Color(hex: "#ffffff")
        case .typeComment: return Color(hex: "#ffffff")
        case .typeCountry: return Color(hex: "#ffffff")
        case .typeCreativeWork: return Color(hex: "#ffffff")
        case .typeCryptoKey: return Color(hex: "#ffffff")
        case .typeDevice: return Color(hex: "#ffffff")
        case .typeDiet: return Color(hex: "#ffffff")
        case .typeDownloader: return Color(hex: "#ffffff")
        case .typeEmailMessage: return Color(hex: "#ffffff")
        case .typeEvent: return Color(hex: "#ffffff")
        case .typeExercisePlan: return Color(hex: "#ffffff")
        case .typeFile: return Color(hex: "#ffffff")
        case .typeFrequency: return Color(hex: "#ffffff")
        case .typeGame: return Color(hex: "#ffffff")
        case .typeGenericAttribute: return Color(hex: "#ffffff")
        case .typeHowTo: return Color(hex: "#ffffff")
        case .typeImporter: return Color(hex: "#ffffff")
        case .typeImporterRun: return Color(hex: "#ffffff")
        case .typeIndexer: return Color(hex: "#ffffff")
        case .typeIndexerRun: return Color(hex: "#ffffff")
        case .typeIndustry: return Color(hex: "#ffffff")
        case .typeIntegrator: return Color(hex: "#ffffff")
        case .typeInvoice: return Color(hex: "#ffffff")
        case .typeLabel: return Color(hex: "#ffffff")
        case .typeLead: return Color(hex: "#ffffff")
        case .typeLocation: return Color(hex: "#ffffff")
        case .typeMaterial: return Color(hex: "#ffffff")
        case .typeMeasure: return Color(hex: "#ffffff")
        case .typeMediaObject: return Color(hex: "#ffffff")
        case .typeMedicalCondition: return Color(hex: "#ffffff")
        case .typeMessage: return Color(hex: "#ffffff")
        case .typeMessageChannel: return Color(hex: "#ffffff")
        case .typeModeOfTransport: return Color(hex: "#ffffff")
        case .typeMovingImage: return Color(hex: "#ffffff")
        case .typeNavigationItem: return Color(hex: "#ffffff")
        case .typeNetwork: return Color(hex: "#ffffff")
        case .typeNote: return Color(hex: "#ffffff")
        case .typeNoteList: return Color(hex: "#ffffff")
        case .typeOffer: return Color(hex: "#ffffff")
        case .typeOpeningHours: return Color(hex: "#ffffff")
        case .typeOption: return Color(hex: "#ffffff")
        case .typeOrganization: return Color(hex: "#ffffff")
        case .typePerformingArt: return Color(hex: "#ffffff")
        case .typePerson: return Color(hex: "#ffffff")
        case .typePhoneNumber: return Color(hex: "#ffffff")
        case .typePhoto: return Color(hex: "#ffffff")
        case .typePhysicalEntity: return Color(hex: "#ffffff")
        case .typeProduct: return Color(hex: "#ffffff")
        case .typeProductCode: return Color(hex: "#ffffff")
        case .typeReceipt: return Color(hex: "#ffffff")
        case .typeRecipe: return Color(hex: "#ffffff")
        case .typeRecording: return Color(hex: "#ffffff")
        case .typeReservation: return Color(hex: "#ffffff")
        case .typeResource: return Color(hex: "#ffffff")
        case .typeReview: return Color(hex: "#ffffff")
        case .typeRoute: return Color(hex: "#ffffff")
        case .typeSetting: return Color(hex: "#ffffff")
        case .typeSpan: return Color(hex: "#ffffff")
        case .typeTimeFrame: return Color(hex: "#ffffff")
        case .typeTransaction: return Color(hex: "#ffffff")
        case .typeTrip: return Color(hex: "#ffffff")
        case .typeUnit: return Color(hex: "#ffffff")
        case .typeVideo: return Color(hex: "#ffffff")
        case .typeVisualArt: return Color(hex: "#ffffff")
        case .typeVote: return Color(hex: "#ffffff")
        case .typeVoteAction: return Color(hex: "#ffffff")
        case .typeWebsite: return Color(hex: "#ffffff")
        case .typeWrittenWork: return Color(hex: "#ffffff")
        default: return Color.white
        }
    }

    func getPrimaryKey() -> String {
        getType().primaryKey() ?? ""
    }

    func getType() -> AnyObject.Type {
        switch self {
        case .typeAccount: return Account.self
        case .typeAddress: return Address.self
        case .typeArticle: return Article.self
        case .typeAudio: return Audio.self
        case .typeAuditItem: return AuditItem.self
        case .typeCVUStateDefinition: return CVUStateDefinition.self
        case .typeCVUStoredDefinition: return CVUStoredDefinition.self
        case .typeComment: return Comment.self
        case .typeCountry: return Country.self
        case .typeCreativeWork: return CreativeWork.self
        case .typeCryptoKey: return CryptoKey.self
        case .typeDevice: return Device.self
        case .typeDiet: return Diet.self
        case .typeDownloader: return Downloader.self
        case .typeEmailMessage: return EmailMessage.self
        case .typeEvent: return Event.self
        case .typeExercisePlan: return ExercisePlan.self
        case .typeFile: return File.self
        case .typeFrequency: return Frequency.self
        case .typeGame: return Game.self
        case .typeGenericAttribute: return GenericAttribute.self
        case .typeHowTo: return HowTo.self
        case .typeImporter: return Importer.self
        case .typeImporterRun: return ImporterRun.self
        case .typeIndexer: return Indexer.self
        case .typeIndexerRun: return IndexerRun.self
        case .typeIndustry: return Industry.self
        case .typeIntegrator: return Integrator.self
        case .typeInvoice: return Invoice.self
        case .typeLabel: return Label.self
        case .typeLead: return Lead.self
        case .typeLocation: return Location.self
        case .typeMaterial: return Material.self
        case .typeMeasure: return Measure.self
        case .typeMediaObject: return MediaObject.self
        case .typeMedicalCondition: return MedicalCondition.self
        case .typeMessage: return Message.self
        case .typeMessageChannel: return MessageChannel.self
        case .typeModeOfTransport: return ModeOfTransport.self
        case .typeMovingImage: return MovingImage.self
        case .typeNavigationItem: return NavigationItem.self
        case .typeNetwork: return Network.self
        case .typeNote: return Note.self
        case .typeNoteList: return NoteList.self
        case .typeOffer: return Offer.self
        case .typeOpeningHours: return OpeningHours.self
        case .typeOption: return Option.self
        case .typeOrganization: return Organization.self
        case .typePerformingArt: return PerformingArt.self
        case .typePerson: return Person.self
        case .typePhoneNumber: return PhoneNumber.self
        case .typePhoto: return Photo.self
        case .typePhysicalEntity: return PhysicalEntity.self
        case .typeProduct: return Product.self
        case .typeProductCode: return ProductCode.self
        case .typeReceipt: return Receipt.self
        case .typeRecipe: return Recipe.self
        case .typeRecording: return Recording.self
        case .typeReservation: return Reservation.self
        case .typeResource: return Resource.self
        case .typeReview: return Review.self
        case .typeRoute: return Route.self
        case .typeSetting: return Setting.self
        case .typeSpan: return Span.self
        case .typeTimeFrame: return TimeFrame.self
        case .typeTransaction: return Transaction.self
        case .typeTrip: return Trip.self
        case .typeUnit: return Unit.self
        case .typeVideo: return Video.self
        case .typeVisualArt: return VisualArt.self
        case .typeVote: return Vote.self
        case .typeVoteAction: return VoteAction.self
        case .typeWebsite: return Website.self
        case .typeWrittenWork: return WrittenWork.self
        case .typeLabelAnnotation: return LabelAnnotation.self
        case .typeLabelAnnotationCollection: return LabelAnnotationCollection.self
        case .typePhotoAnnotation: return PhotoAnnotation.self
        case .typeReceiptDemo: return ReceiptDemo.self
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

/// An account or subscription, for instance for some online service, or a bank account or wallet.
public class Account: Item {
    /// A handle.
    @objc dynamic var handle: String?
    /// The name to display, for Persons this could be a first or last name, both, or a
    /// phonenumber.
    @objc dynamic var displayName: String?
    /// A service of any kind.
    @objc dynamic var service: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// URL to avatar image used by WhatsApp.
    @objc dynamic var avatarUrl: String?

    /// The Person this Item belongs to.
    var belongsTo: Results<Person>? {
        edges("belongsTo")?.items(type: Person.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Results<Location>? {
        edges("location")?.items(type: Location.self)
    }

    /// An organization, for instance an NGO, company or school.
    var organization: Results<Organization>? {
        edges("organization")?.items(type: Organization.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            handle = try decoder.decodeIfPresent("handle") ?? handle
            displayName = try decoder.decodeIfPresent("displayName") ?? displayName
            service = try decoder.decodeIfPresent("service") ?? service
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            avatarUrl = try decoder.decodeIfPresent("avatarUrl") ?? avatarUrl

            try self.superDecode(from: decoder)
        }
    }
}

/// A postal address.
public class Address: Item {
    /// The latitude of a location in WGS84 format.
    let latitude = RealmOptional<Double>()
    /// The longitude of a location in WGS84 format.
    let longitude = RealmOptional<Double>()
    /// A city or town.
    @objc dynamic var city: String?
    /// The postal code. For example, 94043.
    @objc dynamic var postalCode: String?
    /// A state or province of a country.
    @objc dynamic var state: String?
    /// The street address. For example, 1600 Amphitheatre Pkwy.
    @objc dynamic var street: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// A location with a automatic lookup hash.
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
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value
            city = try decoder.decodeIfPresent("city") ?? city
            postalCode = try decoder.decodeIfPresent("postalCode") ?? postalCode
            state = try decoder.decodeIfPresent("state") ?? state
            street = try decoder.decodeIfPresent("street") ?? street
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            locationAutoLookupHash = try decoder
                .decodeIfPresent("locationAutoLookupHash") ?? locationAutoLookupHash

            try self.superDecode(from: decoder)
        }
    }
}

/// An article, for instance from a journal, magazine or newspaper.
public class Article: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// A comment on this Item.
    var comment: Results<Comment>? {
        edges("comment")?.items(type: Comment.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// An audio file.
public class Audio: Item {
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
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?

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
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            caption = try decoder.decodeIfPresent("caption") ?? caption
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class AuditItem: Item {
    /// The date related to an Item.
    @objc dynamic var date: Date?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// Some action that can be taken by some Item.
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
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            definition = try decoder.decodeIfPresent("definition") ?? definition
            domain = try decoder.decodeIfPresent("domain") ?? domain
            name = try decoder.decodeIfPresent("name") ?? name
            query = try decoder.decodeIfPresent("query") ?? query
            selector = try decoder.decodeIfPresent("selector") ?? selector
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A comment.
public class Comment: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A country.
public class Country: Item {
    /// The latitude of a location in WGS84 format.
    let latitude = RealmOptional<Double>()
    /// The longitude of a location in WGS84 format.
    let longitude = RealmOptional<Double>()
    /// The name of the item.
    @objc dynamic var name: String?

    /// The flag that represents some Item, for instance a Country.
    var flag: Photo? {
        edge("flag")?.target(type: Photo.self)
    }

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Location? {
        edge("location")?.target(type: Location.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            latitude.value = try decoder.decodeIfPresent("latitude") ?? latitude.value
            longitude.value = try decoder.decodeIfPresent("longitude") ?? longitude.value
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// The most generic kind of creative work, including books, movies, photographs, software programs,
/// etc.
public class CreativeWork: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A key used in an cryptography protocol.
public class CryptoKey: Item {
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// A role describes the function of the item in their context.
    @objc dynamic var role: String?
    /// A piece of information that determines the functional output of a cryptographic
    /// algorithm.
    @objc dynamic var key: String?
    /// Whether the item is active.
    @objc dynamic var active: Bool = false
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            role = try decoder.decodeIfPresent("role") ?? role
            key = try decoder.decodeIfPresent("key") ?? key
            active = try decoder.decodeIfPresent("active") ?? active
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
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The duration of an Item, for instance an event or an Audio file.
    let duration = RealmOptional<Int>()

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// An included Product.
    var includedProduct: Results<Product>? {
        edges("includedProduct")?.items(type: Product.self)
    }

    /// An excluded Product.
    var excludedProduct: Results<Product>? {
        edges("excludedProduct")?.items(type: Product.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value

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
    /// Used to describe edge types in front end, will be deprecated in the near future.
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
            targetItemType = try decoder.decodeIfPresent("targetType") ?? targetItemType
            targetItemID.value = try decoder.decodeIfPresent("uid") ?? targetItemID.value
            sequence.value = try decoder.decodeIfPresent("sequence") ?? sequence.value
            deleted = try decoder.decodeIfPresent("deleted") ?? deleted
            version = try decoder.decodeIfPresent("version") ?? version
            edgeLabel = try decoder.decodeIfPresent("edgeLabel") ?? edgeLabel

            try parseTargetDict(try decoder.decodeIfPresent("_target"))
        }
    }
}

/// A single email message.
public class EmailMessage: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The subject of some Item.
    @objc dynamic var subject: String?
    /// Datetime when Item was sent.
    @objc dynamic var dateSent: Date?
    /// Datetime when Item was received.
    @objc dynamic var dateReceived: Date?
    /// A service of any kind.
    @objc dynamic var service: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// A message channel this Item belongs to, for instance a WhatsApp chat.
    var messageChannel: Results<MessageChannel>? {
        edges("messageChannel")?.items(type: MessageChannel.self)
    }

    /// The sender of an Item.
    var sender: Results<Account>? {
        edges("sender")?.items(type: Account.self)
    }

    /// The account that received, or is to receive, this Item.
    var receiver: Results<Account>? {
        edges("receiver")?.items(type: Account.self)
    }

    /// Accounts this Message is sent to beside the receiver.
    var cc: Results<Account>? {
        edges("cc")?.items(type: Account.self)
    }

    /// Accounts this Message is sent to beside the receiver, without showing this to the
    /// primary receiver.
    var bcc: Results<Account>? {
        edges("bcc")?.items(type: Account.self)
    }

    /// The Account that is replied to.
    var replyTo: Results<Account>? {
        edges("replyTo")?.items(type: Account.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            subject = try decoder.decodeIfPresent("subject") ?? subject
            dateSent = try decoder.decodeIfPresent("dateSent") ?? dateSent
            dateReceived = try decoder.decodeIfPresent("dateReceived") ?? dateReceived
            service = try decoder.decodeIfPresent("service") ?? service

            try self.superDecode(from: decoder)
        }
    }
}

/// Any kind of event, for instance a music festival or a business meeting.
public class Event: Item {
    /// Intended group that would consume or receive this Item.
    @objc dynamic var audience: String?
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The endTime of something. For a reserved event or service, the time that it is expected
    /// to end. For actions that span a period of time, when the action was performed. e.g. John wrote a
    /// book from January to December. For media, including audio and video, it's the time offset of the
    /// end of a clip within a larger file.
    @objc dynamic var endTime: Date?
    /// The duration of an Item, for instance an event or an Audio file.
    let duration = RealmOptional<Int>()
    /// The status of an event, for instance cancelled.
    @objc dynamic var eventStatus: String?

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Results<Location>? {
        edges("location")?.items(type: Location.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// Another (smaller) organization that is part of this Organization.
    var subEvent: Results<Organization>? {
        edges("subEvent")?.items(type: Organization.self)
    }

    /// The capacity of an Item, for instance the maximum number of attendees of an Event.
    var capacity: Results<Measure>? {
        edges("capacity")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            audience = try decoder.decodeIfPresent("audience") ?? audience
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            eventStatus = try decoder.decodeIfPresent("eventStatus") ?? eventStatus

            try self.superDecode(from: decoder)
        }
    }
}

/// Fitness-related activity designed for a specific health-related purpose, including defined
/// exercise routines as well as activity prescribed by a clinician.
public class ExercisePlan: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The duration of an Item, for instance an event or an Audio file.
    let duration = RealmOptional<Int>()
    /// The number of times something is repeated.
    let repetitions = RealmOptional<Int>()

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// The amount of energy something takes.
    var workload: Results<Measure>? {
        edges("workload")?.items(type: Measure.self)
    }

    /// The frequency of an Item.
    var frequency: Results<Frequency>? {
        edges("frequency")?.items(type: Frequency.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            repetitions.value = try decoder.decodeIfPresent("repetitions") ?? repetitions.value

            try self.superDecode(from: decoder)
        }
    }
}

/// Any file that can be stored on disk.
public class File: Item {
    /// The sha256 hash of a resource.
    @objc dynamic var sha256: String?
    /// A cryptographic nonce https://en.wikipedia.org/wiki/Cryptographic_nonce
    @objc dynamic var nonce: String?
    /// A piece of information that determines the functional output of a cryptographic
    /// algorithm.
    @objc dynamic var key: String?
    /// The filename of a resource.
    @objc dynamic var filename: String?

    /// A universal resource location
    var resource: Results<Resource>? {
        edges("resource")?.items(type: Resource.self)
    }

    /// An Item this Item is used by.
    var usedBy: [Item]? {
        edges("usedBy")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            sha256 = try decoder.decodeIfPresent("sha256") ?? sha256
            nonce = try decoder.decodeIfPresent("nonce") ?? nonce
            key = try decoder.decodeIfPresent("key") ?? key
            filename = try decoder.decodeIfPresent("filename") ?? filename

            try self.superDecode(from: decoder)
        }
    }
}

/// The number of occurrences of a repeating event per measure of time.
public class Frequency: Item {
    /// The number of occurrences.
    @objc dynamic var occurrences: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            occurrences = try decoder.decodeIfPresent("occurrences") ?? occurrences

            try self.superDecode(from: decoder)
        }
    }
}

/// Any kind of (video) game, typically rule-governed recreational activities.
public class Game: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A generic attribute that can be referenced by an Item.
public class GenericAttribute: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// A boolean value.
    @objc dynamic var boolValue: Bool = false
    /// A datetime value.
    @objc dynamic var datetimeValue: Date?
    /// A floating point value.
    let floatValue = RealmOptional<Double>()
    /// An integer value.
    let intValue = RealmOptional<Int>()
    /// A string value.
    @objc dynamic var stringValue: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            boolValue = try decoder.decodeIfPresent("boolValue") ?? boolValue
            datetimeValue = try decoder.decodeIfPresent("datetimeValue") ?? datetimeValue
            floatValue.value = try decoder.decodeIfPresent("floatValue") ?? floatValue.value
            intValue.value = try decoder.decodeIfPresent("intValue") ?? intValue.value
            stringValue = try decoder.decodeIfPresent("stringValue") ?? stringValue

            try self.superDecode(from: decoder)
        }
    }
}

/// Instructions that explain how to achieve a result by performing a sequence of steps.
public class HowTo: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// An Importer is used to import data from an external source to the Pod database.
public class Importer: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// Repository associated with this item, e.g. used by Pod to start appropriate integrator
    /// container.
    @objc dynamic var repository: String?
    /// The type of the data this Item acts on.
    @objc dynamic var dataType: String?
    /// A graphic symbol to represent some Item.
    @objc dynamic var icon: String?
    /// An image in the Xcode bundle.
    @objc dynamic var bundleImage: String?

    /// A run of a certain Importer, that defines the details of the specific import.
    var importerRun: Results<ImporterRun>? {
        edges("importerRun")?.items(type: ImporterRun.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            repository = try decoder.decodeIfPresent("repository") ?? repository
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
    /// Repository associated with this item, e.g. used by Pod to start appropriate integrator
    /// container.
    @objc dynamic var repository: String?
    /// The progress an Item made. Encoded as a float number from 0.0 to 1.0.
    let progress = RealmOptional<Double>()
    /// The type of the data this Item acts on.
    @objc dynamic var dataType: String?
    /// Username of an importer.
    @objc dynamic var username: String?
    /// Password for a username.
    @objc dynamic var password: String?
    /// The status of a run, (running, error, etc).
    @objc dynamic var runStatus: String?
    /// Description of the error
    @objc dynamic var errorMessage: String?
    /// Message describing the progress of a process.
    @objc dynamic var progressMessage: String?

    /// An Importer is used to import data from an external source to the Pod database.
    var importer: Importer? {
        edge("importer")?.target(type: Importer.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            repository = try decoder.decodeIfPresent("repository") ?? repository
            progress.value = try decoder.decodeIfPresent("progress") ?? progress.value
            dataType = try decoder.decodeIfPresent("dataType") ?? dataType
            username = try decoder.decodeIfPresent("username") ?? username
            password = try decoder.decodeIfPresent("password") ?? password
            runStatus = try decoder.decodeIfPresent("runStatus") ?? runStatus
            errorMessage = try decoder.decodeIfPresent("errorMessage") ?? errorMessage
            progressMessage = try decoder.decodeIfPresent("progressMessage") ?? progressMessage

            try self.superDecode(from: decoder)
        }
    }
}

/// An indexer enhances your personal data by inferring facts over existing data and adding those to
/// the database.
public class Indexer: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// Repository associated with this item, e.g. used by Pod to start appropriate integrator
    /// container.
    @objc dynamic var repository: String?
    /// A graphic symbol to represent some Item.
    @objc dynamic var icon: String?
    /// A Memri query that retrieves a set of Items from the Pod database.
    @objc dynamic var query: String?
    /// An image in the Xcode bundle.
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
            repository = try decoder.decodeIfPresent("repository") ?? repository
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
    /// Repository associated with this item, e.g. used by Pod to start appropriate integrator
    /// container.
    @objc dynamic var repository: String?
    /// A Memri query that retrieves a set of Items from the Pod database.
    @objc dynamic var query: String?
    /// The progress an Item made. Encoded as a float number from 0.0 to 1.0.
    let progress = RealmOptional<Double>()
    /// The type of data this Item targets.
    @objc dynamic var targetDataType: String?
    /// The status of a run, (running, error, etc).
    @objc dynamic var runStatus: String?
    /// Description of the error
    @objc dynamic var errorMessage: String?
    /// Message describing the progress of a process.
    @objc dynamic var progressMessage: String?

    /// An Indexer is used to enrich data in the Pod database.
    var indexer: Indexer? {
        edge("indexer")?.target(type: Indexer.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            repository = try decoder.decodeIfPresent("repository") ?? repository
            query = try decoder.decodeIfPresent("query") ?? query
            progress.value = try decoder.decodeIfPresent("progress") ?? progress.value
            targetDataType = try decoder.decodeIfPresent("targetDataType") ?? targetDataType
            runStatus = try decoder.decodeIfPresent("runStatus") ?? runStatus
            errorMessage = try decoder.decodeIfPresent("errorMessage") ?? errorMessage
            progressMessage = try decoder.decodeIfPresent("progressMessage") ?? progressMessage

            try self.superDecode(from: decoder)
        }
    }
}

/// A sector that produces goods or related services within an economy.
public class Industry: Item {
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// An integrator operates on your database enhances your personal data by inferring facts over
/// existing data and adding those to the database.
public class Integrator: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// Repository associated with this item, e.g. used by Pod to start appropriate integrator
    /// container.
    @objc dynamic var repository: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            repository = try decoder.decodeIfPresent("repository") ?? repository

            try self.superDecode(from: decoder)
        }
    }
}

/// A Receipt is a confirmation of a transaction.
public class Invoice: Item {
    /// Any type of file that can be stored on disk.
    var file: File? {
        edge("file")?.target(type: File.self)
    }

    /// An agreement between a buyer and a seller to exchange an asset for payment.
    var transaction: Transaction? {
        edge("transaction")?.target(type: Transaction.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
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
    /// Data that cannot directly be imported in the appropriate Items (yet), in JSON format
    @objc dynamic var importJson: String? = nil
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
        importJson = try decoder.decodeIfPresent("importJson") ?? importJson
        decodeEdges(decoder, "allEdges", self as! Item)
    }

    private enum CodingKeys: String, CodingKey {
        case dateAccessed, dateCreated, dateModified, deleted, externalId, itemDescription, starred,
             version, uid, importJson, allEdges
    }
}

/// Attached to an Item, to mark it to be something.
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

/// A potential offer.
public class Lead: Item {
    /// A potential offer.
    var offer: Results<Offer>? {
        edges("offer")?.items(type: Offer.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
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

/// A material that an Item is (partially) made from, for instance cotton, paper, steel, etc.
public class Material: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// The default quantity, for instance 1 g or 0.25 L
    @objc dynamic var defaultQuantity: String?

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            defaultQuantity = try decoder.decodeIfPresent("defaultQuantity") ?? defaultQuantity

            try self.superDecode(from: decoder)
        }
    }
}

/// A measure consists of a definition, symbol, unit and value (int, float, string, bool, or
/// datetime).
public class Measure: Item {
    /// The definition of an Item.
    @objc dynamic var definition: String?
    /// A symbol, for instance to represent a Unit or Measure.
    @objc dynamic var symbol: String?
    /// An integer value.
    let intValue = RealmOptional<Int>()
    /// A floating point value.
    let floatValue = RealmOptional<Double>()
    /// A string value.
    @objc dynamic var stringValue: String?
    /// A datetime value.
    @objc dynamic var datetimeValue: Date?
    /// A boolean value.
    @objc dynamic var boolValue: Bool = false

    /// A unit, typically from International System of Units (SI).
    var unit: Unit? {
        edge("unit")?.target(type: Unit.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            definition = try decoder.decodeIfPresent("definition") ?? definition
            symbol = try decoder.decodeIfPresent("symbol") ?? symbol
            intValue.value = try decoder.decodeIfPresent("intValue") ?? intValue.value
            floatValue.value = try decoder.decodeIfPresent("floatValue") ?? floatValue.value
            stringValue = try decoder.decodeIfPresent("stringValue") ?? stringValue
            datetimeValue = try decoder.decodeIfPresent("datetimeValue") ?? datetimeValue
            boolValue = try decoder.decodeIfPresent("boolValue") ?? boolValue

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
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?

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
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime

            try self.superDecode(from: decoder)
        }
    }
}

/// Any condition of the human body that affects the normal functioning of a person, whether
/// physically or mentally. Includes diseases, injuries, disabilities, disorders, syndromes, etc.
public class MedicalCondition: Item {
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A single message.
public class Message: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The subject of some Item.
    @objc dynamic var subject: String?
    /// Datetime when Item was sent.
    @objc dynamic var dateSent: Date?
    /// Datetime when Item was received.
    @objc dynamic var dateReceived: Date?
    /// A service of any kind.
    @objc dynamic var service: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// A message channel this Item belongs to, for instance a WhatsApp chat.
    var messageChannel: Results<MessageChannel>? {
        edges("messageChannel")?.items(type: MessageChannel.self)
    }

    /// The sender of an Item.
    var sender: Results<Account>? {
        edges("sender")?.items(type: Account.self)
    }

    /// The account that received, or is to receive, this Item.
    var receiver: Results<Account>? {
        edges("receiver")?.items(type: Account.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            subject = try decoder.decodeIfPresent("subject") ?? subject
            dateSent = try decoder.decodeIfPresent("dateSent") ?? dateSent
            dateReceived = try decoder.decodeIfPresent("dateReceived") ?? dateReceived
            service = try decoder.decodeIfPresent("service") ?? service

            try self.superDecode(from: decoder)
        }
    }
}

/// A chat is a collection of messages.
public class MessageChannel: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// The topic of an item, for instance a Chat.
    @objc dynamic var topic: String?
    /// Whether the item is encrypted.
    @objc dynamic var encrypted: Bool = false

    /// A photo object.
    var photo: Results<Photo>? {
        edges("photo")?.items(type: Photo.self)
    }

    /// The account that received, or is to receive, this Item.
    var receiver: Results<Account>? {
        edges("receiver")?.items(type: Account.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            topic = try decoder.decodeIfPresent("topic") ?? topic
            encrypted = try decoder.decodeIfPresent("encrypted") ?? encrypted

            try self.superDecode(from: decoder)
        }
    }
}

/// A way of transportation, for instance a bus or airplane.
public class ModeOfTransport: Item {
    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// Any type of video, for instance a movie, TV show, animation etc.
public class MovingImage: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// TBD
public class NavigationItem: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// Name of a Session.
    @objc dynamic var sessionName: String?
    /// Used to define position in a sequence, enables ordering based on this number.
    let sequence = RealmOptional<Int>()
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            sessionName = try decoder.decodeIfPresent("sessionName") ?? sessionName
            sequence.value = try decoder.decodeIfPresent("sequence") ?? sequence.value
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A group or system of interconnected people or things, for instance a social network.
public class Network: Item {
    /// The name of the item.
    @objc dynamic var name: String?

    /// An organization, for instance an NGO, company or school.
    var organization: Organization? {
        edge("organization")?.target(type: Organization.self)
    }

    /// A universal resource location
    var resource: Results<Resource>? {
        edges("resource")?.items(type: Resource.self)
    }

    /// A WebSite is a set of related web pages and other items typically served from a single
    /// web domain and accessible via URLs.
    var website: Results<Website>? {
        edges("website")?.items(type: Website.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A file containing a note.
public class Note: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// A comment on this Item.
    var comment: Results<Comment>? {
        edges("comment")?.items(type: Comment.self)
    }

    /// List occurs in Note.
    var noteList: Results<NoteList>? {
        edges("noteList")?.items(type: NoteList.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A list in a note.
public class NoteList: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// Category of this item.
    @objc dynamic var category: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// Range of an item in a piece of text.
    var span: Results<Span>? {
        edges("span")?.items(type: Span.self)
    }

    /// span of an item in a list that lives in text.
    var itemSpan: Results<Span>? {
        edges("itemSpan")?.items(type: Span.self)
    }

    /// Note of an item.
    var note: Results<Note>? {
        edges("note")?.items(type: Note.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            category = try decoder.decodeIfPresent("category") ?? category

            try self.superDecode(from: decoder)
        }
    }
}

/// An offer for some transaction, for instance to buy something or to get some service.
public class Offer: Item {
    /// An agreement between a buyer and a seller to exchange an asset for payment.
    var transaction: Results<Transaction>? {
        edges("transaction")?.items(type: Transaction.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// Hours that an organization is open.
public class OpeningHours: Item {
    /// A timeframe.
    var timeFrame: Results<TimeFrame>? {
        edges("timeFrame")?.items(type: TimeFrame.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// An option for some choice, for instance a Vote.
public class Option: Item {
    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// An organization, for instance an NGO, company or school.
public class Organization: Item {
    /// The name of the item.
    @objc dynamic var name: String?
    /// Date that the Item was founded.
    @objc dynamic var dateFounded: Date?
    /// The area that this Item operates in.
    @objc dynamic var areaServed: String?
    /// A fiscal identifier.
    @objc dynamic var taxId: String?

    /// Physical address of the event or place.
    var address: Results<Address>? {
        edges("address")?.items(type: Address.self)
    }

    /// The place where the Item was founded.
    var foundingLocation: Results<Location>? {
        edges("foundingLocation")?.items(type: Location.self)
    }

    /// A logo that belongs to an Item
    var logo: Results<Photo>? {
        edges("logo")?.items(type: Photo.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// Another (smaller) Event that takes place at this Event
    var subOrganization: Results<Event>? {
        edges("subOrganization")?.items(type: Event.self)
    }

    /// The Event this Item organizes.
    var performsAt: Results<Event>? {
        edges("performsAt")?.items(type: Event.self)
    }

    /// The Event this Item attends.
    var attends: Results<Event>? {
        edges("attends")?.items(type: Event.self)
    }

    /// The Event this Item attends.
    var organizes: Results<Event>? {
        edges("organizes")?.items(type: Event.self)
    }

    /// Hours that an organization is open.
    var openingHours: Results<OpeningHours>? {
        edges("openingHours")?.items(type: OpeningHours.self)
    }

    /// A sector that produces goods or related services within an economy.
    var industry: Results<Industry>? {
        edges("industry")?.items(type: Industry.self)
    }

    /// The buying party in a transaction.
    var buyer: Results<Transaction>? {
        edges("buyer")?.items(type: Transaction.self)
    }

    /// The buying party in a transaction.
    var seller: Results<Transaction>? {
        edges("seller")?.items(type: Transaction.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            name = try decoder.decodeIfPresent("name") ?? name
            dateFounded = try decoder.decodeIfPresent("dateFounded") ?? dateFounded
            areaServed = try decoder.decodeIfPresent("areaServed") ?? areaServed
            taxId = try decoder.decodeIfPresent("taxId") ?? taxId

            try self.superDecode(from: decoder)
        }
    }
}

/// A work of performing art, for instance dance, theater, opera or musical.
public class PerformingArt: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

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
    /// The name to display, for Persons this could be a first or last name, both, or a
    /// phonenumber.
    @objc dynamic var displayName: String?
    /// A role describes the function of the item in their context.
    @objc dynamic var role: String?

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

    /// A sector that produces goods or related services within an economy.
    var industry: Results<Industry>? {
        edges("industry")?.items(type: Industry.self)
    }

    /// A crypto key used in a cryptography protocol.
    var cryptoKey: Results<CryptoKey>? {
        edges("cryptoKey")?.items(type: CryptoKey.self)
    }

    /// An account or subscription, for instance for some online service, or a bank account or
    /// wallet.
    var account: Results<Account>? {
        edges("account")?.items(type: Account.self)
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

    /// The organization this Item is a member of.
    var memberOf: Results<Organization>? {
        edges("memberOf")?.items(type: Organization.self)
    }

    /// The Event this Item organizes.
    var performsAt: Results<Event>? {
        edges("performsAt")?.items(type: Event.self)
    }

    /// The Event this Item attends.
    var attends: Results<Event>? {
        edges("attends")?.items(type: Event.self)
    }

    /// The Event this Item attends.
    var organizes: Results<Event>? {
        edges("organizes")?.items(type: Event.self)
    }

    /// The Organization this Item has founded.
    var founded: Results<Organization>? {
        edges("founded")?.items(type: Organization.self)
    }

    /// The buying party in a transaction.
    var buyer: Results<Transaction>? {
        edges("buyer")?.items(type: Transaction.self)
    }

    /// The buying party in a transaction.
    var seller: Results<Transaction>? {
        edges("seller")?.items(type: Transaction.self)
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
            displayName = try decoder.decodeIfPresent("displayName") ?? displayName
            role = try decoder.decodeIfPresent("role") ?? role

            try self.superDecode(from: decoder)
        }
    }
}

/// A telephone number.
public class PhoneNumber: Item {
    /// A phone number with an area code.
    @objc dynamic var phoneNumber: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            phoneNumber = try decoder.decodeIfPresent("phoneNumber") ?? phoneNumber
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// An image file.
public class Photo: Item {
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
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// Exif data of an image file.
    @objc dynamic var exifData: String?
    /// The name of the item.
    @objc dynamic var name: String?

    /// Any type of file that can be stored on disk.
    var file: File? {
        edge("file")?.target(type: File.self)
    }

    /// Items included within this Item. Included Items can be of any type.
    var includes: [Item]? {
        edges("includes")?.itemsArray()
    }

    /// Thumbnail image for an Item, typically an image or video.
    var thumbnail: File? {
        edge("thumbnail")?.target(type: File.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            bitrate.value = try decoder.decodeIfPresent("bitrate") ?? bitrate.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime
            fileLocation = try decoder.decodeIfPresent("fileLocation") ?? fileLocation
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// Some object that exists in the real world.
public class PhysicalEntity: Item {
    /// The Person this Item belongs to.
    var belongsTo: Results<Person>? {
        edges("belongsTo")?.items(type: Person.self)
    }

    /// An instance of an Item, for instance the PhysicalEntity instance of a Book.
    var instanceOf: [Item]? {
        edges("instanceOf")?.itemsArray()
    }

    /// The location of for example where the event is happening, an organization is located, or
    /// where an action takes place.
    var location: Results<Location>? {
        edges("location")?.items(type: Location.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// Any product.
public class Product: Item {
    /// Intended group that would consume or receive this Item.
    @objc dynamic var audience: String?
    /// The color of this Item.
    @objc dynamic var color: String?
    /// The manufacturer of the Item
    @objc dynamic var manufacturer: String?
    /// The model number or name of an Item, for instance of a mobile phone.
    @objc dynamic var model: String?
    /// A repeated decorative design.
    @objc dynamic var pattern: String?
    /// The date this item was acquired.
    @objc dynamic var dateAcquired: Date?
    /// A description of the condition of a product, for instance new.
    @objc dynamic var productCondition: String?
    /// The date the Item was produced.
    @objc dynamic var dateProduced: Date?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// A service of any kind.
    @objc dynamic var service: String?

    /// The material the Item is (partially) made of.
    var material: Results<Material>? {
        edges("material")?.items(type: Material.self)
    }

    /// A type of code related to a Product.
    var productCode: Results<ProductCode>? {
        edges("productCode")?.items(type: ProductCode.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// Product fo which this Item is a spare part or accessory.
    var accessoryOrSparePartFor: Results<Product>? {
        edges("accessoryOrSparePartFor")?.items(type: Product.self)
    }

    /// Product that consumes this Item, for instance the printer that takes this ink
    /// cartridge.
    var consumableBy: Results<Product>? {
        edges("consumableBy")?.items(type: Product.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            audience = try decoder.decodeIfPresent("audience") ?? audience
            color = try decoder.decodeIfPresent("color") ?? color
            manufacturer = try decoder.decodeIfPresent("manufacturer") ?? manufacturer
            model = try decoder.decodeIfPresent("model") ?? model
            pattern = try decoder.decodeIfPresent("pattern") ?? pattern
            dateAcquired = try decoder.decodeIfPresent("dateAcquired") ?? dateAcquired
            productCondition = try decoder.decodeIfPresent("productCondition") ?? productCondition
            dateProduced = try decoder.decodeIfPresent("dateProduced") ?? dateProduced
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            service = try decoder.decodeIfPresent("service") ?? service

            try self.superDecode(from: decoder)
        }
    }
}

/// A code or number used to identify Products, for instance a UPC or GTIN.
public class ProductCode: Item {
    /// An identifier type for Products, for instance a UPC or GTIN.
    @objc dynamic var productCodeType: String?
    /// An identifier for Products, for instance a UPC or GTIN.
    @objc dynamic var productNumber: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            productCodeType = try decoder.decodeIfPresent("productCodeType") ?? productCodeType
            productNumber = try decoder.decodeIfPresent("productNumber") ?? productNumber

            try self.superDecode(from: decoder)
        }
    }
}

/// A bill that describes money owed for some Transaction.
public class Receipt: Item {
    /// The date something is due.
    @objc dynamic var dateDue: Date?

    /// Any type of file that can be stored on disk.
    var file: File? {
        edge("file")?.target(type: File.self)
    }

    /// An agreement between a buyer and a seller to exchange an asset for payment.
    var transaction: Transaction? {
        edge("transaction")?.target(type: Transaction.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            dateDue = try decoder.decodeIfPresent("dateDue") ?? dateDue

            try self.superDecode(from: decoder)
        }
    }
}

/// A set of instructions for preparing a particular dish, including a list of the ingredients
/// required.
public class Recipe: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The duration of an Item, for instance an event or an Audio file.
    let duration = RealmOptional<Int>()
    /// A set of steps to reach a certain goal.
    @objc dynamic var instructions: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// An ingredient of an Item.
    var ingredient: Results<Product>? {
        edges("ingredient")?.items(type: Product.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    /// The amount produced or financial return.
    var yields: Results<Measure>? {
        edges("yields")?.items(type: Measure.self)
    }

    /// Some tool required by an Item.
    var toolRequired: Results<Product>? {
        edges("toolRequired")?.items(type: Product.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            instructions = try decoder.decodeIfPresent("instructions") ?? instructions

            try self.superDecode(from: decoder)
        }
    }
}

/// A audio performance or production. Can be a single, album, radio show, podcast etc.
public class Recording: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// Describes a reservation, for instance for a Route or Event, or at a Organization.
public class Reservation: Item {
    /// Reservation date.
    @objc dynamic var dateReserved: Date?
    /// The status of a reservation, for instance cancelled.
    @objc dynamic var reservationStatus: String?

    /// An organization, for instance an NGO, company or school.
    var organization: Results<Organization>? {
        edges("organization")?.items(type: Organization.self)
    }

    /// A route from one Location to another, using some ModeOfTransport.
    var route: Results<Route>? {
        edges("route")?.items(type: Route.self)
    }

    /// The Person who made this reservation.
    var reservedBy: Results<Person>? {
        edges("reservedBy")?.items(type: Person.self)
    }

    /// A Person for whom this reservation was made.
    var reservedFor: Results<Person>? {
        edges("reservedFor")?.items(type: Person.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            dateReserved = try decoder.decodeIfPresent("dateReserved") ?? dateReserved
            reservationStatus = try decoder
                .decodeIfPresent("reservationStatus") ?? reservationStatus

            try self.superDecode(from: decoder)
        }
    }
}

/// A universal resource location
public class Resource: Item {
    /// The url property represents the Uniform Resource Location (URL) of a resource.
    @objc dynamic var url: String?

    /// An Item this Item is used by.
    var usedBy: [Item]? {
        edges("usedBy")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            url = try decoder.decodeIfPresent("url") ?? url

            try self.superDecode(from: decoder)
        }
    }
}

/// A review of an Item, for instance a Organization, CreativeWork, or Product.
public class Review: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    /// A rating is an evaluation using some Measure, for instance 1 to 5 stars.
    var rating: Results<Measure>? {
        edges("rating")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// A route from one Location to another, using some ModeOfTransport.
public class Route: Item {
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The endTime of something. For a reserved event or service, the time that it is expected
    /// to end. For actions that span a period of time, when the action was performed. e.g. John wrote a
    /// book from January to December. For media, including audio and video, it's the time offset of the
    /// end of a clip within a larger file.
    @objc dynamic var endTime: Date?

    /// A way of transportation, for instance a bus or airplane.
    var modeOfTransport: Results<ModeOfTransport>? {
        edges("modeOfTransport")?.items(type: ModeOfTransport.self)
    }

    /// The location where some Item starts, for instance the start of a route.
    var startLocation: Results<Location>? {
        edges("startLocation")?.items(type: Location.self)
    }

    /// The location where some Item ends, for instance the destination of a route.
    var endLocation: Results<Location>? {
        edges("endLocation")?.items(type: Location.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    /// A Receipt is a confirmation of a transaction.
    var receipt: Results<Receipt>? {
        edges("receipt")?.items(type: Receipt.self)
    }

    /// A ticket for an Event or Route.
    var ticket: Results<File>? {
        edges("ticket")?.items(type: File.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime

            try self.superDecode(from: decoder)
        }
    }
}

/// A setting, named by a key, specifications in JSON format.
public class Setting: Item {
    /// A piece of information that determines the functional output of a cryptographic
    /// algorithm.
    @objc dynamic var key: String?
    /// A string in JSON (JavaScript Object Notation) format.
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

/// A class that represents a position of an element in a string.
public class Span: Item {
    /// Start position of an element.
    let startIdx = RealmOptional<Int>()
    /// End position of an element.
    let endIdx = RealmOptional<Int>()

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            startIdx.value = try decoder.decodeIfPresent("startIdx") ?? startIdx.value
            endIdx.value = try decoder.decodeIfPresent("endIdx") ?? endIdx.value

            try self.superDecode(from: decoder)
        }
    }
}

/// A specified period of time in which something occurs or is planned to take place.
public class TimeFrame: Item {
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The endTime of something. For a reserved event or service, the time that it is expected
    /// to end. For actions that span a period of time, when the action was performed. e.g. John wrote a
    /// book from January to December. For media, including audio and video, it's the time offset of the
    /// end of a clip within a larger file.
    @objc dynamic var endTime: Date?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime

            try self.superDecode(from: decoder)
        }
    }
}

/// An agreement between a buyer and a seller to exchange an asset for payment.
public class Transaction: Item {
    /// Whether the Item is deleted.
    @objc dynamic var orderStatus: Bool = false
    /// Identifier of a transaction.
    @objc dynamic var orderNumber: String?
    /// Can be used to get a discount.
    @objc dynamic var discountCode: String?
    /// The date this Item was lost.
    @objc dynamic var dateOrdered: Date?
    /// Date of execution.
    @objc dynamic var dateExecuted: Date?

    /// The location depicted or described in the content. For example, the location in a
    /// photograph or painting.
    var purchaseLocation: Results<Location>? {
        edges("purchaseLocation")?.items(type: Location.self)
    }

    /// Any Product.
    var product: Results<Product>? {
        edges("product")?.items(type: Product.self)
    }

    /// The address associated with financial purchases.
    var billingAddress: Results<Address>? {
        edges("billingAddress")?.items(type: Address.self)
    }

    /// The Account used to pay.
    var payedWithAccount: Results<Account>? {
        edges("payedWithAccount")?.items(type: Account.self)
    }

    /// A discount or price reduction.
    var discount: Results<Measure>? {
        edges("discount")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            orderStatus = try decoder.decodeIfPresent("orderStatus") ?? orderStatus
            orderNumber = try decoder.decodeIfPresent("orderNumber") ?? orderNumber
            discountCode = try decoder.decodeIfPresent("discountCode") ?? discountCode
            dateOrdered = try decoder.decodeIfPresent("dateOrdered") ?? dateOrdered
            dateExecuted = try decoder.decodeIfPresent("dateExecuted") ?? dateExecuted

            try self.superDecode(from: decoder)
        }
    }
}

/// A trip or journey, consisting of Routes.
public class Trip: Item {
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The endTime of something. For a reserved event or service, the time that it is expected
    /// to end. For actions that span a period of time, when the action was performed. e.g. John wrote a
    /// book from January to December. For media, including audio and video, it's the time offset of the
    /// end of a clip within a larger file.
    @objc dynamic var endTime: Date?

    /// A route from one Location to another, using some ModeOfTransport.
    var route: Results<Route>? {
        edges("route")?.items(type: Route.self)
    }

    /// The location where some Item starts, for instance the start of a route.
    var startLocation: Results<Location>? {
        edges("startLocation")?.items(type: Location.self)
    }

    /// The location where some Item ends, for instance the destination of a route.
    var endLocation: Results<Location>? {
        edges("endLocation")?.items(type: Location.self)
    }

    /// The price or cost of an Item, typically for one instance of the Item or the
    /// defaultQuantity.
    var price: Results<Measure>? {
        edges("price")?.items(type: Measure.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime

            try self.superDecode(from: decoder)
        }
    }
}

/// A unit, typically from International System of Units (SI).
public class Unit: Item {
    /// A symbol, for instance to represent a Unit or Measure.
    @objc dynamic var symbol: String?
    /// The name of the item.
    @objc dynamic var name: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            symbol = try decoder.decodeIfPresent("symbol") ?? symbol
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A video file.
public class Video: Item {
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
    /// The startTime of something. For a reserved event or service, the time that it is
    /// expected to start. For actions that span a period of time, when the action was performed. e.g.
    /// John wrote a book from January to December. For media, including audio and video, it's the time
    /// offset of the start of a clip within a larger file.
    @objc dynamic var startTime: Date?
    /// The caption for this object. For downloadable machine formats (closed caption, subtitles
    /// etc.) use MediaObject and indicate the encodingFormat.
    @objc dynamic var caption: String?
    /// Exif data of an image file.
    @objc dynamic var exifData: String?
    /// The name of the item.
    @objc dynamic var name: String?

    /// Any type of file that can be stored on disk.
    var file: File? {
        edge("file")?.target(type: File.self)
    }

    /// Items included within this Item. Included Items can be of any type.
    var includes: [Item]? {
        edges("includes")?.itemsArray()
    }

    /// Thumbnail image for an Item, typically an image or video.
    var thumbnail: Results<File>? {
        edges("thumbnail")?.items(type: File.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            bitrate.value = try decoder.decodeIfPresent("bitrate") ?? bitrate.value
            duration.value = try decoder.decodeIfPresent("duration") ?? duration.value
            endTime = try decoder.decodeIfPresent("endTime") ?? endTime
            fileLocation = try decoder.decodeIfPresent("fileLocation") ?? fileLocation
            startTime = try decoder.decodeIfPresent("startTime") ?? startTime
            caption = try decoder.decodeIfPresent("caption") ?? caption
            exifData = try decoder.decodeIfPresent("exifData") ?? exifData
            name = try decoder.decodeIfPresent("name") ?? name

            try self.superDecode(from: decoder)
        }
    }
}

/// A work of visual arts, for instance a painting, sculpture or drawing.
public class VisualArt: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// An occasion where a choice is made choose between two or more options, for instance an election.
public class Vote: Item {
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

    /// An option for some choice, for instance a Vote.
    var option: Results<Option>? {
        edges("option")?.items(type: Option.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

/// The act casting a vote.
public class VoteAction: Item {
    /// Date of execution.
    @objc dynamic var dateExecuted: Date?

    /// An occasion where a choice is made choose between two or more options, for instance an
    /// election.
    var vote: Results<Vote>? {
        edges("vote")?.items(type: Vote.self)
    }

    /// An Item this Item is used by.
    var usedBy: [Item]? {
        edges("usedBy")?.itemsArray()
    }

    /// A chosen Option.
    var choice: Results<Option>? {
        edges("choice")?.items(type: Option.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            dateExecuted = try decoder.decodeIfPresent("dateExecuted") ?? dateExecuted

            try self.superDecode(from: decoder)
        }
    }
}

/// A Website is a set of related web pages and other items typically served from a single web
/// domain and accessible via URLs.
public class Website: Item {
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?
    /// The url property represents the Uniform Resource Location (URL) of a resource.
    @objc dynamic var url: String?

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType
            url = try decoder.decodeIfPresent("url") ?? url

            try self.superDecode(from: decoder)
        }
    }
}

/// A written work, for instance a book, article or note. Doesn't have to be published.
public class WrittenWork: Item {
    /// The title of an Item.
    @objc dynamic var title: String?
    /// An abstract is a short description that summarizes an Items content.
    @objc dynamic var abstract: String?
    /// Date of first broadcast/publication.
    @objc dynamic var datePublished: Date?
    /// Keywords or tags used to describe this content. Multiple entries in a keywords list are
    /// typically delimited by commas.
    @objc dynamic var keyword: String?
    /// The content of an Item.
    @objc dynamic var content: String?
    /// The plain text content of an Item, without styling or syntax for Markdown, HTML, etc.
    @objc dynamic var textContent: String?
    /// If this MediaObject is an AudioObject or VideoObject, the transcript of that object.
    @objc dynamic var transcript: String?
    /// The type or (sub)category of some Item.
    @objc dynamic var itemType: String?

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

    /// The author of this Item.
    var writtenBy: Results<Person>? {
        edges("writtenBy")?.items(type: Person.self)
    }

    /// Any type of file that can be stored on disk.
    var file: Results<File>? {
        edges("file")?.items(type: File.self)
    }

    /// The event where something is recorded.
    var recordedAt: Results<Event>? {
        edges("recordedAt")?.items(type: Event.self)
    }

    /// A review of the Item.
    var review: Results<Review>? {
        edges("review")?.items(type: Review.self)
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            title = try decoder.decodeIfPresent("title") ?? title
            abstract = try decoder.decodeIfPresent("abstract") ?? abstract
            datePublished = try decoder.decodeIfPresent("datePublished") ?? datePublished
            keyword = try decoder.decodeIfPresent("keyword") ?? keyword
            content = try decoder.decodeIfPresent("content") ?? content
            textContent = try decoder.decodeIfPresent("textContent") ?? textContent
            transcript = try decoder.decodeIfPresent("transcript") ?? transcript
            itemType = try decoder.decodeIfPresent("itemType") ?? itemType

            try self.superDecode(from: decoder)
        }
    }
}

func dataItemListToArray(_ object: Any) -> [Item] {
    var collection: [Item] = []

    if let list = object as? Results<Account> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Address> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Article> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Audio> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<AuditItem> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<CVUStateDefinition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<CVUStoredDefinition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<Comment> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Country> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<CreativeWork> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<CryptoKey> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Device> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Diet> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Downloader> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Edge> { return list.itemsArray() }
    else if let list = object as? Results<EmailMessage> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Event> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<ExercisePlan> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<File> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Frequency> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Game> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<GenericAttribute> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<HowTo> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Importer> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<ImporterRun> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Indexer> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<IndexerRun> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Industry> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Integrator> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Invoice> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Item> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Label> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Lead> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Location> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Material> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Measure> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<MediaObject> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<MedicalCondition> {
        list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<Message> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<MessageChannel> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<ModeOfTransport> { list.forEach { collection.append($0) }
    }
    else if let list = object as? Results<MovingImage> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<NavigationItem> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Network> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Note> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<NoteList> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Offer> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<OpeningHours> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Option> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Organization> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<PerformingArt> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Person> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<PhoneNumber> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Photo> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<PhysicalEntity> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Product> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<ProductCode> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Receipt> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Recipe> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Recording> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Reservation> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Resource> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Review> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Route> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Setting> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Span> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<TimeFrame> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Transaction> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Trip> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Unit> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Video> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<VisualArt> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Vote> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<VoteAction> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<Website> { list.forEach { collection.append($0) } }
    else if let list = object as? Results<WrittenWork> { list.forEach { collection.append($0) } }

    return collection
}
