//
//  SessionView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class SessionView: DataItem {
 
    override var genericType:String { "SessionView" }
 
    @objc dynamic var name: String? = nil
    @objc dynamic var viewDefinition: CVUStoredDefinition? = nil
    @objc dynamic var userState: UserState? = nil
    @objc dynamic var viewArguments: ViewArguments? = nil
    @objc dynamic var datasource: Datasource? = nil // TODO refactor: fix cascading
    @objc dynamic var session: Session? = nil
    
    override var computedTitle:String {
//        if let value = self.name ?? self.title { return value }
//        else if let rendererName = self.rendererName {
//            return "A \(rendererName) showing: \(self.datasource?.query ?? "")"
//        }
//        else if let query = self.datasource?.query {
//            return "Showing: \(query)"
//        }
        return "[No Name]"
    }
    
    required init(){
        super.init()
        
        self.functions["computedDescription"] = {_ in
            print("MAKE THIS DISSAPEAR")
            return self.computedTitle
        }
    }
    
    public class func fromCVUDefinition(_ def:CVUParsedViewDefinition) -> SessionView {
        return SessionView(value: [
            "selector": def.selector ?? "[view]",
            "name": def["name"] as? String ?? "",
            "viewDefinition": CVUStoredDefinition(value: [
                "type": "view",
                "selector": def.selector,
                "domain": def.domain,
                "definition": def.toCVUString(0, "    ")
            ])
        ])
    }

}
