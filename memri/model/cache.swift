//
//  cache.swift
//  memri
//
//  Created by Ruben Daniels on 3/12/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

var config = Realm.Configuration(
//    fileURL: URL(string: "file:///Users/rubendaniels/Development/realm/memri.realm"),
    
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).
    schemaVersion: 24,

    // Set the block which will be called automatically when opening a Realm with
    // a schema version lower than the one set above
    migrationBlock: { migration, oldSchemaVersion in
        // We haven’t migrated anything yet, so oldSchemaVersion == 0
        if (oldSchemaVersion < 2) {
            // Nothing to do!
            // Realm will automatically detect new properties and removed properties
            // And will update the schema on disk automatically
        }
    })

// Schedules long term tasks like syncing with remote
public class Scheduler {
    private var queue:Results<Task>
    private var realm:Realm
    public var cache:Cache? = nil
    private var busy:Bool = false
    
    init(_ rlm:Realm) {
        realm = rlm
        
        // For a future solution: https://stackoverflow.com/questions/46344963/swift-jsondecode-decoding-arrays-fails-if-single-element-decoding-fails
        
        queue = realm.objects(Task.self)
        processQueue()
    }
    
    /**
     *
     */
    public func add(_ item:DataItem) {
        // Don't add the same update to the queue more than once
        let result = queue.filter("item.uid = '\(item.getString("uid"))'")
        if result.count > 0 { return }
        
        // Add a task (should be auto added to the realm result set)
        realm.create(Task.self, value: ["item":item])
        
        // Continue processing the queue
        processQueue()
    }
    
    /**
     *
     */
    public func remove(_ item:DataItem) {
        // Don't add the same update to the queue more than once
        let result = queue.filter("item.uid = '\(item.getString("uid"))'")
        if let task = result.first {
            realm.delete(task)
        }
    }
    
    public func remove(_ task:Task) {
        realm.delete(task)
    }
    
    /**
     *
     */
    // TODO add concurrency
    // TODO time-delay
    public func processQueue(){
        // Already working
        if busy { return }
        
        // Nothing to do
        if queue.count == 0 { return }
        
        let task = queue[0]
        busy = true;

        // TODO catch
        try? cache!.execute(task) { (error, success) -> Void in
            remove(task)
            if !success {  // TODO keep a retry counter to not have stuck jobs ??
                add(task.item!)
            }
            busy = false
            processQueue()
        }
    }
}

// Represents a task such as syncing with remote
public class Task: Object, Codable {
    @objc dynamic var item:DataItem?
}

func getRealmPath() -> String{
    let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]!
    let realmDir = homeDir + "/realm.memri"
    do {
        try FileManager.default.createDirectory(atPath: realmDir, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print(error)
    }
    return realmDir
}

public class Cache {
    var podAPI: PodAPI
    
    var cancellables:[AnyCancellable]? = nil
    var queryCache:[String:SearchResult] = [:]
    
    private var scheduler:Scheduler
    private var realm:Realm
    
    enum CacheError: Error {
        case UnknownTaskJob(job: String)
    }
    
