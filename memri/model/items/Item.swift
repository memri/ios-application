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

	override public var description: String {
		var str = "\(genericType) \(realm == nil ? "[UNMANAGED] " : ""){\n"
			+ "    uid: \(uid.value == nil ? "nil" : String(uid.value ?? 0))\n"
			+ "    " + objectSchema.properties
			.filter {
				self[$0.name] != nil && $0.name != "allEdges"
					&& $0.name != "uid" && $0.name != "syncState"
			}
			.map { "\($0.name): \(CVUSerializer.valueToString(self[$0.name]))" }
			.joined(separator: "\n    ")
			+ "\n    syncState: \(syncState?.description ?? "")"

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
			} else if let edgeTypes = args?[0] as? [String] {
				return self.edge(edgeTypes)
			}
			return nil
		}
		functions["edges"] = { args in
			if let edgeType = args?[0] as? String {
				return self.edges(edgeType)
			} else if let edgeTypes = args?[0] as? [String] {
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
				print("Warning: getting property that this item doesnt have: \(name) for \(genericType):\(uid.value ?? -1000)")
			#endif

			return ""
		} else {
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
		} else {
			print("Cannot find type \(genericType) in ItemFamily")
			return nil
		}
	}

	/// Determines whether item has property
	/// - Parameter propName: name of the property
	/// - Returns: boolean indicating whether Item has the property
	public func hasProperty(_ propName: String) -> Bool {
		if propName == "self" {
			return true
		}
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
		if name == "self" {
			return self as? T
		} else if objectSchema[name] != nil {
			return self[name] as? T
		} else if let edge = edge(name) {
			return edge.target() as? T
		}
		return nil
	}

	/// Set property to value, which will be persisted in the local database
	/// - Parameters:
	///   - name: property name
	///   - value: value
	public func set(_ name: String, _ value: Any?) {
		realmWriteIfAvailable(realm) {
			if self.objectSchema[name] != nil {
				self[name] = value
			} else if let obj = value as? Object {
				_ = try self.link(obj, type: name, distinct: true)
			} else if let list = value as? [Object] {
                for obj in list {
                    _ = try self.link(obj, type: name)
                }
            }
		}
	}

	/// Flattens the type hierarchy in sequence to search through all related edge types
	private func edgeCollection(_ edgeType: String) -> [String]? {
		// TODO: IMPLEMENT

		if edgeType == "family" {
			return ["family", "brother", "sister", "sibling", "father", "mother", "aunt",
					"uncle", "cousin", "niece"]
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
			} else {
				flattened.append(type)
			}
		}

		let filter = "deleted = false and (type = '\(flattened.joined(separator: "' or type = '"))')"

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
			} else {
				flattened.append(type)
			}
		}

		let filter = "deleted = false and (type = '\(flattened.joined(separator: "' or type = '"))')"

		return allEdges.filter(filter).first
	}

	private func determineSequenceNumber(_ edgeType: String, _ sequence: EdgeSequencePosition?) throws -> Int? {
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
			} else if beforeNumber - previousNumber > 1 {
				orderNumber = beforeNumber - (beforeNumber - previousNumber / 2)
			} else {
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
			} else if afterNumber - nextNumber > 1 {
				orderNumber = afterNumber - (afterNumber - nextNumber / 2)
			} else {
				// TODO: renumber the entire list
				throw "Not implemented yet"
			}
		}

		return orderNumber
	}

	/// When distinct is set to false multiple of the same relationship type are allowed
	public func link(_ item: Object, type edgeType: String = "edge",
					 order: EdgeSequencePosition? = nil, label: String? = nil,
					 distinct: Bool = false, overwrite: Bool = true) throws -> Edge? {
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
		let sequenceNumber: Int? = try determineSequenceNumber(edgeType, order)

		realmWriteIfAvailable(realm) {
			if item.realm == nil, let item = item as? Item {
				item.syncState?.actionNeeded = "create"
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
			} else if overwrite, let edge = edge {
				edge.targetItemID.value = targetID
				edge.targetItemType = item.genericType
				edge.sequence.value = sequenceNumber
				edge.edgeLabel = label

				if edge.syncState?.actionNeeded == nil {
					edge.syncState?.actionNeeded = "update"
				}
			} else if edge == nil {
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
			realmWriteIfAvailable(realm) {
				edge.deleted = true
				edge.syncState?.actionNeeded = "delete"
				realm?.delete(edge)
			}
		} else {
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
			realmWriteIfAvailable(realm) {
				if all {
					for edge in results {
						edge.deleted = true
						edge.syncState?.actionNeeded = "delete"
					}
				} else if let edge = results.first {
					edge.deleted = true
					edge.syncState?.actionNeeded = "delete"
				}
			}
		}
	}

	/// Toggle boolean property
	/// - Parameter name: property name
	public func toggle(_ name: String) {
		if let val = self[name] as? Bool {
			val ? set(name, false) : set(name, true)
		} else {
			print("tried to toggle property \(name), but \(name) is not a boolean")
		}
	}

	/// Compares value of this Items property with the corresponding property of the passed items property
	/// - Parameters:
	///   - propName: name of the compared property
	///   - item: item to compare against
	/// - Returns: boolean indicating whether the property values are the same
	public func isEqualProperty(_ propName: String, _ item: Item) -> Bool {
		if let prop = objectSchema[propName] {
			// List
			if prop.objectClassName != nil {
				return false // TODO: implement a list compare and a way to add to updatedFields
			} else {
				let value1 = self[propName]
				let value2 = item[propName]

				if let item1 = value1 as? String, let value2 = value2 as? String {
					return item1 == value2
				}
				if let item1 = value1 as? Int, let value2 = value2 as? Int {
					return item1 == value2
				}
				if let item1 = value1 as? Double, let value2 = value2 as? Double {
					return item1 == value2
				}
				if let item1 = value1 as? Object, let value2 = value2 as? Object {
					return item1 == value2
				} else {
					// TODO: Error handling
					print("Trying to compare property \(propName) of item \(item) and \(self) " +
						"but types do not mach")
				}
			}

			return true
		} else {
			// TODO: Error handling
			print("Tried to compare property \(propName), but \(self) does not have that property")
			return false
		}
	}

	/// Safely merges the passed item with the current Item. When there are merge conflicts, meaning that some other process
	/// requested changes for the same properties with different values, merging is not performed.
	/// - Parameter item: item to be merged with the current Item
	/// - Returns: boolean indicating the succes of the merge
	public func safeMerge(_ item: Item) -> Bool {
		if let syncState = self.syncState {
			// Ignore when marked for deletion
			if syncState.actionNeeded == "delete" { return true }

			// Do not update when the version is not higher then what we already have
			if item.version <= version { return false }

			// Make sure to not overwrite properties that have been changed
			let updatedFields = syncState.updatedFields

			// Compare all updated properties and make sure they are the same
            #warning("properly implment this for edges")
			for fieldName in updatedFields {
				if !isEqualProperty(fieldName, item) { return false }
			}

			// Merge with item
			merge(item)

			return true
		} else {
			// TODO: Error handling
			print("trying to merge, but syncState is nil")
			return false
		}
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
			} catch {
				print("Could not write merge of \(item) and \(self) to realm")
			}
		} else {
			doMerge(item, mergeDefaults)
		}
	}

	private func doMerge(_ item: Item, _ mergeDefaults: Bool = false) {
		let properties = objectSchema.properties
		for prop in properties {
			// Exclude SyncState
            if prop.name == "SyncState" || prop.name == "uid" {
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
	public func access() {
		realmWriteIfAvailable(realm) {
			self.dateAccessed = Date()
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

	/// Sets syncState .actionNeeded property
	/// - Parameters:
	///   - action: action name
	public func setSyncStateActionNeeded(_ action: String) {
		if let syncState = self.syncState {
			syncState.actionNeeded = action
		} else {
			print("No syncState available for item \(self)")
		}
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
			let realm = try Realm()
			let filter = "uid = "
				+ compactMap {
					if let value = (dir == .target ? $0.targetItemID.value : $0.sourceItemID.value) {
						return String(value)
					}
					return nil
				}.joined(separator: " or uid = ")
			return realm.objects(finalType).filter(filter)
		} catch {
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
			let realm = try Realm()
			if let itemType = targetType {
				return realm.object(ofType: itemType, forPrimaryKey: targetItemID) as? T
			} else {
				throw "Could not resolve edge target: \(self)"
			}
		} catch {
			debugHistory.error("\(error)")
		}

		return nil
	}

	func source<T: Item>(type _: T.Type? = T.self) -> T? {
		do {
			let realm = try Realm()
			if let itemType = sourceType {
				return realm.object(ofType: itemType, forPrimaryKey: sourceItemID) as? T
			} else {
				throw "Could not resolve edge source: \(self)"
			}
		} catch {
			debugHistory.error("\(error)")
		}

		return nil
	}
    
    func parseTargetDict(_ dict:[String:AnyCodable]?) throws {
        guard let dict = dict else { return }
        
        guard let itemType = dict["_type"]?.value as? String else {
            throw "Invalid JSON, no _type specified for target: \(dict)"
        }

        guard let type = ItemFamily(rawValue: itemType)?.getType() as? Object.Type else {
            throw "Invalid target item type specificed: \(itemType)"
        }
        
        var values = [String: Any]()
        for (key, value) in dict { values[key] = value.value }

        let item = try Cache.createItem(type, values: values)
        if let uid = item["uid"] as? Int {
            targetItemType = itemType
            targetItemID.value = uid
        } else {
            throw "Unable to create target item in edge"
        }
    }

	convenience init(type: String = "edge", source: (String, Int), target: (String, Int),
					 sequence: Int? = nil, label: String? = nil, action: String? = nil) {
		self.init()

		self.type = type
		sourceItemType = source.0
		sourceItemID.value = source.1
		targetItemType = target.0
		targetItemID.value = target.1
		self.sequence.value = sequence
		self.edgeLabel = label

		if let action = action {
			syncState?.actionNeeded = action
		}
	}
}
