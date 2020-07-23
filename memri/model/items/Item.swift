//
// Item.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift

public class Item: SchemaItem {
    /// Title computed by implementations of the Item class
    @objc dynamic var computedTitle: String {
        "\(genericType) [\(uid.value ?? -1000)]"
    }

    var functions: [String: (_ args: [Any?]?) -> Any?] = [:]

    /// Primary key used in the realm database of this Item
    override public static func primaryKey() -> String? {
        "uid"
    }

//    extension SyncState {
//        override public var description: String {
//            "{"
//                + (actionNeeded != nil ? "\n        actionNeeded: \(actionNeeded ?? "")" : "")
//                + (isPartiallyLoaded ? "\n        isPartiallyLoaded: \(isPartiallyLoaded)" : "")
//                + (changedInThisSession ? "\n        changedInThisSession: \(changedInThisSession)" : "")
//                + (updatedFields.count > 0 ? "\n        updatedFields: [\(updatedFields.map { $0 }.joined(separator: ", "))]" : "")
//                + "\n    }"
//        }
//    }

    override public var description: String {
        var str = "\(genericType) \(realm == nil ? "[UNMANAGED] " : ""){\n"
            + "    uid: \(uid.value == nil ? "nil" : String(uid.value ?? 0))\n"
            +
            "    _updated: \(_updated.count == 0 ? "[]" : "[\(_updated.joined(separator: ", "))]")\n"
            + "    " + objectSchema.properties
            .filter {
                self[$0.name] != nil && $0.name != "allEdges" && $0.name != "uid"
                    && $0.name != "_updated"
            }
            .map { "\($0.name): \(CVUSerializer.valueToString(self[$0.name]))" }
            .joined(separator: "\n    ")

        str += (allEdges.count > 0 ? "\n\n    " : "")
            + allEdges
            .map { $0.description }
            .joined(separator: "\n    ")
            + "\n}"

        return str
    }

    enum ItemError: Error {
        case cannotMergeItemWithDifferentId
    }

    var changelog: Results<AuditItem>? {
        edges("changelog")?.items(type: AuditItem.self)
    }

    required init() {
        super.init()

        functions["describeChangelog"] = { _ in
            let dateCreated = Views.formatDate(self.dateCreated)
            let views = self.changelog?.filter { $0.action == "read" }.count ?? 0
            let edits = self.changelog?.filter { $0.action == "update" }.count ?? 0
            let timeSinceCreated = Views.formatDateSinceCreated(self.dateCreated)
            return "You created this \(self.genericType) \(dateCreated) and viewed it \(views) times and edited it \(edits) times over the past \(timeSinceCreated)"
        }
        functions["computedTitle"] = { _ in
            self.computedTitle
        }
        functions["edge"] = { args in
            if let edgeType = args?[0] as? String {
                return self.edge(edgeType)
            }
            else if let edgeTypes = args?[0] as? [String] {
                return self.edge(edgeTypes)
            }
            return nil
        }
        functions["edges"] = { args in
            if let edgeType = args?[0] as? String {
                return self.edges(edgeType)
            }
            else if let edgeTypes = args?[0] as? [String] {
                return self.edges(edgeTypes)
            }

            return nil
        }
        functions["min"] = { args in
            let first = args?[0] as? Double ?? Double.nan
            let second = args?[1] as? Double ?? Double.nan
            return min(first, second)
        }
        functions["max"] = { args in
            let first = args?[0] as? Double ?? Double.nan
            let second = args?[1] as? Double ?? Double.nan
            return max(first, second)
        }
        functions["floor"] = { args in
            let value = args?[0] as? Double ?? Double.nan
            return floor(value)
        }
        functions["ceil"] = { args in
            let value = args?[0] as? Double ?? Double.nan
            return ceil(value)
        }
    }

    required init(from _: Decoder) throws {
        super.init()
    }

    public func cast() -> Self {
        self
    }

