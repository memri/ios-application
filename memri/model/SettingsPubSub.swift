//
// SettingsPubSub.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift

final class SettingSubscription<SubscriberType: Subscriber, T: Decodable>: Subscription
    where SubscriberType.Input == Any?
{
    private var id = UUID()
    private var subscriber: SubscriberType?
    private let path: String
    private let settings: Settings

    init(settings: Settings, subscriber: SubscriberType, path: String, type: T.Type) {
        self.subscriber = subscriber
        self.path = path
        self.settings = settings

        do {
            try self.settings.addListener(path, id, type: type) { value in
                _ = subscriber.receive(value)
            }
        }
        catch {
            debugHistory.warn("Unable to set listener for setting: \(path) : \(error)")
        }
    }

    func request(_: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        settings.removeListener(path, id)
        subscriber = nil
    }
}

struct SettingPublisher<T: Decodable>: Publisher {
    typealias Output = Any?
    typealias Failure = Never

    let path: String
    let settings: Settings
    let type: T.Type

    init(settings: Settings, path: String, type: T.Type) {
        self.path = path
        self.settings = settings
        self.type = type
    }

    func receive<S>(subscriber: S) where S: Subscriber,
        S.Failure == SettingPublisher.Failure, S.Input == SettingPublisher.Output
    {
        // TODO:
        let subscription = SettingSubscription(
            settings: settings,
            subscriber: subscriber,
            path: path,
            type: type
        )
        subscriber.receive(subscription: subscription)
    }
}

extension Settings {
    func subscribe<T>(_ path: String, type: T.Type = T.self) -> SettingPublisher<T> {
        SettingPublisher(settings: self, path: path, type: T.self)
    }
}
