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
        DatabaseController.read { $0.object(ofType: type, forPrimaryKey: uid) }
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
        DatabaseController.read {
            $0.objects(Edge.self).filter("""
                type = '\(type)'
                    AND sourceItemID = \(sourceItemID)
                    AND targetItemID = \(targetItemID)
            """).first
        }
    }
}

class DatabaseController {
    private init() {}

    static var realmTesting = false
    
    private static var realmConfig: Realm.Configuration {
        Realm.Configuration(
            // Set the file url
            fileURL: try! getRealmURL(),
            
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 101,

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
    static func getRealmAsync(_ receiveRealm: @escaping (Realm) throws -> Void) throws -> Void {
        try Authentication.getPublicRootKey { error, encryptionKey in
            var config = realmConfig
            config.encryptionKey = encryptionKey
            let realm = try Realm(configuration: config)
            try receiveRealm(realm)
        }
    }

    /// This function returns a Realm for the current thread
    static func getRealmSync() throws -> Realm {
        let encryptionKey = try Authentication.getPublicRootKeySync()
        var config = realmConfig
        config.encryptionKey = encryptionKey
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

    static func tryRead(_ doRead: @escaping (Realm) throws -> Void) throws {
        try getRealmAsync { realm in
            try doRead(realm)
        }
    }

    static func tryRead<T>(_ doRead: (Realm) throws -> T) throws -> T {
        let realm = try getRealmSync()
        return try doRead(realm)
    }

    static func read(_ doRead: (Realm) throws -> Void) {
        do {
            try tryRead(doRead)
        }
        catch {
            debugHistory.error("Realm Error: \(error)")
        }
    }

    static func read<T>(_ doRead: (Realm) throws -> T?) -> T? {
        do {
            return try tryRead(doRead)
        }
        catch {
            debugHistory.error("Realm Error: \(error)")
            return nil
        }
    }

    /// Use this for tasks that will affect user-visible behaviour. It will run on the current-thread.
    static func tryWriteSync(_ doWrite: @escaping (Realm) throws -> Void) throws {
        try getRealmAsync { realm in
            guard !realm.isInWriteTransaction else {
                try doWrite(realm)
                return
            }
            try realm.write {
                try doWrite(realm)
            }
        }
    }

    /// Use this for tasks that will affect user-visible behaviour. It will run on the current-thread.
    static func tryWriteSync<T>(_ doWrite: (Realm) throws -> T?) throws -> T? {
        let realm = try getRealmSync()
        guard !realm.isInWriteTransaction else {
            return try doWrite(realm)
        }
        try realm.write {
            return try doWrite(realm)
        }
        return nil
    }

    /// Use this for tasks that will affect user-visible behaviour. It will run on the current-thread.
    static func writeSync(_ doWrite: (Realm) throws -> Void) {
        do {
            try tryWriteSync(doWrite)
        }
        catch {
            debugHistory.error("Realm Error: \(error)")
        }
    }

    /// Use this for tasks that will affect user-visible behaviour. It will run on the current-thread.
    static func writeSync<T>(_ doWrite: (Realm) throws -> T?) -> T? {
        do {
            return try tryWriteSync(doWrite)
        }
        catch {
            debugHistory.error("Realm Error: \(error)")
            return nil
        }
    }

    /// Use this for writing to Realm in the background. It will run on a background thread.
    static func writeAsync(_ doWrite: @escaping (Realm) throws -> Void) {
        realmQueue.async {
            autoreleasepool {
                do {
                    try getRealmAsync { realm in
                        guard !realm.isInWriteTransaction else {
                            try doWrite(realm)
                            return
                        }
                        try realm.write {
                            try doWrite(realm)
                        }
                    }
                }
                catch {
                    debugHistory.error("Realm Error: \(error)")
                }
            }
        }
    }
    
    static func clean() {
        #warning("@Toby, deleting here on realm doesnt remove them from the db and thus this is called every time. Any idea why?")
        DatabaseController.writeSync { realm in
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
        }
    }
}