    /// Get string, or string representation (e.g. "true) from property name
    /// - Parameter name: property name
    /// - Returns: string representation
    public func getString(_ name: String) -> String {
        if objectSchema[name] == nil {
            #if DEBUG
                print(
                    "Warning: getting property that this item doesnt have: \(name) for \(genericType):\(uid.value ?? -1000)"
                )
            #endif

            return ""
        }
        else {
            return ExprInterpreter.evaluateString(self[name], "")
        }
    }

    /// Get the type of Item
    /// - Returns: type of the Item
    public func getType() -> Item.Type? {
        if let type = ItemFamily(rawValue: genericType) {
            let T = ItemFamily.getType(type)
            // NOTE: allowed forced downcast
            return (T() as! Item.Type)
        }
        else {
            print("Cannot find type \(genericType) in ItemFamily")
            return nil
        }
    }

    /// Determines whether item has property
    /// - Parameter propName: name of the property
    /// - Returns: boolean indicating whether Item has the property
    public func hasProperty(_ propName: String) -> Bool {
        for prop in objectSchema.properties {
            if prop.name == propName { return true }
            if let haystack = self[prop.name] as? String {
                if haystack.lowercased().contains(propName.lowercased()) {
                    return true
                }
            }
        }

        return false
    }

    /// Get property value
    /// - Parameters:
    ///   - name: property name
    public func get<T>(_ name: String, type _: T.Type = T.self) -> T? {
        if objectSchema[name] != nil {
            return self[name] as? T
        }
        else if let edge = edge(name) {
            return edge.target() as? T
        }
        return nil
    }

    /// Set property to value, which will be persisted in the local database
    /// - Parameters:
    ///   - name: property name
    ///   - value: value
    public func set(_ name: String, _ value: Any?) {
        DatabaseController.writeSync { _ in
            if let schema = self.objectSchema[name] {
                guard !isEqualValue(self[name], value) else { return }

                switch schema.type {
                case .int:
                    self[name] = value as? Int
                case .float:
                    self[name] = value as? Float
                case .double:
                    self[name] = value as? Double
                default:
                    self[name] = value
                }

                self.modified([name])
            }
            else if let obj = value as? Object {
                _ = try self.link(obj, type: name, distinct: true)
            }
            else if let list = value as? [Object] {
                for obj in list {
                    _ = try self.link(obj, type: name)
                }
            }
            self.dateModified = Date() // Update DateModified
        }
    }

    /// Flattens the type hierarchy in sequence to search through all related edge types
    private func edgeCollection(_ edgeType: String) -> [String]? {
        // TODO: IMPLEMENT

        if edgeType == "family" {
            return [
                "family",
                "brother",
                "sister",
                "sibling",
                "father",
                "mother",
                "aunt",
                "uncle",
                "cousin",
                "niece",
            ]
        }

        return nil
    }

    public func reverseEdges(_ edgeType: String) -> Results<Edge>? {
        guard realm != nil, let uid = self.uid.value else {
            return nil
        }

        // TODO: collection support
        #warning("Not implemented fully yet")

        // Should this create a temporary edge for which item() is source() ?
        return realm?.objects(Edge.self)
            .filter("targetItemID = \(uid) AND type = '\(edgeType)")
    }

    public func reverseEdge(_ edgeType: String) -> Edge? {
        guard realm != nil, let uid = self.uid.value else {
            return nil
        }

        // TODO: collection support
        #warning("Not implemented fully yet")

        // Should this create a temporary edge for which item() is source() ?
        return realm?.objects(Edge.self)
            .filter("deleted = false AND targetItemID = \(uid) AND type = '\(edgeType)").first
    }

    public func edges(_ edgeType: String) -> Results<Edge>? {
        guard edgeType != "", realm != nil else {
            return nil
        }

        if let collection = edgeCollection(edgeType) {
            return edges(collection)
        }

        return allEdges.filter("deleted = false AND type = '\(edgeType)'")
    }

