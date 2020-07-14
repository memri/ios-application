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

    init (cache: Cache, subscriber: SubscriberType, item: Data, event: Cache.ItemChange) {
        self.subscriber = subscriber
        self.item = item
        self.cache = cache
        self.event = event
        
        do {
            try listen()
        }
        catch let error {
            debugHistory.error("\(error)")
        }
    }
    
    func listen(_ retries:Int = 0) throws {
        guard let uid = item.uid.value else {
            throw "Exception: Cannot subscribe to changes of an item without a uid"
        }
        
        guard !item.deleted else {
            throw "Exception: Cannot subscribe to changes of a deleted item"
        }
        
        if case .create = self.event {
            throw "Exception: Item is already created, cannot listen for create event"
        }
        
        guard retries < 20 else {
            return
        }
        
        if item.syncState?.actionNeeded == "create" {
            cache.sync.syncToPod()
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                try? self.listen(retries + 1)
            }
            return
        }
        
        // Poll every second
        // TODO: make this an option?
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            
            self.cache.podAPI.get(uid) { error, item in
                if let error = error {
                    debugHistory.warn("Received error polling item: \(error)")
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
                        debugHistory.warn("Received error polling item: \(error)")
                    }
                }
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

    init(cache: Cache, item: Data, events: Cache.ItemChange) {
        self.item = item
        self.itemEvents = events
        self.cache = cache
    }
    
    func receive<S>(subscriber: S) where S : Subscriber,
        S.Failure == ItemPublisher.Failure, S.Input == ItemPublisher.Output {
            
        // TODO
        let subscription = ItemSubscription(
            cache: self.cache,
            subscriber: subscriber,
            item: item,
            event: itemEvents
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

    init (cache: Cache, subscriber: SubscriberType, query: String, event: Cache.ItemChange) {
        self.subscriber = subscriber
        self.query = query
        self.cache = cache
        self.event = event
        
        do {
            try listen()
        }
        catch let error {
            debugHistory.error("\(error)")
        }
    }
    
    func listen(_ retries:Int = 0) throws {
        guard query != "" else {
            throw "Exception: empty query"
        }
        
        guard retries < 20 else {
            return
        }
        
        // Poll every second
        // TODO: make this an option?
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            
            self.cache.podAPI.query(Datasource(query: self.query), withEdges: false) { error, items in
                if let error = error {
                    debugHistory.warn("Received error polling item: \(error)")
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
                        debugHistory.warn("Received error polling item: \(error)")
                    }
                }
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

    init(cache: Cache, query: String, events: Cache.ItemChange) {
        self.query = query
        self.itemEvents = events
        self.cache = cache
    }
    
    func receive<S>(subscriber: S) where S : Subscriber,
        S.Failure == QueryPublisher.Failure, S.Input == QueryPublisher.Output {
            
        // TODO
        let subscription = QuerySubscription(
            cache: self.cache,
            subscriber: subscriber,
            query: query,
            event: itemEvents
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
    
    func subscribe(query: String, on events: ItemChange = .all) -> QueryPublisher {
        return QueryPublisher(cache: self, query: query, events: events)
    }

    
    func subscribe(to item: Item, on events: ItemChange = .all) -> ItemPublisher<Item> {
        return ItemPublisher(cache: self, item: item, events: events)
    }
}
