//
// DatabaseController.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

class ItemReference {
    let uid: Int
    let type: Item.Type

    init(to: Item) {
        guard let uid = to.uid.value, let type = to.getType(), to.realm != nil else {
            fatalError("Trying to get a reference to an item that is not in realm or has no uid")
        }
        
        self.uid = uid
        self.type = type
    }

    func resolve() -> Item? {
        do {
            return try DatabaseController.tryCurrent {
                $0.object(ofType: self.type, forPrimaryKey: self.uid)
            }
        }
        catch {
            return nil
        }
    }
}

class EdgeReference {
    let type: String
    let sourceItemID: Int
    let targetItemID: Int

    init(to: Edge) {
        guard
            let type = to.type,
            let targetItemID = to.targetItemID.value,
            let sourceItemID = to.sourceItemID.value,
            to.realm != nil
        else {
            fatalError("Trying to get a reference to an edge that is not in realm or has no uid")
        }
        
        self.type = type
        self.sourceItemID = sourceItemID
        self.targetItemID = targetItemID
    }

    func resolve() -> Edge? {
        do {
            return try DatabaseController.tryCurrent {
                $0.objects(Edge.self).filter("""
                    type = '\(self.type)'
                        AND sourceItemID = \(self.sourceItemID)
                        AND targetItemID = \(self.targetItemID)
                """).first
            }
        }
        catch {
            return nil
        }
    }
}

class DatabaseController {
    private init() {}

    #if targetEnvironment(simulator)
    static var realmTesting = false
    static var reportedKey = false
    #else
    static let realmTesting = false
    #endif
    
    private static var realmConfig: Realm.Configuration {
        Realm.Configuration(
            // Set the file url
            fileURL: try! getRealmURL(),
            
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 110,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { _, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 2 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            }
        )
    }

    /// Computes the Realm database path at /home/<user>/realm.memri/memri.realm and creates the directory (realm.memri) if it does not exist.
    /// - Returns: the computed database file path
    static func getRealmURL() throws -> URL {
        #if targetEnvironment(simulator)
            if let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
                var realmDir = homeDir + "/memriDevData/realm.memri"

                if realmTesting {
                    realmDir += ".testing"
                }

                do {
                    try FileManager.default.createDirectory(atPath:
                        realmDir, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print(error)
                }

//            print("Using realm at \(realmDir + "/memri.realm")")

                let realmURL = URL(fileURLWithPath: realmDir + "/memri.realm")
                return realmURL
            }
            else {
                throw "Could not get realm url"
            }
        #else
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory.appendingPathComponent("memri.realm")
        #endif
    }
    
    /// This function returns a Realm for the current thread
    static func getRealmAsync(_ receiveRealm: @escaping (Error?, Realm?) -> Void) -> Void {
        Authentication.getPublicRootKey { error, data in
            guard let data = data else {
                receiveRealm(error, nil)
                return
            }
            
            var config = realmConfig
            
            if !realmTesting {
                #if targetEnvironment(simulator)
                if !reportedKey {
                    print("REALM KEY: \(data.hexEncodedString(options: .upperCase))")
                    reportedKey = true
                }
                #endif
                
                config.encryptionKey = data
            }
            
            do {
                let realm = try Realm(configuration: config)
                receiveRealm(nil, realm)
            }
            catch {
                // TODO error handling
                // Notify the user
                debugHistory.error("\(error)")
                receiveRealm(error, nil)
            }
        }
    }
    
    /// This function returns a Realm for the current thread
    static func getRealmSync() throws -> Realm {
        let data = try Authentication.getPublicRootKeySync()
        var config = realmConfig
        if !realmTesting {
            #if targetEnvironment(simulator)
            if !reportedKey {
                reportedKey = true
                print("REALM KEY: \(data.hexEncodedString(options: .upperCase))")
                Authentication.getOwnerAndDBKey { err, owner, db in
                    if err != nil {
                        reportedKey = false
                        return
                    }
                    
                    print("OWNER KEY: \(owner ?? "")")
                    print("DB KEY: \(db ?? "")")
                }
            }
            #endif
            
            config.encryptionKey = data
        }
        return try Realm(configuration: config)
    }
    