    public func edges(_ edgeTypes: [String]) -> Results<Edge>? {
        guard edgeTypes.count > 0, realm != nil else {
            return nil
        }

        var flattened = [String]()
        for type in edgeTypes {
            if let collection = edgeCollection(type) {
                flattened.append(contentsOf: collection)
            }
            else {
                flattened.append(type)
            }
        }

        let filter =
            "deleted = false and (type = '\(flattened.joined(separator: "' or type = '"))')"

        return allEdges.filter(filter)
    }

    public func edge(_ edgeType: String) -> Edge? {
        guard edgeType != "", realm != nil else {
            return nil
        }

        if let collection = edgeCollection(edgeType) {
            return edge(collection)
        }

        return allEdges.filter("deleted = false AND type = '\(edgeType)'").first
    }

    public func edge(_ edgeTypes: [String]) -> Edge? {
        guard edgeTypes.count > 0, realm != nil else {
            return nil
        }

        var flattened = [String]()
        for type in edgeTypes {
            if let collection = edgeCollection(type) {
                flattened.append(contentsOf: collection)
            }
            else {
                flattened.append(type)
            }
        }

        let filter =
            "deleted = false and (type = '\(flattened.joined(separator: "' or type = '"))')"

        return allEdges.filter(filter).first
    }

    private func determineSequenceNumber(
        _ edgeType: String,
        _ sequence: EdgeSequencePosition?
    ) throws -> Int? {
        guard let sequence = sequence else {
            return nil
        }

        var orderNumber: Int = 1000 // Default 1st order number

        let edges = allEdges.filter("deleted = false and type = '\(edgeType)'")

        switch sequence {
        case let .number(nr): orderNumber = nr
        case .first:
            let sorted = edges.sorted(byKeyPath: "sequence", ascending: false)
            if let firstOrderNumber = sorted.first?.sequence.value {
                orderNumber = Int(firstOrderNumber / 2)

                if orderNumber == firstOrderNumber {
                    // TODO: renumber the entire list
                    throw "Not implemented yet"
                }
            }
        case .last:
            let sorted = edges.sorted(byKeyPath: "sequence", ascending: true)
            if let lastOrderNumber = sorted.first?.sequence.value {
                orderNumber = lastOrderNumber + 1000
            }
        case let .before(beforeEdge):
            if !allEdges.contains(beforeEdge) || beforeEdge.type != edgeType {
                throw "Edge is not part of this set"
            }

            guard let beforeNumber = beforeEdge.sequence.value else {
                throw "Before edge is not part of an ordered list"
            }

            let beforeBeforeEdge = edges
                .filter("deleted = false AND sequence < \(beforeNumber)")
                .sorted(byKeyPath: "sequence", ascending: true)
                .first

            let previousNumber = (beforeBeforeEdge?.sequence.value ?? 0)
            if beforeNumber - previousNumber > 1000 {
                orderNumber = beforeNumber - 1000
            }
            else if beforeNumber - previousNumber > 1 {
                orderNumber = beforeNumber - (beforeNumber - previousNumber / 2)
            }
            else {
                // TODO: renumber the entire list
                throw "Not implemented yet"
            }
        case let .after(afterEdge):
            if !allEdges.contains(afterEdge) || afterEdge.type != edgeType {
                throw "Edge is not part of this set"
            }

            guard let afterNumber = afterEdge.sequence.value else {
                throw "Before edge is not part of an ordered list"
            }

            let afterAfterEdge = edges
                .filter("deleted = false AND sequence < \(afterNumber)")
                .sorted(byKeyPath: "sequence", ascending: true)
                .first

            let nextNumber = (afterAfterEdge?.sequence.value ?? 0)
            if afterNumber - nextNumber > 1000 {
                orderNumber = afterNumber - 1000
            }
            else if afterNumber - nextNumber > 1 {
                orderNumber = afterNumber - (afterNumber - nextNumber / 2)
            }
            else {
                // TODO: renumber the entire list
                throw "Not implemented yet"
            }
        }

        return orderNumber
    }

