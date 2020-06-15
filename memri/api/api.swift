import Foundation
import Combine
import RealmSwift


/// Provides functions to communicate asynchronously with a Pod (Personal Online Datastore) for storage of data and/or for
/// executing actions
public class PodAPI {
    var key: String
    
    /// Specifies used http methods
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case DELETE = "DELETE"
        case PUT = "PUT"
    }
    
    enum HTTPError: Error {
        case ClientError(Int, String)
    }
    
    public init(_ podkey: String){
        self.key = podkey
    }
    
    private func http(_ method: HTTPMethod = .GET, path: String = "", body: Data? = nil,
                      _ callback: @escaping (_ error: Error?, _ data: Data?) -> Void) {
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        let baseUrl = URL(string: Settings.get("user/pod/host") ?? "")!
            .appendingPathComponent("v1")
            .appendingPathComponent(path)
        
        // TODO when the backend sends the correct caching headers
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
            timeoutInterval: .greatestFiniteMagnitude)
        urlRequest.httpMethod = method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body { urlRequest.httpBody = body }
        urlRequest.allowsCellularAccess = true
        urlRequest.allowsExpensiveNetworkAccess = true
        urlRequest.allowsConstrainedNetworkAccess = true
        urlRequest.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: urlRequest) { data, response, error  in
            if let error = error {
                callback(error, data)
            }
            else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode > 399 {
                    let httpError = HTTPError.ClientError(httpResponse.statusCode,
                        "URL: \(baseUrl.absoluteString)\nBody:"
                            + (String(data: data ?? Data(), encoding: .utf8) ?? ""))
                    callback(httpError, data)
                    return
                }
            }
            
            callback(nil, data)
        }
        
        task.resume()
    }
    
    private func getArray(_ item:DataItem, _ prop:String) -> [DataItem] {
        let className = item.objectSchema[prop]?.objectClassName
        
        if className == "Edge" {
            let realm = try! Realm()
            var result = [DataItem]()
            
            if let list = item[prop] as? List<Edge> {
                for edge in list {
                    if let family = DataItemFamily(rawValue: edge.objectType) {
                        let item = realm.object(ofType: family.getType() as! Object.Type,
                                                forPrimaryKey: edge.objectMemriID)
                        result.append(item as! DataItem)
                    }
                }
                
                return result
            }
            else {
                // TODO error
                return []
            }
        }
        else if className == "DataItem" {
            // Unsupported
            return []
        }
        else {
            // TODO TEMP FIX
            let family = DataItemFamily(rawValue: className!)!
    //        let family = DataItemFamily(rawValue: className!.lowercased())!
            return family.getCollection(item[prop] as Any)
        }
    }
    
    private let MAXDEPTH = 2
    private func toJSON(_ dataItem: DataItem, removeUID:Bool = false) -> Data {
        
        let updatedFields:List<String>? = dataItem.syncState?.actionNeeded == "updated"
            ? dataItem.syncState?.updatedFields
            : nil
        
        func recur(_ dataItem: DataItem, _ depth:Int) -> [String:Any] {
            let properties = dataItem.objectSchema.properties
            var result:[String:Any] = [:]
            var isPartiallyLoaded = false
            
            // TODO Refactor: this will change when edges are implemented
            if depth == MAXDEPTH {
                isPartiallyLoaded = true
                result["memriID"] = dataItem.memriID
            }
            else {
                for prop in properties {
                    if prop.name == "syncState" || prop.name == "deleted" || (removeUID && prop.name == "uid") {
                        // Ignore
                    }
                    else if updatedFields == nil || updatedFields!.contains(prop.name) {
                        if prop.type == .object {
                            if prop.isArray {
                                var toList = [[String:Any]]()
                                for item in getArray(dataItem, prop.name) {
                                    toList.append(recur(item, depth + 1))
                                }
                                result[prop.name] = toList
                            }
                            else {
                                result[prop.name] = recur(dataItem[prop.name] as! DataItem, depth + 1)
                            }
                        }
                        else {
                            result[prop.name] = dataItem[prop.name]
                        }
                    }
                    else {
                        isPartiallyLoaded = true
                    }
                }
            }
            
            var syncState:[String:Any] = [:]
            if isPartiallyLoaded { syncState["isPartiallyLoaded"] = true }
            
            result["type"] = dataItem.genericType
            result["syncState"] = syncState
            
            return result
        }
        
        // TODO refactor: error handling
        return try! MemriJSONEncoder.encode(AnyCodable(recur(dataItem, 1)))
    }
    
    /// Retrieves a single data item from the pod
    /// - Parameters:
    ///   - memriID: The memriID of the data item to retrieve
    ///   - callback: Function that is called when the task is completed either with a result, or an error
    /// - Remark: Note that it is not necessary to specify the type here as the pod has a global namespace for uids
    public func get(_ memriID:String,
                    _ callback: @escaping (_ error: Error?, _ item: DataItem?) -> Void) -> Void {
        
        self.http(path: "items/\(memriID)") { error, data in
            if let data = data {
                // TODO Refactor: Error handling
                let result:[DataItem]? = try? MemriJSONDecoder
                    .decode(family: DataItemFamily.self, from: data)
                
                callback(nil, result?[safe:0])
            }
            else {
                callback(error, nil)
            }
        }
    }
    
    /// Create a data item and return the new uid for that data item
    /// - Parameters:
    ///   - item: The data item to create on the pod
    ///   - callback: Function that is called when the task is completed either with the new uid, or an error
    public func create(_ item: DataItem,
                       _ callback: @escaping (_ error: Error?, _ uid: Int?) -> Void) -> Void {
        
        self.http(.POST, path: "items", body: toJSON(item, removeUID:true)) { error, data in
            callback(error, data != nil ? Int(String(data: data!, encoding: .utf8) ?? "") : nil)
        }
    }
    
    /// Updates a data item and returns the new version number
    /// - Parameters:
    ///   - item: The data item to update on the pod
    ///   - callback: Function that is called when the task is completed either with the new version number, or an error
    public func update(_ item:DataItem,
                       _ callback: @escaping (_ error: Error?, _ version: Int?) -> Void) -> Void {
                       
        self.http(.PUT, path: "items/\(item.memriID)", body: toJSON(item)) { error, data in
            callback(error, (data != nil ? Int(String(data: data!, encoding: .utf8) ?? "") : nil))
        }
    }
    
    /// Marks a data item as deleted on the pod.
    /// - Parameters:
    ///   - memriID: The memriID of the data item to remove
    ///   - callback: Function that is called when the task is completed either with a result, or  an error
    /// - Remark: Note that data items that are marked as deleted are by default not returned when querying
    public func remove(_ memriID:String,
                       _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) -> Void {
        
        self.http(.DELETE, path: "items/\(memriID)") { error, data in
            callback(error, error == nil)
        }
    }
    
    /// Queries the database for a subset of DataItems and returns a list of DataItems
    /// - Parameters:
    ///   - queryOptions: Object describing what to query and how to return the results
    ///   - callback: Function that is called when the task is completed either with the results, or  an error
    /// - Remark: The query language is a WIP
    public func query(_ queryOptions:Datasource,
                      _ callback: @escaping (_ error:Error?, _ result:[DataItem]?) -> Void) -> Void {
        
        // TODO Can no longer detect whether the data item is synced
//        if queryOptions.query!.test(#"^-\d+"#) { // test for uid that is negative
//            callback("nothing to do", nil)
//            return
//        }
        
        var data:Data? = nil
        
        let matches = queryOptions.query!.match(#"^(\w+) AND memriID = '(.+)'$"#)
        if matches.count == 3 {
            let type = matches[1]
            let memriID = matches[2]
            
            print("Requesting single \(type) with memriID \(memriID)")
            
            data = """
                {
                  items(func: type(\(type))) @filter(eq(memriID, \(memriID))) {
                    uid
                    type : dgraph.type
                    expand(_all_) {
                      uid
                      type : dgraph.type
                      expand(_all_) {
                        uid
                        memriID
                        type : dgraph.type
                      }
                    }
                  }
                }
            """.data(using: .utf8)
        }
        else {
            let type = queryOptions.query!.split(separator: " ").first ?? ""
            
            print("Requesting query result of \(type): \(queryOptions.query ?? "")")
            
            data = """
                {
                  items(func: type(\(type))) {
                    uid
                    type : dgraph.type
                    expand(_all_) {
                      uid
                      type : dgraph.type
                      expand(_all_) {
                        uid
                        memriID
                        type : dgraph.type
                      }
                    }
                  }
                }
            """.data(using: .utf8)
        }
        
        self.http(.POST, path: "all", body: data) { error, data in
            if let error = error {
                errorHistory.error("Could not load data from pod: \n\(error)")
                callback(error, nil)
            }
            else if let data = data {
                do {
                    var str = String(data: data, encoding: .utf8) ?? ""
                    
                    var items:[DataItem]?
                    try JSONErrorReporter() {
                        items = try MemriJSONDecoder
                            .decode(family: DataItemFamily.self, from: str.data(using: .utf8)!)
                    }
                    
                    callback(nil, items)
                }
                catch let error {
                    errorHistory.error("Could not load data from pod: \n\(error)")
                    callback(error, nil)
                }
            }
        }
        
    }
    
    /// Runs an importer on the pod
    /// - Parameters:
    ///   - memriID: The memriID of the data item to remove
    ///   - callback: Function that is called when the task is completed either with a result, or  an error
    public func runImport(_ memriID:String,
                       _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) -> Void {
        
        self.http(.PUT, path: "import/\(memriID)") { error, data in
            callback(error, error == nil)
        }
    }

    /// Runs an indexer on the pod
    /// - Parameters:
    ///   - memriID: The memriID of the data item to remove
    ///   - callback: Function that is called when the task is completed either with a result, or  an error
    public func runIndex(_ memriID:String,
                          _ callback: @escaping (_ error: Error?, _ success: Bool) -> Void) -> Void {
        
        self.http(.PUT, path: "index/\(memriID)") { error, data in
            callback(error, error == nil)
        }
    }
    
    
    
//    public func queryNLP(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
//
//    public func queryDSL(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
//
//    public func queryRAW(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

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
