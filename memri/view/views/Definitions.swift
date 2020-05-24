//
//  Definitions.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class CVUStoredDefinition: DataItem {
    @objc dynamic var type: String? = nil
    @objc dynamic var selector: String? = nil
    @objc dynamic var definition: String? = nil
    @objc dynamic var domain: String = "user"
    override var genericType:String { "ViewDSLDefinition" }
}