    /// When distinct is set to false multiple of the same relationship type are allowed
    public func link(
        _ item: Object,
        type edgeType: String = "edge",
        sequence: EdgeSequencePosition? = nil,
        label: String? = nil,
        distinct: Bool = false,
        overwrite: Bool = true
    ) throws -> Edge? {
        guard let _: Int = get("uid") else {
            throw "Exception: Missing uid on source"
        }

        guard item.objectSchema["uid"] != nil, let targetID: Int = item["uid"] as? Int else {
            throw "Exception: Missing uid on target"
        }

        guard edgeType != "" else {
            throw "Exception: Edge type is not set"
        }

        let query = "deleted = false and type = '\(edgeType)'"
            + (distinct ? "" : " and targetItemID = \(targetID)")
        var edge = allEdges.filter(query).first
        let sequenceNumber: Int? = try determineSequenceNumber(edgeType, sequence)

        DatabaseController.writeSync { _ in
            if item.realm == nil, let item = item as? Item {
                item._action = "create"
                realm?.add(item, update: .modified)
            }

            if edge == nil {
                edge = try Cache.createEdge(
                    source: self,
                    target: item,
                    type: edgeType,
                    label: label,
                    sequence: sequenceNumber
                )
                if let edge = edge {
                    allEdges.append(edge)
                }
            }
            else if overwrite, let edge = edge {
                edge.targetItemID.value = targetID
                edge.targetItemType = item.genericType
                edge.sequence.value = sequenceNumber
                edge.edgeLabel = label

                if edge._action == nil {
                    edge._action = "update"
                }
            }
            else if edge == nil {
                throw "Exception: Could not create link"
            }
        }

        return edge
    }

    //    public func orderedEdgeIndex(_ type: String, _ needle: Edge) -> Int? {
    //        var i = 0
    //        if let list = edges(type) {
    //            for edge in list {
    //                i += 1
    //                if edge.sourceItemID.value == needle.sourceItemID.value
    //                    && edge.sourceItemType == needle.sourceItemType {
    //                    return i
    //                }
    //            }
    //        }
    //        return nil
    //    }

    public func unlink(_ edge: Edge) throws {
        if edge.sourceItemID.value == uid.value, edge.sourceItemType == genericType {
            DatabaseController.writeSync { _ in
                edge.deleted = true
                edge._action = "delete"
                realm?.delete(edge)
            }
        }
        else {
            throw "Exception: Edge does not link from this item"
        }
    }

    public func unlink(_ item: Item, type edgeType: String? = nil, all: Bool = true) throws {
        guard let targetID: Int = item.get("uid") else {
            return
        }

        guard edgeType != "" else {
            throw "Exception: Edge type is not set"
        }

        let edgeQuery = edgeType != nil ? "type = '\(edgeType!)' and " : ""
        let query = "deleted = false and \(edgeQuery) targetItemID = \(targetID)"
        let results = allEdges.filter(query)

        if results.count > 0 {
            DatabaseController.writeSync { _ in
                if all {
                    for edge in results {
                        edge.deleted = true
                        edge._action = "delete"
                    }
                }
                else if let edge = results.first {
                    edge.deleted = true
                    edge._action = "delete"
                }
            }
        }
    }

    /// Toggle boolean property
    /// - Parameter name: property name
    public func toggle(_ name: String) throws {
        guard objectSchema[name]?.type == .bool else {
            throw "'\(name)' is not a boolean property"
        }

        let val = self[name] as? Bool ?? false
        set(name, !val)
    }

