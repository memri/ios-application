//
//  Definitions.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class SessionsDefinition: DataItem {
    @objc dynamic var selector: String? = nil
    let sessions = RealmSwift.List<SessionDefinition>()
}

public class SessionDefinition: DataItem {
    @objc dynamic var selector: String? = nil
    let views = RealmSwift.List<ViewDSLDefinition>()
}

public class ViewDSLDefinition: DataItem {
    @objc dynamic var type: String? = nil
    @objc dynamic var selector: String? = nil
    @objc dynamic var definition: String? = nil
}