    private static var realmQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "memri.realmQueue", qos: .utility)
        return queue
    }()

    //	static let realmQueueSpecificKey = DispatchSpecificKey<Bool>()
    /// This is used internally to get a queue-confined instance of Realm
    //	private static func getQueueConfinedRealm() -> Realm {
    //		try! Realm(configuration: realmConfig, queue: realmQueue)
    //	}
    //	static var isOnRealmQueue: Bool {
    //		DispatchQueue.getSpecific(key: realmQueueSpecificKey) ?? false
    //	}
    
    /// Execute a realm based function on the current thread
    static func current(
        write:Bool = false,
        error:(@escaping (Error) -> Void) = globalErrorHandler,
        _ exec:@escaping (Realm) throws -> Void
    ) {
        getRealmAsync { err, realm in
            if let err = err {
                error(err)
                return
            }
            
            guard let realm = realm else {
                error("Unable to initialize realm")
                return
            }
            
            do {
                if write {
                    guard !realm.isInWriteTransaction else {
                        try exec(realm)
                        return
                    }
                    
                    try realm.write {
                        try exec(realm)
                    }
                }
                else {
                    try exec(realm)
                }
            }
            catch let err {
                error(err)
            }
        }
    }
    
    /// Execute a realm based function that returns a value on the main thread
    static func current<T>(
        write:Bool = false,
        _ exec:@escaping (Realm) throws -> T?
    ) -> T? {
        do {
            return try tryCurrent(write: write, exec)
        }
        catch {
            debugHistory.warn("\(error)")
            return nil
        }
    }
    
    /// Execute a realm based function that throws and returns a value on the main thread
    static func tryCurrent<T>(
        write:Bool = false,
        _ exec:@escaping (Realm) throws -> T?
    ) throws -> T? {
        let realm = try getRealmSync()
        
        if write {
            guard !realm.isInWriteTransaction else {
                return try exec(realm)
            }
            
            return try realm.write {
                try exec(realm)
            }
        }
        else {
            return try exec(realm)
        }
    }
    
    /// Execute a realm based function on a background thread
    static func background(
        write:Bool = false,
        error:(@escaping (Error) -> Void) = globalErrorHandler,
        _ exec:@escaping (Realm) throws -> Void
    ) {
        realmQueue.async {
            autoreleasepool {
                current(write: write, error: error, exec)
            }
        }
    }
    
    /// Execute a realm based function on the main thread (warning this blocks the UI)
    static func main(
        write:Bool = false,
        error:(@escaping (Error) -> Void) = globalErrorHandler,
        _ exec:@escaping (Realm) throws -> Void
    ) {
        DispatchQueue.main.async {
            autoreleasepool {
                current(write: write, error: error, exec)
            }
        }
    }
    
    static func write(_ rlm:Realm?, _ exec: () throws -> Void) {
        do {
            let realm:Realm = rlm == nil ? try getRealmSync() : rlm!
            
            guard !realm.isInWriteTransaction else {
                return try exec()
            }
            
            return try realm.write {
                try exec()
            }
        }
        catch {
            debugHistory.warn("\(error)")
        }
    }
    
    static func globalErrorHandler(error:Error) {
        debugHistory.error("\(error)")
    }
    
    static func deleteDatabase(_ callback:@escaping (Error?) -> Void) {
        Authentication.authenticateOwnerByPasscode { error in
            if let error = error {
                callback("Unable to authenticate: \(error)")
                return
            }
            
            do {
                let fileManager = FileManager.default
                let realmUrl = try getRealmURL()
                
                // Check if realm database exists
                if fileManager.fileExists(atPath: realmUrl.path) {
                    try fileManager.removeItem(at: realmUrl)
                }
                
                callback(nil)
            }
            catch {
                callback("Could not remove realm database: \(error)")
            }
        }
    }

    static func clean(_ callback:@escaping (Error?) -> Void) {
        #warning("@Toby, deleting here on realm doesnt remove them from the db and thus this is called every time. Any idea why?")
        DatabaseController.background(write: true, error: callback) { realm in
            for itemType in ItemFamily.allCases {
                if itemType == .typeUserState { continue }

                if let type = itemType.getType() as? Item.Type {
                    let items = realm.objects(type).filter("_action == nil and deleted = true")
                    for item in items {
//                        item.allEdges.forEach { edge in
//                            realm.delete(edge)
//                        }
                        realm.delete(item.allEdges)
                        realm.delete(item)
                    }
                }
                
                let edges = realm.objects(Edge.self).filter("_action == nil and deleted = true")
                for edge in edges {
                    realm.delete(edge)
                }
            }
            
            callback(nil)
        }
    }
}
