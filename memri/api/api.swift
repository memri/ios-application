import Combine
import Foundation
import RealmSwift

/// Provides functions to communicate asynchronously with a Pod (Personal Online Datastore) for storage of data and/or for
/// executing actions
public class PodAPI {
	var key: String

	/// Specifies used http methods
	enum HTTPMethod: String {
		case GET
		case POST
		case DELETE
		case PUT
	}

	enum HTTPError: Error {
		case ClientError(Int, String)
	}

	public init(_ podkey: String) {
		key = podkey
	}

	private func http(_ method: HTTPMethod = .GET, path: String = "", body: Data? = nil,
					  _ callback: @escaping (_ error: Error?, _ data: Data?) -> Void) {
		let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
		let podhost = Settings.get("user/pod/host") ?? ""
		guard var baseUrl = URL(string: podhost) else {
			let message = "Invalid pod host set in settings: \(podhost)"
			debugHistory.error(message)
			callback(message, nil)
			return
		}

		baseUrl = baseUrl
			.appendingPathComponent("v1")
			.appendingPathComponent(path)

		// TODO: when the backend sends the correct caching headers
		// this can be changed: .reloadIgnoringCacheData

		guard let username: String = Settings.get("user/pod/username"),
			let password: String = Settings.get("user/pod/password") else {
			// TODO: User error handling
			print("ERROR: Could not find login credentials, so could not authenticate to pod")
			return
		}

		let loginString = "\(username):\(password)"

		guard let loginData = loginString.data(using: String.Encoding.utf8) else {
			return
		}
		let base64LoginString = loginData.base64EncodedString()

		var urlRequest = URLRequest(
			url: baseUrl,
			cachePolicy: .reloadIgnoringCacheData,
			timeoutInterval: .greatestFiniteMagnitude
		)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		if let body = body { urlRequest.httpBody = body }
		urlRequest.allowsCellularAccess = true
		urlRequest.allowsExpensiveNetworkAccess = true
		urlRequest.allowsConstrainedNetworkAccess = true
		urlRequest.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

		let task = session.dataTask(with: urlRequest) { data, response, error in
			if let error = error {
				callback(error, data)
			} else if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode > 399 {
					let httpError = HTTPError.ClientError(
						httpResponse.statusCode,
						"URL: \(baseUrl.absoluteString)\nBody:"
							+ (String(data: data ?? Data(), encoding: .utf8) ?? "")
					)
					callback(httpError, data)
					return
				}
			}

			callback(nil, data)
		}

		task.resume()
	}

