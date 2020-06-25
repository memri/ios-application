//
//  SwiftUIView.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

public class MainNavigation:ObservableObject {
 
    var items: [NavigationItem] = []
 
    var filterText: String {
        get {
            return Settings.get("device/navigation/filterText") ?? ""
        }
        set (newFilter) {
            Settings.set("device/navigation/filterText", newFilter)
            
            scheduleUIUpdate?(nil)
        }
    }
    
    public var scheduleUIUpdate: ((((_ context:MemriContext) -> Bool)?) -> ())? = nil
    
    private var realm:Realm
    
    required init(_ rlm:Realm) {
        realm = rlm
    }
    
 
    public func getItems() -> [NavigationItem] {
        let needle = self.filterText.lowercased()
        
        return self.items.filter {
            return needle == "" || $0.type == "item" && $0.title.lowercased().contains(needle)
        }
    }
    
 
    public func load(_ callback: () throws -> Void) throws {
        // Fetch navigation from realm and sort based on the order property
        let navItems = realm.objects(NavigationItem.self).sorted(byKeyPath: "order")
        
        // Add items to the items array
        for item in navItems {
            items.append(item)
        }
        
        try callback()
    }
 
    public func install() {
        // Load default navigation items from pacakge
        do {
            let jsonData = try jsonDataFromFile("default_navigation")
            items = try MemriJSONDecoder.decode([NavigationItem].self, from: jsonData)
            
            realmWriteIfAvailable(realm) {
                for item in items {
                    print(item.title)
                    realm.add(item)
                }
                
            }
        }
        catch {
            print("Failed to install MainNavigation")
        }
    }
}
