//
// DatabaseController.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

class ItemReference {
    let uid: Int
    let type: Item.Type

    init(to: Item) {
        uid = to.uid.value ?? -1
        type = to.getType() ?? Item.self
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
        type = to.type ?? ""
        sourceItemID = to.sourceItemID.value ?? -1
        targetItemID = to.targetItemID.value ?? -1
    }

    func resolve() -> Edge? {
        DatabaseController.read {
            $0.objects(Edge.self)
                .filter(
                    "type = '\(type)' AND sourceItemID = \(sourceItemID) AND targetItemID = \(targetItemID)"
                )
                .first
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
    static func getRealm() -> Realm {
        try! Realm(configuration: realmConfig)
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

    static func tryRead(_ doRead: (Realm) throws -> Void) throws {
        let realm = getRealm()
        try doRead(realm)
    }

    static func tryRead<T>(_ doRead: (Realm) throws -> T) throws -> T {
        let realm = getRealm()
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
    static func tryWriteSync(_ doWrite: (Realm) throws -> Void) throws {
        let realm = getRealm()
        guard !realm.isInWriteTransaction else {
            try doWrite(realm)
            return
        }
        try realm.write {
            try doWrite(realm)
        }
    }

    /// Use this for tasks that will affect user-visible behaviour. It will run on the current-thread.
    static func tryWriteSync<T>(_ doWrite: (Realm) throws -> T?) throws -> T? {
        let realm = getRealm()
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
                    let realm = getRealm()
                    guard !realm.isInWriteTransaction else {
                        try doWrite(realm)
                        return
                    }
                    try realm.write {
                        try doWrite(realm)
                    }
                }
                catch {
                    debugHistory.error("Realm Error: \(error)")
                }
            }
        }
    }

    /// Use this for writing to Realm in the background. It will run on a background thread.
    static func writeAsync<T>(
        withResolvedReferenceTo objectReference: ThreadSafeReference<T>,
        _ doWrite: @escaping (Realm, T) throws -> Void
    ) {
        realmQueue.async {
            autoreleasepool {
                do {
                    let realm = getRealm()
                    guard let threadSafeObject = realm.resolve(objectReference) else { return }

                    guard !realm.isInWriteTransaction else {
                        try doWrite(realm, threadSafeObject)
                        return
                    }

                    try realm.write {
                        try doWrite(realm, threadSafeObject)
                    }
                }
                catch {
                    debugHistory.error("Realm Error: \(error)")
                }
            }
        }
    }
}