    public init(_ podAPI: PodAPI){
        
                
        // Tell Realm to use this new configuration object for the default Realm
        #if targetEnvironment(simulator)
            config.fileURL = URL(string: "file://\(getRealmPath())/memri.realm")
        #endif
        
        Realm.Configuration.defaultConfiguration = config

        realm = try! Realm()
        
        print("Starting realm at \(Realm.Configuration.defaultConfiguration.fileURL!)")
        
        self.podAPI = podAPI
        
        // Create scheduler objects
        scheduler = Scheduler(realm)
        scheduler.cache = self
    }
    
    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    public func query(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]?, _ cached:Bool?) -> Void) {
        var receivedFromServer = false
        func handle (_ error:Error?, _ items:[DataItem]?, _ cached:Bool) -> Void {
            if receivedFromServer { return } 
            receivedFromServer = !cached
            
            if (error != nil) {
                callback(error, nil, nil)
                return
            }
            
            // Add all new data items to the cache
            var data:[DataItem] = []
            if let items = items {
                if items.count > 0 {
                    for i in 0...items.count - 1 {
                        data.append(self.addToCache(items[i]))
                    }
                }
            }
            
            callback(nil, data, cached)
        }
        
        queryLocal(query) { (error, items) in handle(error, items, true) }
        podAPI.query(query) { (error, items) in handle(error, items, false) }
    }
    
    /**
     *
     */
    public func queryLocal(_ query:QueryOptions, _ callback: (_ error: Error?, _ items: [DataItem]?) -> Void) -> Void {
        let q = query.query ?? ""
        if (q != "") {
            callback("Empty Query", nil)
        }
        else if (q.starts(with: "0x")) {
            let result = realm.objects(Note.self).filter("id = '\(q)'") // HACK
            
            callback(nil, [result[0]])
        }
        else {
            let type = DataItemFamily(rawValue: q)
            if let type = type {
                let queryType = DataItemFamily.getType(type)
                let result = realm.objects(queryType()) // TODO filter
                
                var returnValue:[DataItem] = []
                for item in result { returnValue.append(item) }
                
                callback(nil, returnValue)
            }
            else {
                callback(nil, [])
            }
        }
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: [DataItem]) -> Void) -> Void {}
    public func fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem]{ [DataItem()]}
    
    /**
     *
     */
    public func getItemById<T:DataItem>(_ type:String, _ uid: String) -> T? {
        let type = DataItemFamily(rawValue: type)
        if let type = type {
            let item = DataItemFamily.getType(type)
            return realm.objects(item()).filter("uid = '\(uid)'").first as! T?
        }
        return nil
    }

    /**
     *
     */
    func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
    private func generateUID() -> String {
        let counter = UUID().uuidString
        return "0xNEW\(counter)"
    }

    /**
     *
     */
    public func addToCache(_ item:DataItem) -> DataItem {
        // Fetch item from the cache
        var cachedItem:DataItem?
        if let uid = item.uid {
            cachedItem = self.getItemById(item.type, uid)
        }
        else {
            item.uid = generateUID()
        }
        
        // Update properties to the cached item that are not nil
        if let cachedItem = cachedItem {
            let properties = cachedItem.objectSchema.properties
            var value:[String:Any] = [:]
            for prop in properties {
                if (item[prop.name] != nil) {
                    value[prop.name] = item[prop.name]
                }
            }
            
            let type = DataItemFamily(rawValue: item.type)
            if let type = type {
                let itemType = DataItemFamily.getType(type)
                try! realm.write() {
                    realm.create(itemType(), value: value, update: .modified) // Should update cachedItem
                }
            }
        }
        // Or, if its not in the cache, add to the cache
        else {
            try! realm.write() {
                realm.add(item) // , update: .modified
            }
            cachedItem = item
        }
        
        // TODO hook updates using realm.observe()
        let _ = cachedItem!.observe { (change) in
            switch (change){
            case .deleted:
                self.onRemove(item)
            case .change:
                if item.getString("uid").starts(with: "0xNEW") { // HACK
                    self.onCreate(item)
                }
                else {
                    // change = dict of changes
                    self.onUpdate(item)
                }
            case .error(let error):
                print(error)
            }
            
            item.objectWillChange.send()
        }

        // Return item from the cache
        return cachedItem ?? item
    }
    
    public func loadPage(_ searchResult:SearchResult, _ index:Int, _ callback:((_ error:Error?) -> Void)) -> Void {
        // Set state to loading
        searchResult.loading = 1
        
        if searchResult.query.query == "" {
            callback("No query specified")
            return
        }
        
        let _ = self.query(searchResult.query) { (error, result, success) -> Void in
            if (error != nil) {
                /* TODO: trigger event or so */

                // Loading error
                searchResult.loading = -2

                callback(error)
                return
            }

            // TODO this only works when retrieving 1 page. It will break for pagination
            if let result = result { searchResult.data = result }

            // We've successfully loaded page 0
            searchResult.pages[0] = true;

            // First time loading is done
            searchResult.loading = -1

            callback(nil)
        }
    }
    
    /**
     * Client side filter //, with a fallback to the server
     */
    public func filter(_ searchResult:SearchResult, _ query:String) -> SearchResult {
        var options = searchResult.query
        options.query = query
        
        let filterResult = SearchResult(options, searchResult.data)
        filterResult.loading = searchResult.loading
        filterResult.pages = searchResult.pages
        
        for i in stride(from: filterResult.data.count - 1, through: 0, by: -1) {
            if (!filterResult.data[i].match(query)) {
                filterResult.data.remove(at: i)
            }
        }

        return filterResult
    }
        
    /**
     * Executes the query again
     */
    public func reload(_ searchResult:SearchResult) -> Void {
        // Reload all pages
        for (page, _) in searchResult.pages {
            let _ = self.loadPage(searchResult, page, { (error) in })
        }
    }
    
    /**
     *
     */
    public func resort(_ options:QueryOptions) {
        
    }
    
    
    /**
     * Does not copy the id property
     */
    public func duplicate(_ item:DataItem) -> DataItem {
        let type = DataItemFamily(rawValue: item.type)!
        let T = DataItemFamily.getType(type)
        let copy = T().init()
        let properties = item.objectSchema.properties
        for prop in properties {
            if prop.name == "uid" { continue }
            copy[prop.name] = item[prop.name]
        }
        return copy
    }
    
    /**
     *
     */
    public func addToCache(_ result:SearchResult) {
        // Overwrite past results (even though sorting options etc, may differ ...
        if let q = result.query.query {
            self.queryCache[q] = result
        }
    }
    
    /**
     *
     */
    public func execute(_ task:Task, callback: (_ error:Error?, _ success:Bool) -> Void) throws {
        if let item = task.item {
            switch item.loadState.actionNeeded {
            case .create:
                podAPI.create(item) { (error, id) -> Void in
                    if error != nil { return callback(error, false) }
                    
                    // Set the new id from the server
                    item.uid = id
                    
                    callback(nil, true)
                }
            case .delete:
                podAPI.remove(item.getString("uid")) { (error, success) -> Void in
                    callback(error, success)
                }
            case .update:
                podAPI.update(item, callback)
            default:
                throw CacheError.UnknownTaskJob(job: item.loadState.actionNeeded.rawValue)
            }
        }
    }
    
    var newCounter = 0
    private func onCreate(_ item:DataItem) {
        // Store in local storage
        try! realm.write() {
            realm.add(item) // , update: .modified
        }
        
        // Create a task
        item.loadState.actionNeeded = .create
        scheduler.add(item)
    }
    private func onRemove(_ item:DataItem) {
        if item.id == "" { return } // TODO edge case when it is being created...
        
        try! realm.write() {
            realm.delete(item)
        }
        
        // Create a task
        item.loadState.actionNeeded = .delete
        scheduler.add(item)
    }
    private func onUpdate(_ item:DataItem) {
        // Update a task
        item.loadState.actionNeeded = .update
        scheduler.add(item)
    }
}
