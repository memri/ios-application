//
//  Sync.swift
//  memri
//
//  Created by Ruben Daniels on 4/3/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

///// This class represent the state of syncing for a Item, it keeps tracks of the multiple versions of a Item on the server and
///// what actions are needed to sync the Item with the latest version on the pod
// class SyncState: Object, Codable {
//	// Whether the data item is loaded partially and requires a full load
//	@objc dynamic var isPartiallyLoaded: Bool = false
//
//	// What action is needed on this data item to sync with the pod
//	// Enum: "create", "delete", "update"
//	@objc dynamic var actionNeeded: String = ""
//
//	// Which fields to update
//	let updatedFields = List<String>()
//
//	//
//	@objc dynamic var changedInThisSession = false
//
//	public required convenience init(from decoder: Decoder) throws {
//		self.init()
//
//		jsonErrorHandling(decoder) {
//			isPartiallyLoaded = try decoder.decodeIfPresent("isPartiallyLoaded") ?? isPartiallyLoaded
//		}
//	}
//
//	required init() {
//		super.init()
//	}
// }

/// Based on a query, Sync checks whether it still has the latest version of the resulting Items. It does this asynchronous and in the
/// background, items are updated automatically.
class Sync {
	/// PodAPI Object to use for executing queries
	private var podAPI: PodAPI
	/// Cache Object used to fetch resultsets
	public var cache: Cache?
    

	private var scheduled: Int = 0
	private var syncing: Bool = false
	private var backgroundSyncing: Bool = false

	private var recentQueries = [String: Bool]()

	/// Initialization of the cache
	/// - Parameters:
	///   - api: api Object
	///   - rlm: local Realm database object
	init(_ api: PodAPI) {
		podAPI = api

		// Periodically sync data from the pod
		// TODO:

		// Schedule syncing to the pod to see if there are any jobs that remain
		schedule()

		// Run any priority syncs in the background
		prioritySyncAll()
	}

	/// Schedule a query to sync the resulting Items from the pod
	/// - Parameter datasource: QueryOptions used to perform the query
	public func syncQuery(_ datasource: Datasource) {
		// TODO: if this query was executed recently, considering postponing action
		do {
			// Store query in a log item
			let audititem = AuditItem()
			let data = try MemriJSONEncoder.encode([ // TODO: move this to Datasource
				"query": datasource.query,
				"sortProperty": datasource.sortProperty,
				"sortAscending": datasource.sortAscending.value ?? false ? "true" : "false",
			] as? [String: String])
			
			audititem.uid.value = try Cache.incrementUID()
			audititem.content = String(data: data, encoding: .utf8) ?? ""
			audititem.action = "query"
			audititem.date = Date()
			
			// Set syncstate to "fetch" in order to get priority treatment for querying
			audititem.syncState?.actionNeeded = "fetch"
			// Add to realm
			realmWriteAsync(audititem) { realm, audititem in
				realm.add(audititem)
			}
			
			// Execute query with priority
			self.prioritySync(datasource, audititem)
		} catch {
			print("syncQuery failed: \(error)")
		}
	}

	public func clearSyncCache() {
		recentQueries = [:]
	}

	private func prioritySyncAll() {
		//
		if !backgroundSyncing {
			//
			backgroundSyncing = true

			// TODO: make async in order to not hurt init when cache is not set

			// Execute query objects
			//            prioritySync()

			//
			backgroundSyncing = false
		}
	}

	private func prioritySync(_ datasource: Datasource, _ audititem: AuditItem) {
		// Only execute queries once per session until we fix syncing
        
//        guard recentQueries[datasource.uniqueString] != true else {
//            return
//        }
        
        debugHistory.info("Syncing from pod with query: \(datasource.query ?? "")")
        
        // Call out to the pod with the query
        podAPI.query(datasource) { error, items in
            if let items = items {
                if let cache = self.cache {
                    self.recentQueries[datasource.uniqueString] = true

                    // Find resultset that belongs to this query
                    let resultSet = cache.getResultSet(datasource)
                    //                    if resultSet.count == 1 { return }

                    for item in items {
                        // TODO: handle sync errors
                        do {
                            _ = try cache.addToCache(item)
                        } catch {
                            debugHistory.error("\(error)")
                        }
                    }

                    do {
                        // Update resultset with the new results
                        try resultSet.reload()
                    } catch {
                        debugHistory.error("\(error)")
                    }

                    // We no longer need to process this log item
                    realmWriteAsync(audititem) { _, audititem in
                        audititem.setSyncStateActionNeeded("")
                    }
                }
            } else {
                // Ignore errors (we'll retry next time)
                // TODO: consider resorting so that it is not retried too often
            }
        }
	}

