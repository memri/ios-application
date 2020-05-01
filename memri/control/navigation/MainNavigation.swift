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
            
            scheduleUIUpdate!{_ in true}
        }
    }
    
    public var scheduleUIUpdate: ((_ check:(_ main:Main) -> Bool) -> Void)? = nil
    
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
    
 
    public func load(_ callback: () -> Void) {
        // Fetch navigation from realm and sort based on the order property
        let navItems = realm.objects(NavigationItem.self).sorted(byKeyPath: "order")
        
        // Add items to the items array
        for item in navItems {
            items.append(item)
        }
        
        callback()
    }
 
    public func install() {
        // Load default navigation items from pacakge
        let jsonData = try! jsonDataFromFile("default_navigation")
        items = try! MemriJSONDecoder.decode([NavigationItem].self, from: jsonData)
        
        try! realm.write {
        
            // Store default items in realm
            for item in items {
                print(item.title)
                realm.add(item)
            }
        }
    }
}

public class NavigationItem: Object, ObservableObject, Codable {

    /// Used as the caption in the navigation
    @objc dynamic var title: String = ""
    /// Name of the view it opens
    @objc dynamic var view: String? = nil
    /// Defines the position in the navigation
    @objc dynamic var order: Int = 0
    
    ///     0 = Item
    ///     1 = Heading
    ///     2 = Line
    @objc dynamic var type: String = "item"
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.view = try decoder.decodeIfPresent("view") ?? self.view
            self.order = try decoder.decodeIfPresent("order") ?? self.order
            self.type = try decoder.decodeIfPresent("type") ?? self.type
        }
    }
}