//
//	private func getArray(_ item: Item, _ prop: String) -> [Item] {
//		let className = item.objectSchema[prop]?.objectClassName
//
//		if className == "Edge" {
//			var result = [Item]()
//
//			if let list = item[prop] as? List<Edge> {
//				for edge in list {
//					if let d = edge.item() {
//						result.append(d)
//					}
//				}
//
//				return result
//			} else {
//				// TODO: error
//				return []
//			}
//		} else if className == "Item" {
//			// Unsupported
//			return []
//		} else {
//			return dataItemListToArray(item[prop] as Any)
//		}
//	}

	private let MAXDEPTH = 2
	private func recursiveSearch(_ item: SchemaItem, removeUID _: Bool = false) throws -> [String: Any] {
		if item.syncState?.actionNeeded == nil { throw "No action required" }

		var createItems = [[String: Any]]()
		var updateItems = [[String: Any]]()
		var deleteItems = [[String: Any]]()
		var createEdges = [[String: Any]]()
		var updateEdges = [[String: Any]]()
		var deleteEdges = [[String: Any]]()

		func recurEdge(_ edge: Edge, forceInclude: Bool = false) throws {
			let a = edge.syncState?.actionNeeded
			if a == nil, !forceInclude { return }
			guard let action = a else { return }

			var result = [String: Any]()

			let properties = item.objectSchema.properties
			for prop in properties {
				if prop.name == "syncState" || prop.name == "deleted"
					|| prop.name == "targetItemType" || prop.name == "targetItemID"
					|| prop.name == "sourceItemType" || prop.name == "sourceItemID" {
					// Ignore
				} else {
					result[prop.name] = edge[prop.name]
				}
			}

			if let tgt = edge.item() {
				try recur(tgt)
				result["_source"] = edge.sourceItemID
				result["_target"] = edge.targetItemID
			} else {
				// Database is corrupt
				debugHistory.warn("Database corruption; edge to nowhere")
			}

			switch action {
			case "create": createEdges.append(result)
			case "update": updateEdges.append(result)
			case "delete": deleteEdges.append(result)
			default: throw "Unexpected action"
			}
		}

		func recur(_ item: SchemaItem, forceInclude: Bool = false) throws {
			let a = item.syncState?.actionNeeded
			if a == nil, !forceInclude { return }
			guard let action = a else { return }

			let updatedFields = item.syncState?.updatedFields
			var result: [String: Any] = [
				"_type": item.genericType,
			]

			let properties = item.objectSchema.properties
			for prop in properties {
				if prop.name == "syncState" || prop.name == "deleted" {
					// Ignore
				} else if prop.name == "allEdges" {
					for edge in item.allEdges {
						try recurEdge(edge, forceInclude: action == "create")
					}
				} else if updatedFields == nil || updatedFields?.contains(prop.name) ?? false {
					if prop.type == .object {
						throw "Unexpected object schema"
					} else {
						result[prop.name] = item[prop.name]
					}
				}
			}

			switch action {
			case "create": createItems.append(result)
			case "update": updateItems.append(result)
			case "delete": deleteItems.append(result)
			default: throw "Unexpected action"
			}
		}

		// TODO: refactor: error handling
		do {
			_ = try recur(item)

			var result = [String: Any]()
			if createItems.count > 0 { result["createItems"] = createItems }
			if updateItems.count > 0 { result["updateItems"] = updateItems }
			if deleteItems.count > 0 { result["deleteItems"] = deleteItems }
			if createEdges.count > 0 { result["createEdges"] = createEdges }
			if updateEdges.count > 0 { result["updateEdges"] = updateEdges }
			if deleteEdges.count > 0 { result["deleteEdges"] = deleteEdges }

			return result
		} catch {
			debugHistory.error("Exception while communicating with the pod: \(error)")
			return [:]
		}
	}

	func toJSON(_ result: [String: Any]) throws -> Data {
		try MemriJSONEncoder.encode(AnyCodable(result))
	}

	func simplify(_ item: SchemaItem, create: Bool = false) throws -> [String: Any] {
		let updatedFields = item.syncState?.updatedFields
		var result: [String: Any] = [
			"_type": item.genericType,
            "uid": item.uid
		]
        print("\(item.genericType) \(item.uid.value ?? 0)")

		let properties = item.objectSchema.properties
        let exclude = ["syncState", "deleted", "allEdges", "uid"]
		for prop in properties {
            if exclude.contains(prop.name) {
				// Ignore
			} else if create || updatedFields == nil || updatedFields?.contains(prop.name) ?? false {
				if prop.type == .object {
					debugHistory.warn("Unexpected object schema")
				} else {
					result[prop.name] = item[prop.name]
				}
			}
		}
        
        guard result["uid"] is Int else {
            throw "Exception: Item does not have uid set: \(item)"
        }

		return result
	}

	func simplify(_ edge: Edge, create _: Bool = false) throws -> [String: Any] {
		var result = [String: Any]()

		let properties = edge.objectSchema.properties
        let exclude = ["version", "syncState", "deleted", "targetItemType", "targetItemID", "sourceItemType", "sourceItemID"]
		for prop in properties {
			if exclude.contains(prop.name) {
				// Ignore
			} else if prop.name == "type" {
				result["_type"] = edge[prop.name]
			} else {
				#warning("Implement checking for updatedfields")
				result[prop.name] = edge[prop.name]
			}
		}

		if let _ = edge.target() {
			result["_source"] = edge.sourceItemID
			result["_target"] = edge.targetItemID
		} else {
			// Database is corrupt
			debugHistory.warn("Database corruption; edge to nowhere")
		}
        
        guard result["_source"] != nil && result["_target"] != nil && result["_target"] != nil else {
            print(result)
            throw "Exception: Edge is not properly formed: \(edge)"
        }

		return result
	}

	/// Retrieves a single data item from the pod
	/// - Parameters:
	///   - memriID: The memriID of the data item to retrieve
	///   - callback: Function that is called when the task is completed either with a result, or an error
	/// - Remark: Note that it is not necessary to specify the type here as the pod has a global namespace for uids
	public func get(_ uid: Int,
					_ callback: @escaping (_ error: Error?, _ item: Item?) -> Void) {
		http(path: "items/\(uid)") { error, data in
			if let data = data {
				// TODO: Refactor: Error handling
				let result: [Item]? = try? MemriJSONDecoder
					.decode(family: ItemFamily.self, from: data)
				callback(nil, result?[safe: 0])
			} else {
				callback(error, nil)
			}
		}
	}

	public func sync(_ item: SchemaItem,
					 _ callback: @escaping (_ error: Error?) -> Void) throws {
		http(.POST, path: "bulk_action", body: try toJSON(try recursiveSearch(item))) { error, _ in
			callback(error)
		}
	}

	public func sync(createItems: [SchemaItem]?,
					 updateItems: [SchemaItem]?,
					 deleteItems: [SchemaItem]?,
					 createEdges: [Edge]?,
					 updateEdges: [Edge]?,
					 deleteEdges: [Edge]?,
					 _ callback: @escaping (_ error: Error?) -> Void) throws {
        
		var result = [String: Any]()
		if createItems?.count ?? 0 > 0 {
            result["createItems"] = try createItems?.map { try simplify($0, create: true) }
        }
		if updateItems?.count ?? 0 > 0 {
            result["updateItems"] = try updateItems?.map { try simplify($0) }
        }
		if deleteItems?.count ?? 0 > 0 {
            result["deleteItems"] = try deleteItems?.map { try simplify($0) }
        }
		if createEdges?.count ?? 0 > 0 {
            result["createEdges"] = try createEdges?.map { try simplify($0, create: true) }
        }
		if updateEdges?.count ?? 0 > 0 {
            result["updateEdges"] = try updateEdges?.map { try simplify($0) }
        }
		if deleteEdges?.count ?? 0 > 0 {
            result["deleteEdges"] = try deleteEdges?.map { try simplify($0) }
        }

		http(.POST, path: "bulk_action", body: try toJSON(result)) { error, _ in
			callback(error)
		}
	}

