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
    let views = RealmSwift.List<SessionViewDefinition>()
}

public class BaseDefinition: DataItem {
    @objc dynamic var selector: String? = nil
    @objc dynamic var definition: String? = nil
}

public class SessionViewDefinition: BaseDefinition {
    
}

public class RenderDefinition: BaseDefinition {
}

public class ColorDefinition: BaseDefinition {
}

public class StyleDefinition: BaseDefinition {
}

public class LanguageDefinition: BaseDefinition {
}

public class ViewParseContext {
    // subscript
}