	/// Schedule a syncing round
	/// - Remark: currently calls mock code
	/// - TODO: implement syncToPod()
	public func schedule(long: Bool = false) {
		// Don't schedule when we are already scheduled
		if scheduled == 0 || !long && scheduled == 2 {
			// Prevent multiple calls to the dispatch queue
			scheduled = long ? 2 : 1

			// Wait 100ms before syncing (should this be longer?)
			DispatchQueue.main.asyncAfter(deadline: .now() + (long ? 18000 : 0.1)) {
				if self.syncing {
					self.scheduled = 0
					self.schedule()
					return
				}

				// Reset scheduled
				self.scheduled = 0

				// Start syncing local data to the pod
				self.syncToPod()
			}
		}
	}

	public func syncToPod() {
		func markAsDone(_ list: [String: Any]) {
			for (_, sublist) in list {
				for item in sublist as? [Any] ?? [] {
					if let item = item as? ThreadSafeReference<SchemaItem> {
						realmWriteAsync(item) { realm, item in
							if item.syncState?.actionNeeded == "delete" {
								realm.delete(item)
							}
							else {
								item.syncState?.actionNeeded = ""
								item.syncState?.updatedFields.removeAll()
							}
						}
					} else if let item = item as? ThreadSafeReference<Edge> {
						realmWriteAsync(item) { realm, item in
							if item.syncState?.actionNeeded == "delete" {
								realm.delete(item)
							}
							else {
								item.syncState?.actionNeeded = ""
								item.syncState?.updatedFields.removeAll()
							}
						}
					}
				}
			}
		}
        
        realmReadAsync { (realm) in
            #warning("@Ruben, I have added this guard check here to avoid starting again if already syncing... but not sure if it should be there?")
            guard !self.syncing else { return }
            self.syncing = true
            
            var found = 0
            var itemQueue: [String: [SchemaItem]] = ["create": [], "update": [], "delete": []]
            var edgeQueue: [String: [Edge]] = ["create": [], "update": [], "delete": []]
            
            // Items
            for itemType in ItemFamily.allCases {
                if itemType == .typeUserState { continue }
                
                if let type = itemType.getType() as? SchemaItem.Type {
                    let items = realm.objects(type).filter("syncState.actionNeeded != ''")
                    for item in items {
                        if let action = item.syncState?.actionNeeded, itemQueue[action] != nil {
                            itemQueue[action]?.append(item)
                            found += 1
                        }
                    }
                }
            }
            
            // Edges
            let edges = realm.objects(Edge.self).filter("syncState.actionNeeded != ''")
            for edge in edges {
                if let action = edge.syncState?.actionNeeded, edgeQueue[action] != nil {
                    edgeQueue[action]?.append(edge)
                    found += 1
                }
            }
			
			let safeItemQueue = itemQueue.mapValues {
				$0.map { ThreadSafeReference(to: $0) }
			}
			
			let safeEdgeQueue = edgeQueue.mapValues {
				$0.map { ThreadSafeReference(to: $0) }
			}
            
			
            if found > 0 {
                debugHistory.info("Syncing to pod with \(found) changes")
                do {
                    try self.podAPI.sync(
                        createItems: itemQueue["create"],
                        updateItems: itemQueue["update"],
                        deleteItems: itemQueue["delete"],
                        createEdges: edgeQueue["create"],
                        updateEdges: edgeQueue["update"],
                        deleteEdges: edgeQueue["delete"]
                    ) { (error) -> Void in
                        self.syncing = false
                        
                        if let error = error {
                            debugHistory.error("Could not sync to pod: \(error)")
                            self.schedule(long: true)
                        }
                        else {
                            #warning("Items/Edges could have changed in the mean time, check dateModified/AuditItem")
                            markAsDone(safeItemQueue)
                            markAsDone(safeEdgeQueue)
                            
                            self.schedule()
                        }
                    }
                } catch {
                    debugHistory.error("Could not sync to pod: \(error)")
                }
            } else {
                self.schedule(long: true)
            }
        }
	}

	private func syncFromPod() {
		// TODO:
	}

//	/// - Remark: Currently unused
//	/// - TODO: Implement and document
//	/// - Parameters:
//	///   - item:
//	///   - callback:
//	/// - Throws:
//	public func execute(_ item: Item, callback: @escaping (_ error: Error?, _ success: Bool) -> Void) throws {
//		if let syncState = item.syncState {
//			switch syncState.actionNeeded {
//			case "create", "delete", "update":
//				try podAPI.sync(item) { (error, _) -> Void in
//					if error != nil { return callback(error, false) }
//				}
//			case "fetch":
//				// TODO:
//				break
//			default:
//				// Ignore unknown tasks
//				print("Unknown sync state action: \(item.syncState?.actionNeeded ?? "")")
//			}
//		} else {
//			throw "No syncState defined"
//		}
//	}
}