    /// Compares value of this Items property with the corresponding property of the passed items property
    /// - Parameters:
    ///   - propName: name of the compared property
    ///   - item: item to compare against
    /// - Returns: boolean indicating whether the property values are the same
    public func isEqualProperty(_ propName: String, _ item: Item) -> Bool {
        if let prop = objectSchema[propName] {
            // List
            if prop.isArray {
                return false // TODO: implement a list compare and a way to add to updatedFields
            }
            else {
                return isEqualValue(self[propName], item[propName])
            }
        }
        else {
            // TODO: Error handling
            debugHistory
                .warn(
                    "Unable to compare property \(propName), but \(self) does not have that property"
                )
            return false
        }
    }

    func isEqualValue(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil { return b == nil }
        else if let a = a as? Bool { return a == b as? Bool }
        else if let a = a as? String { return a == b as? String }
        else if let a = a as? Int { return a == b as? Int }
        else if let a = a as? Double { return a == b as? Double }
        else if let a = a as? Object { return a == b as? Object }
        else {
            debugHistory.warn("Unable to compare value: types do not mach")
            return false
        }
    }

    /// Safely merges the passed item with the current Item. When there are merge conflicts, meaning that some other process
    /// requested changes for the same properties with different values, merging is not performed.
    /// - Parameter item: item to be merged with the current Item
    /// - Returns: boolean indicating the succes of the merge
    public func safeMerge(_ item: Item) -> Bool {
        // Ignore when marked for deletion
        if _action == "delete" { return true }

        // Do not update when the version is not higher then what we already have
        if item.version <= version { return false }

        // Make sure to not overwrite properties that have been changed
        let updatedFields = _updated

        // Compare all updated properties and make sure they are the same
        #warning("properly implement this for edges")
        for fieldName in updatedFields {
            if !isEqualProperty(fieldName, item) { return false }
        }

        // Merge with item
        merge(item)

        return true
    }

    /// merges the the passed Item in the current item
    /// - Parameters:
    ///   - item: passed Item
    ///   - mergeDefaults: boolean describing how to merge. If mergeDefault == true: Overwrite only the property values have
    ///    not already been set (nil). else: Overwrite all property values with the values from the passed item, with the exception
    ///    that values cannot be set from a non-nil value to nil.
    public func merge(_ item: Item, _ mergeDefaults: Bool = false) {
        // Store these changes in realm
        if let realm = self.realm {
            do {
                try realm.write { doMerge(item, mergeDefaults) }
            }
            catch {
                print("Could not write merge of \(item) and \(self) to realm")
            }
        }
        else {
            doMerge(item, mergeDefaults)
        }
    }

    private func doMerge(_ item: Item, _ mergeDefaults: Bool = false) {
        let properties = objectSchema.properties
        for prop in properties {
            // Exclude SyncState
            if prop.name == "_updated" || prop.name == "_action" || prop.name == "_partial"
                || prop.name == "deleted" || prop.name == "_changedInSession" || prop
                .name == "uid" {
                continue
            }

            // Perhaps not needed:
            // - TODO needs to detect lists which will always be set
            // - TODO needs to detect optionals which will always be set

            // Overwrite only the property values that are not already set
            if mergeDefaults {
                if self[prop.name] == nil {
                    self[prop.name] = item[prop.name]
                }
            }
            // Overwrite all property values with the values from the passed item, with the
            // exception, that values cannot be set ot nil
            else {
                if item[prop.name] != nil {
                    self[prop.name] = item[prop.name]
                }
            }
        }
        #warning("Implement edge merging")
    }

    /// update the dateAccessed property to the current date
    public func accessed() {
        let safeSelf = ItemReference(to: self)
        DatabaseController.writeAsync { _ in
            guard let item = safeSelf.resolve() else { return }

            item.dateAccessed = Date()

            let auditItem = try Cache.createItem(AuditItem.self, values: ["action": "read"])
            _ = try item.link(auditItem, type: "changelog")
        }
    }