//	/// Create a data item and return the new uid for that data item
//	/// - Parameters:
//	///   - item: The data item to create on the pod
//	///   - callback: Function that is called when the task is completed either with the new uid, or an error
//	public func create(_ item: Item,
//					   _ callback: @escaping (_ error: Error?, _ uid: Int?) -> Void) {
//		http(.POST, path: "items", body: toJSON(item)) { error, data in
//			callback(error, data != nil ? Int(String(data: data ?? Data(), encoding: .utf8) ?? "") : nil)
//		}
//	}
//
//	/// Updates a data item and returns the new version number
//	/// - Parameters:
//	///   - item: The data item to update on the pod
//	///   - callback: Function that is called when the task is completed either with the new version number, or an error
//	public func update(_ item: Item,
//					   _ callback: @escaping (_ error: Error?, _ version: Int?) -> Void) {
//		http(.PUT, path: "items/\(item.memriID)", body: toJSON(item)) { error, data in
//			callback(error, data != nil ? Int(String(data: data ?? Data(), encoding: .utf8) ?? "") : nil)
//		}
//	}
//
//	/// Marks a data item as deleted on the pod.
//	/// - Parameters:
//	///   - memriID: The memriID of the data item to remove
//	///   - callback: Function that is called when the task is completed either with a result, or  an error
//	/// - Remark: Note that data items that are marked as deleted are by default not returned when querying
//	public func remove(_ uid: Int,
//					   _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) {
//		http(.DELETE, path: "items/\(uid)") { error, _ in
//			callback(error, error == nil)
//		}
//	}

	/// Queries the database for a subset of Items and returns a list of Items
	/// - Parameters:
	///   - queryOptions: Object describing what to query and how to return the results
	///   - callback: Function that is called when the task is completed either with the results, or  an error
	/// - Remark: The query language is a WIP
	public func query(_ queryOptions: Datasource,
					  _ callback: @escaping (_ error: Error?, _ result: [Item]?) -> Void) {
		// TODO: Can no longer detect whether the data item is synced
		//        if queryOptions.query!.test(#"^-\d+"#) { // test for uid that is negative
		//            callback("nothing to do", nil)
		//            return
		//        }

		var data: Data?

		let query = queryOptions.query ?? ""
		let matches = query.match(#"^(\w+) AND uid = (.+)$"#)
		if matches.count == 3 {
			let type = matches[1]
			let uid = matches[2]

			data = """
			{
			  "_type": "\(type)",
			  "uid": \(uid)
			}
			""".data(using: .utf8)
		} else if let type = query.match(#"^(\w+)$"#)[safe: 1] {
			data = """
			{
			  "_type": "\(type)"
			}
			""".data(using: .utf8)
		} else {
			callback("Not implemented yet", nil)
			return
		}

		http(.POST, path: "search_by_fields", body: data) { error, data in
			if let error = error {
				debugHistory.error("Could not connect to pod: \n\(error)")
				callback(error, nil)
			} else if let data = data {
				do {
					var items: [Item]?
					try JSONErrorReporter {
						items = try MemriJSONDecoder
							.decode(family: ItemFamily.self, from: data)
					}

					callback(nil, items)
				} catch {
					debugHistory.error("Could not connect to pod: \n\(error)")
					callback(error, nil)
				}
			}
		}
	}

	/// Runs an importer on the pod
	/// - Parameters:
	///   - memriID: The memriID of the data item to remove
	///   - callback: Function that is called when the task is completed either with a result, or  an error
	public func runImporterRun(_ uid: Int,
							   _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) {
		http(.PUT, path: "import/\(uid)") { error, _ in
			callback(error, error == nil)
		}
	}

	/// Runs an indexer on the pod
	/// - Parameters:
	///   - memriID: The memriID of the data item to remove
	///   - callback: Function that is called when the task is completed either with a result, or  an error
	public func runIndexerRun(_ uid: Int,
							  _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) {
		http(.PUT, path: "index/\(uid)") { error, _ in
			callback(error, error == nil)
		}
	}

	//    public func queryNLP(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[Item]) -> Void) -> Void {}
//
	//    public func queryDSL(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[Item]) -> Void) -> Void {}
//
	//    public func queryRAW(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[Item]) -> Void) -> Void {}

	//    public func import() -> Void {}
	//    public func export() -> Void {}
	//    public func sync() -> Void {}
	//    public func index() -> Void {}
	//    public func convert() -> Void {}
	//    public func augment() -> Void {}
	//    public func automate() -> Void {}
//
	//    public func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (_ error:Error?, _ stream:Stream) -> Void) -> Void {}
}

