//
//  Other.swift
//  memri
//
//  Created by Ruben Daniels on 6/25/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Note {
    override var computedTitle:String {
        return "\(title ?? "")"
    }
}

extension PhoneNumber {
    override var computedTitle:String {
        return number ?? ""
    }
}

extension Website {
    override var computedTitle:String {
        return url ?? ""
    }
}

extension Country {
    override var computedTitle:String {
        return "\(name ?? "")"
    }
}

extension Address {
    override var computedTitle:String {
        return """
        \(street ?? "")
        \(city ?? "")
        \(postalCode ?? ""), \(state ?? "")
        \(country?.computedTitle ?? "")
        """
    }
}

extension Company {
    override var computedTitle:String {
        return name ?? ""
    }
}

extension OnlineProfile {
    override var computedTitle:String {
        return handle ?? ""
    }
}

extension Diet {
    override var computedTitle:String {
        return name ?? ""
    }
}

extension MedicalCondition {
    override var computedTitle:String {
        return name ?? ""
    }
}

extension Person {
    override var computedTitle:String {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
}

extension AuditItem {
    override var computedTitle:String {
        return "Logged \(action ?? "unknown action") on \(date?.description ?? "")"
    }
    
    convenience init(date: Date? = nil,contents: String? = nil, action: String? = nil,
                     appliesTo: [Item]? = nil) {
        self.init()
        self.date = date ?? self.date
        self.contents = contents ?? self.contents
        self.action = action ?? self.action
                
        if let appliesTo = appliesTo{
            let edges = appliesTo.map{ Edge(self.memriID, $0.memriID, self.genericType, $0.genericType) }
            
//            let edgeName = "appliesTo"
//
//            item["~appliesTo"] =  edges
            // TODO
            self.appliesTo.append(objectsIn: edges)
//            for item in appliesTo{
//                item.changelog.append(objectsIn: edges)
//            }
        }
    }
}

extension Label {
    override var computedTitle:String {
        return name
    }
}

extension Photo {
    override var computedTitle:String {
        return name
    }
}

extension Video {
    override var computedTitle:String {
        return name
    }
}

extension Audio {
    override var computedTitle:String {
        return name
    }
}

extension Importer {
    override var computedTitle:String {
        return name
    }
}

extension Indexer {
    override var computedTitle:String {
        return name
    }
}