    /// update the dateAccessed property to the current date
    public func modified(_ updatedFields: [String]) {
        let safeSelf = ItemReference(to: self)
        DatabaseController.writeAsync { _ in
            guard let item = safeSelf.resolve() else { return }

            let previousModified = item.dateModified
            item.dateModified = Date()

            for field in updatedFields {
                if !item._updated.contains(field) {
                    item._updated.append(field)
                }
            }

            if previousModified?.distance(to: Date()) ?? 0 < 300 /* 5 minutes */ {
                #warning("Test that .last gives the last added audit item")
                if
                    let auditItem = item.edges("changelog")?.last?.item(type: AuditItem.self),
                    let content = auditItem.content,
                    var dict = try unserialize(content, type: [String: AnyCodable?].self) {
                    for field in updatedFields {
                        guard item.objectSchema[field] != nil else { throw "Invalid update call" }
                        dict[field] = AnyCodable(item[field])
                    }
                    auditItem.content = String(
                        data: try MemriJSONEncoder.encode(dict),
                        encoding: .utf8
                    ) ?? ""
                    return
                }
            }

            var dict = [String: AnyCodable?]()
            for field in updatedFields {
                guard item.objectSchema[field] != nil else { throw "Invalid update call" }
                dict[field] = AnyCodable(item[field])
            }

            let content = String(data: try MemriJSONEncoder.encode(dict), encoding: .utf8) ?? ""
            let auditItem = try Cache.createItem(
                AuditItem.self,
                values: [
                    "action": "update",
                    "content": content,
                ]
            )
            _ = try item.link(auditItem, type: "changelog")
        }
    }

    /// compare two dataItems
    /// - Parameters:
    ///   - lhs: Item 1
    ///   - rhs: Item 2
    /// - Returns: boolean indicating equality
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.uid.value == rhs.uid.value
    }

    /// Reads Items from file
    /// - Parameters:
    ///   - file: filename (without extension)
    ///   - ext: extension
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized Items
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [Item] {
        let jsonData = try jsonDataFromFile(file, ext)

        let items: [Item] = try MemriJSONDecoder.decode(family: ItemFamily.self, from: jsonData)
        return items
    }

    /// Read Item from string
    /// - Parameter json: string to parse
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized Items
    public class func fromJSONString(_ json: String) throws -> [Item] {
        let items: [Item] = try MemriJSONDecoder
            .decode(family: ItemFamily.self, from: Data(json.utf8))
        return items
    }
}

extension RealmSwift.Results where Element == Edge {
    private enum Direction {
        case source, target
    }

    private func lookup<T: Object>(type: T.Type? = nil, dir: Direction = .target) -> Results<T>? {
        guard count > 0 else {
            return nil
        }

        var listType = type
        if listType == nil {
            let strType = dir == .target ? first?.targetItemType : first?.sourceItemType
            if let strType = strType, let itemType = ItemFamily(rawValue: strType) {
                listType = itemType.getType() as? T.Type
            }
        }

        guard let finalType = listType else {
            return nil
        }

        do {
            return try DatabaseController.tryRead {
                let filter = "uid = "
                    + compactMap {
                        if let value = (dir == .target ? $0.targetItemID.value : $0.sourceItemID
                            .value) {
                            return String(value)
                        }
                        return nil
                    }.joined(separator: " or uid = ")
                return $0.objects(finalType).filter(filter)
            }
        }
        catch {
            debugHistory.error("\(error)")
            return nil
        }
    }

    // TODO: support for heterogenous edge lists

    func items<T: Item>(type: T.Type? = nil) -> Results<T>? { lookup(type: type) }
    func targets<T: Item>(type: T.Type? = nil) -> Results<T>? { lookup(type: type) }
    func sources<T: Item>(type: T.Type? = nil) -> Results<T>? { lookup(type: type, dir: .source) }

    func itemsArray<T: Item>(type _: T.Type? = T.self) -> [T] {
        var result = [T]()

        for edge in self {
            if let target = edge.target() as? T {
                result.append(target)
            }
        }

        return result
    }

