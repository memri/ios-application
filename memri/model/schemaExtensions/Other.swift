//
// Other.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

extension Object {
    var genericType: String {
        objectSchema.className
    }
}

extension Note {
    override var computedTitle: String {
        "\(title ?? "")"
    }
}

extension PhoneNumber {
    override var computedTitle: String {
        phoneNumber ?? ""
    }
}

extension Website {
    override var computedTitle: String {
        url ?? ""
    }
}

extension Country {
    override var computedTitle: String {
        "\(name ?? "")"
    }
}

extension Address {
    override var computedTitle: String {
        //        \(type ?? "")
        """
        \(street ?? "")
        \(city ?? "")
        \(postalCode == nil ? "" : postalCode! + ",") \(state ?? "")
        \(edge("country")?.target()?.computedTitle ?? "")
        """
    }
}

extension Organization {
    override var computedTitle: String {
        name ?? ""
    }
}

extension Account {
    override var computedTitle: String {
        handle ?? ""
    }
}

extension Diet {
    override var computedTitle: String {
        itemType ?? ""
    }
}

extension MedicalCondition {
    override var computedTitle: String {
        itemType ?? ""
    }
}

extension Network {
    override var computedTitle: String {
        name ?? ""
    }
}

class Person: SchemaPerson {
    override var computedTitle: String {
        fullName
    }
    
    
    override var computedVars: [ComputedPropertyLink] {[
        ComputedPropertyLink(propertyName: "fullName", type: .string),
        ComputedPropertyLink(propertyName: "initials", type: .string),
        ComputedPropertyLink(propertyName: "age", type: .int)
    ]}
    
    // Full name in western style (first last)
    var fullName: String {
        "\(firstName ?? "") \(lastName ?? "")"
    }
    
    // Initials (two letters) in western style (FL)
    var initials: String {
        [firstName?.first, lastName?.first].compactMap { $0 }.map { String($0) }.joined()
    }

    /// Age in years
    var age: Int? {
        if let birthDate = birthDate {
            return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
        }
        return nil
    }

    required init() {
        super.init()

        functions["age"] = { _ in self.age }
        functions["fullName"] = { _ in self.fullName }
        functions["initials"] = { _ in self.initials }
    }
}

extension AuditItem {
    override var computedTitle: String {
        "Logged \(action ?? "unknown action") on \(date?.description ?? "")"
    }

    convenience init(
        date: Date? = nil,
        contents: String? = nil,
        action: String? = nil,
        appliesTo: [Item]? = nil
    ) throws {
        self.init()
        self.date = date ?? self.date
        content = content ?? content
        self.action = action ?? self.action

        if let appliesTo = appliesTo {
            for item in appliesTo {
                _ = try link(item, type: "appliesTo")
            }
        }
    }
}

extension Label {
    override var computedTitle: String {
        name ?? ""
    }
}

extension Photo {
    override var computedTitle: String {
        caption ?? ""
    }
}

extension Video {
    override var computedTitle: String {
        caption ?? ""
    }
}

extension Audio {
    override var computedTitle: String {
        caption ?? ""
    }
}

extension Importer {
    override var computedTitle: String {
        name ?? ""
    }
}

extension Indexer {
    override var computedTitle: String {
        name ?? ""
    }

    internal convenience init(
        name: String? = nil,
        itemDescription: String? = nil,
        query: String? = nil,
        icon: String? = nil,
        bundleImage: String? = nil,
        runDestination: String? = nil
    ) {
        self.init()
        self.name = name ?? self.name
        self.itemDescription = itemDescription ?? self.itemDescription
        self.query = query ?? self.query
        self.icon = icon ?? self.icon
        self.bundleImage = bundleImage ?? self.bundleImage
        self.runDestination = runDestination ?? self.runDestination
    }
}

extension IndexerRun {
    internal convenience init(
        name: String? = nil,
        query: String? = nil,
        indexer: Indexer? = nil,
        progress: Int? = nil
    ) {
        self.init()
        self.name = name ?? self.name
        self.query = query ?? self.query
        self.progress.value = progress ?? self.progress.value

        if let indexer = indexer { set("indexer", indexer) }
    }
}

extension CVUStateDefinition {
    public class func fromCVUStoredDefinition(_ stored: CVUStoredDefinition) throws
        -> CVUStateDefinition {
            try Cache.createItem(CVUStateDefinition.self, values: [
                "definition": stored.definition,
                "domain": "state",
                "name": stored.name,
                "query": stored.query,
                "selector": stored.selector,
                "itemType": stored.itemType,
            ])
        }

    public class func fromCVUParsedDefinition(_ parsed: CVUParsedDefinition) throws
        -> CVUStateDefinition {
            try Cache.createItem(CVUStateDefinition.self, values: [
                "definition": parsed.toCVUString(0, "    "),
                "domain": "state",
                "name": parsed.name,
//            "query": stores.query,
                "selector": parsed.selector,
                "itemType": parsed.definitionType,
            ])
        }
}

extension CVUStoredDefinition {
    override var computedTitle: String {
        #warning("Parse and then create a proper string representation")
        if let value = name, value != "" { return value }
        return "[No Name]"
    }
}


/// retrieves item from realm by type and uid.
/// - Parameters:
///   - type: realm type
///   - memriID: item memriID
/// - Returns: retrieved item. If the item does not exist, returns nil.
func getItem(_ type: String, _ uid: Int) -> Item? {
    let type = ItemFamily(rawValue: type)
    if let type = type {
        let item = ItemFamily.getType(type)
        return DatabaseController.sync {
            $0.object(ofType: item() as! Object.Type, forPrimaryKey: uid) as? Item
        }
    }
    return nil
}

func me() -> Person {
    do {
        let realm = try DatabaseController.getRealmSync()
        guard let myself = realm.objects(Person.self).filter("ANY allEdges.type = 'me'").first else {
            throw "Unexpected error. Cannot find 'me' in the database"
        }
        return myself
    }
    catch {
        return Person()
    }
}
