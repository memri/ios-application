//
// LocalSettings.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

class LocalSetting: Object {
    @objc var key: String?
    @objc var value: String?

    /// Primary key used in the realm database of this Item
    override public static func primaryKey() -> String? {
        "key"
    }

    public class func set(_ key: String, _ value: String) {
        DatabaseController
            .asyncOnCurrentThread(write: true, error: { debugHistory.warn("\($0)") }) { realm in
                if let setting = realm.object(ofType: LocalSetting.self, forPrimaryKey: key) {
                    setting.value = value
                }
                else {
                    realm.create(LocalSetting.self, value: ["key": key, "value": value])
                }
            }
    }

    public class func get(_ key: String) -> String? {
        DatabaseController.sync(write: true) { realm in
            if let setting = realm.object(ofType: LocalSetting.self, forPrimaryKey: key) {
                return setting["value"] as? String
            }
            return nil
        }
    }
}
