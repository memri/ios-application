//
//  DatabaseController.swift
//  memri
//
//  Created by Toby Brennan on 19/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class DatabaseController {
	private init() {}
	private static var realmConfig: Realm.Configuration = .defaultConfiguration
	
	
	/// This function returns a Realm for the current thread
	static func getRealm() -> Realm {
		guard !isOnRealmQueue else { return queueConfinedRealm } // If someone trys to write to realm while we're already in the realm queue this would lock the thread. Hence this check
		return try! Realm(configuration: realmConfig, queue: nil)
	}
	
	private static var realmQueue: DispatchQueue =  {
		let queue = DispatchQueue(label: "memri.realmQueue", qos: .utility)
		queue.setSpecific(key: realmQueueSpecificKey, value: true)
		return queue
	}()
	static let realmQueueSpecificKey = DispatchSpecificKey<Bool>()
	/// This is used internally to get a queue-confined instance of Realm
//	private static func getQueueConfinedRealm() -> Realm {
//		try! Realm(configuration: realmConfig, queue: realmQueue)
//	}
	static let queueConfinedRealm = try! Realm(configuration: realmConfig, queue: realmQueue)
	static var isOnRealmQueue: Bool {
		DispatchQueue.getSpecific(key: realmQueueSpecificKey) ?? false
	}
	
	static func tryRead(_ doRead: ((Realm) throws -> Void) ) throws {
		let realm = getRealm()
		try doRead(realm)
	}
	
	static func tryRead<T>(_ doRead: ((Realm) throws -> T?) ) throws -> T? {
		let realm = getRealm()
		return try doRead(realm)
	}
	
	static func read(_ doRead: ((Realm) throws -> Void) ) {
		do {
			try tryRead(doRead)
		}
		catch {
			debugHistory.error("Realm Error: \(error)")
		}
	}
	
	
	static func read<T>(_ doRead: ((Realm) throws -> T?) ) -> T? {
		do {
			return try tryRead(doRead)
		}
		catch {
			debugHistory.error("Realm Error: \(error)")
			return nil
		}
	}
	
	static func tryWriteSync(_ doWrite: ((Realm) throws -> Void) ) throws {
		let realm = getRealm()
		guard !realm.isInWriteTransaction else {
			try doWrite(realm)
			return
		}
		try realm.write {
			try doWrite(realm)
		}
	}
	
	static func tryWriteSync<T>(_ doWrite: ((Realm) throws -> T?) ) throws -> T? {
		let realm = getRealm()
		guard !realm.isInWriteTransaction else {
			return try doWrite(realm)
		}
		try realm.write {
			return try doWrite(realm)
		}
		return nil
	}
	
	static func writeSync(_ doWrite: ((Realm) throws -> Void) ) {
		do {
			try tryWriteSync(doWrite)
		}
		catch {
			debugHistory.error("Realm Error: \(error)")
		}
	}
	
	static func writeSync<T>(_ doWrite: ((Realm) throws -> T?)) -> T? {
		do {
			return try tryWriteSync(doWrite)
		}
		catch {
			debugHistory.error("Realm Error: \(error)")
			return nil
		}
	}
	
	static func writeAsync(_ doWrite: (@escaping (Realm) throws -> Void) ) {
		realmQueue.async {
			do {
				let realm = queueConfinedRealm
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
	
	static func writeAsync<T>(withResolvedReferenceTo objectReference: ThreadSafeReference<T>, _ doWrite: @escaping (Realm, T) throws -> Void) {
		realmQueue.async {
			do {
				let realm = queueConfinedRealm
				guard let threadSafeObject = realm.resolve(objectReference) else { return }
				
				guard !realm.isInWriteTransaction else {
					try doWrite(realm, threadSafeObject)
					return
				}
				
				try realm.write {
					try doWrite(realm, threadSafeObject)
				}
			} catch {
				debugHistory.error("Realm Error: \(error)")
			}
		}
	}
}
