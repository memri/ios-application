//
//  CachePubSub.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import RealmSwift

final class ItemSubscription<SubscriberType: Subscriber, Data: Item>: Subscription
    where SubscriberType.Input == Data {
    
    private var subscriber: SubscriberType?
    private let item: Data
    private let cache: Cache
    private let event: Cache.ItemChange
    private let wait: Double

    init (cache: Cache, subscriber: SubscriberType, item: Data, event: Cache.ItemChange, wait:Double) {
        self.subscriber = subscriber
        self.item = item
        self.cache = cache
        self.event = event
        self.wait = wait
        
        DispatchQueue.global(qos: .background).async {
            self.listen()
        }
    }
    
    func waitListen(_ retries:Int = 0, _ error:Error? = nil) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.wait) {
            self.listen(retries, error)
        }
    }
    
    func listen(_ retries:Int = 0, _ error:Error? = nil) {
        guard self.subscriber != nil else { return }
        
        guard let uid = item.uid.value else {
            debugHistory.error("Exception: Cannot subscribe to changes of an item without a uid")
            return
        }
        
        guard !item.deleted else {
            debugHistory.error("Exception: Cannot subscribe to changes of a deleted item")
            return
        }
        
        if case .create = self.event {
            debugHistory.error("Exception: Item is already created, cannot listen for create event")
            return
        }
        
        guard retries < 20 else {
            debugHistory.warn("Stopped polling after 20 retries with error: \(error ?? "")")
            return
        }
        
        cache.isOnRemote(item) { error in
            if error != nil {
                // How to handle??
                #warning("Look at this when implementing syncing")
                debugHistory.error("Polling timeout. All polling services disabled")
                return
            }
            
            self.cache.podAPI.get(uid) { error, item in
                if let error = error {
                    self.waitListen(retries + 1, error)
                    return
                }
                else if let item = item {
                    do {
                        if item.version > self.item.version {
                            if let cachedItem = try self.cache.addToCache(item) as? Data {
                                if case .update = self.event, cachedItem.deleted { return }
                                if case .update = self.event, !cachedItem.deleted { return }
                                _ = self.subscriber?.receive(cachedItem)
                            }
                            else {
                                throw "Exception: Could not parse item"
                            }
                        }
                    }
                    catch let error {
                        self.waitListen(retries + 1, error)
                        return
                    }
                }
                
                self.waitListen()
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        subscriber = nil
    }
}

struct ItemPublisher<Data: Item>: Publisher {
    typealias Output = Data
    typealias Failure = Never

    let item: Data
    let itemEvents: Cache.ItemChange
    let cache: Cache
    let wait: Double

    init(cache: Cache, item: Data, events: Cache.ItemChange, wait: Double) {
        self.item = item
        self.itemEvents = events
        self.cache = cache
        self.wait = wait
    }
    
    func receive<S>(subscriber: S) where S : Subscriber,
        S.Failure == ItemPublisher.Failure, S.Input == ItemPublisher.Output {
            
        // TODO
        let subscription = ItemSubscription(
            cache: self.cache,
            subscriber: subscriber,
            item: item,
            event: itemEvents,
            wait: wait
        )
        subscriber.receive(subscription: subscription)
    }
}

final class QuerySubscription<SubscriberType: Subscriber>: Subscription
    where SubscriberType.Input == [Item] {
    
    private var subscriber: SubscriberType?
    private let query: String
    private let cache: Cache
    private let event: Cache.ItemChange
    private let wait: Double

    init (cache: Cache, subscriber: SubscriberType, query: String, event: Cache.ItemChange, wait: Double) {
        self.subscriber = subscriber
        self.query = query
        self.cache = cache
        self.event = event
        self.wait = wait
        
        DispatchQueue.global(qos: .background).async {
            self.listen()
        }
    }
    
    func waitListen(_ retries:Int = 0, _ error:Error? = nil) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.wait) {
            self.listen(retries, error)
        }
    }
    
    func listen(_ retries:Int = 0, _ error:Error? = nil) {
        guard self.subscriber != nil else { return }
        
        guard query != "" else {
            debugHistory.error("Unable to start polling: Empty query")
            return
        }
        
        guard retries < 20 else {
            debugHistory.warn("Stopped polling after 20 retries with error: \(error ?? "").")
            return
        }
        
        self.cache.podAPI.query(Datasource(query: self.query), withEdges: false) { error, items in
            if let error = error {
                self.waitListen(retries + 1, error)
                return
            }
            else if let items = items {
                do {
                    var changes = [Item]()
                    for i in 0..<items.count {
                        let item = items[i]
                        
                        if let uid = item.uid.value {
                            if let cachedItem = getItem(item.genericType, uid) {
                                if item.version > cachedItem.version {
                                    if case .delete = self.event, !item.deleted { continue }
                                    else if case .create = self.event { continue }
                                }
                                else {
                                    continue
                                }
                            }
                            else { // Create
                                if case .update = self.event { continue }
                                if case .create = self.event { continue }
                            }
                                
                            let cachedItem = try self.cache.addToCache(items[i])
                            changes.append(cachedItem)
                        }
                    }
                    
                    if changes.count > 0 {
                        _ = self.subscriber?.receive(changes)
                    }
                }
                catch let error {
                    self.waitListen(retries + 1, error)
                    return
                }
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.wait) {
                self.waitListen()
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        subscriber = nil
    }
}

struct QueryPublisher: Publisher {
    typealias Output = [Item]
    typealias Failure = Never

    let query: String
    let itemEvents: Cache.ItemChange
    let cache: Cache
    let wait: Double

    init(cache: Cache, query: String, events: Cache.ItemChange, wait: Double) {
        self.query = query
        self.itemEvents = events
        self.cache = cache
        self.wait = wait
    }
    
    func receive<S>(subscriber: S) where S : Subscriber,
        S.Failure == QueryPublisher.Failure, S.Input == QueryPublisher.Output {
            
        // TODO
        let subscription = QuerySubscription(
            cache: cache,
            subscriber: subscriber,
            query: query,
            event: itemEvents,
            wait: wait
        )
        subscriber.receive(subscription: subscription)
    }
}

extension Cache {
    enum ItemChange {
        case create
        case update
        case delete
        case all
    }
    
    func isOnRemote(_ item: Item, _ retries: Int = 0, _ callback: @escaping (Error?) -> Void) {
        if retries > 20 {
            callback("Maximum retries reached")
            return
        }
        
        if item._action == "create" {
            sync.syncToPod()
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isOnRemote(item, retries + 1, callback)
            }
            return
        }
        
        callback(nil)
    }
    
    func subscribe(query: String, on events: ItemChange = .all, wait:Double = 0.5) -> QueryPublisher {
        return QueryPublisher(cache: self, query: query, events: events, wait: wait)
    }

    
    func subscribe(to item: Item, on events: ItemChange = .all, wait:Double = 0.5) -> ItemPublisher<Item> {
        return ItemPublisher(cache: self, item: item, events: events, wait: wait)
    }
}