    func edgeArray() -> [Edge] {
        var result = [Edge]()

        for edge in self {
            result.append(edge)
        }

        return result
    }

    //    #warning("Toby, how do Ranges work exactly?")
    //    #warning("@Ruben I think this achieves what you want")
    //    // TODO: views.removeSubrange((currentViewIndex + 1)...)
    //    func removeEdges(ofType type: String, withOrderMatchingBounds orderBounds: PartialRangeFrom<Int>) {
    //        edges(type)?.filter("order > \(orderBounds.lowerBound)").forEach { edge in
    //            do {
    //                try self.unlink(edge)
    //            } catch {
    //                // log errors in unlinking here
    //            }
    //        }
    //    }
}

public enum EdgeSequencePosition {
    case first
    case last
    case before(Edge)
    case after(Edge)
    case number(Int)
}

extension memri.Edge {
    override public var description: String {
        "Edge (\(type ?? "")\(edgeLabel != nil ? ":\(edgeLabel ?? "")" : "")): \(sourceItemType ?? ""):\(sourceItemID.value ?? 0) -> \(targetItemType ?? ""):\(targetItemID.value ?? 0)"
    }

    var targetType: Object.Type? {
        ItemFamily(rawValue: targetItemType ?? "")?.getType() as? Object.Type
    }

    var sourceType: Item.Type? {
        ItemFamily(rawValue: sourceItemType ?? "")?.getType() as? Item.Type
    }

    func item<T: Item>(type: T.Type? = T.self) -> T? {
        target(type: type)
    }

    func target<T: Object>(type _: T.Type? = T.self) -> T? {
        do {
            return try DatabaseController.tryRead {
                if let itemType = targetType {
                    return $0.object(ofType: itemType, forPrimaryKey: targetItemID) as? T
                }
                else {
                    throw "Could not resolve edge target: \(self)"
                }
            }
        }
        catch {
            debugHistory.error("\(error)")
        }

        return nil
    }

    func source<T: Item>(type _: T.Type? = T.self) -> T? {
        do {
            return try DatabaseController.tryRead {
                if let itemType = sourceType {
                    return $0.object(ofType: itemType, forPrimaryKey: sourceItemID) as? T
                }
                else {
                    throw "Could not resolve edge source: \(self)"
                }
            }
        }
        catch {
            debugHistory.error("\(error)")
        }

        return nil
    }

    func parseTargetDict(_ dict: [String: AnyCodable]?) throws {
        guard let dict = dict else { return }

        guard let itemType = dict["_type"]?.value as? String else {
            throw "Invalid JSON, no _type specified for target: \(dict)"
        }

        guard let type = ItemFamily(rawValue: itemType)?.getType() as? Item.Type else {
            throw "Invalid target item type specificed: \(itemType)"
        }

        let realm = DatabaseController.getRealm()
        var item = type.init()
        for (key, value) in dict {
            guard let prop = realm.schema[itemType]?[key] else {
                continue
            }

            if prop.type == .date, let value = value.value as? Int {
                item[key] = Date(timeIntervalSince1970: Double(value / 1000))
            }
            else {
                item[key] = value.value
            }
        }
        item = try Cache.addToCache(item)

        if let uid = item.uid.value {
            targetItemType = itemType
            targetItemID.value = uid
        }
        else {
            throw "Unable to create target item in edge"
        }
    }

    convenience init(
        type: String = "edge",
        source: (String, Int),
        target: (String, Int),
        sequence: Int? = nil,
        label: String? = nil,
        action: String? = nil
    ) {
        self.init()

        self.type = type
        sourceItemType = source.0
        sourceItemID.value = source.1
        targetItemType = target.0
        targetItemID.value = target.1
        self.sequence.value = sequence
        edgeLabel = label
        _action = action
    }
}
