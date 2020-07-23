//
// Definitions.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

public class CVUStoredDefinition: DataItem {
    @objc dynamic var type: String?
    @objc dynamic var name: String?
    @objc dynamic var selector: String?
    @objc dynamic var definition: String?
    @objc dynamic var query: String?
    @objc dynamic var domain: String = "user"
    override var genericType: String { "CVUStoredDefinition" }
}