/*
 {
           item(func: eq(isPartiallyLoaded, true)) {
             uid
             ~syncState {
               expand(_all_) {
                 uid
                 name
                 comment
                 color
                 isPartiallyLoaded
                 version
               }
             }
           }
         }

         {
           get(func: type(note)) @filter(NOT anyofterms(title, "3") OR eq(starred, false)) @recurse {
             uid
             type : dgraph.type
             expand(note)
           }
         }
         This will give you the uid and type of both note node and the label nodes that are linked to it via labels edge, and all properties of note. If you want more properties of the linked label, you can either specify it e.g. name under expand(note) , or if you want all of them, do query like this:
         {
           get(func: type(note)) @filter(NOT anyofterms(title, "3") OR eq(starred, false)) @recurse {
             uid
             type : dgraph.type
             expand(_all_)
           }
         }
         @recurse(depth:2)

         {
           get(func: anyofterms(title, "5")) @recurse {
             uid
             type : dgraph.type
             expand(note)
           }
         }
         The expand() trick as I wrote in the last post also applies here, so if you want only uid and type of 2nd layer nodes, you use expand(note) (all properties of the 1st layer node). I give the result here:
         {
           "data": {
             "get": [
               {
                 "uid": "0x2",
                 "dgraph.type": [
                   "note"
                 ],
                 "title": "Shopping list 5",
                 "content": "- tomatoes\n- icecream"
                 "labels": [
                   {
                     "uid": "0x1",
                     "dgraph.type": [
                       "label"
                     ]
                   },
                   {
                     "uid": "0x6",
                     "dgraph.type": [
                       "label"
                     ]
                   }
                 ]
               }
             ]
           },

             {
               item(func: anyofterms(name, "Home"))  {
                 ~labels {
                   uid
                   dgraph.type
                   expand(note) {
                     uid
                 }
                 }
               }
             }
 */
