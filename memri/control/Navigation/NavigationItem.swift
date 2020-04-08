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

public class MainNavigation {
    /**
     *
     */
    var items: [NavigationItem] = []
    
    private var realm:Realm
    
    required init(_ rlm:Realm) {
        realm = rlm
    }
    
    /**
     *
     */
    public func load(_ callback: () -> Void) {
        // Fetch navigation from realm and sort based on the order property
        let navItems = realm.objects(NavigationItem.self).sorted(byKeyPath: "order")
        
        // Add items to the items array
        for item in navItems {
            items.append(item)
        }
        
        callback()
    }
    /**
     *
     */
    public func install() {
        // Load default navigation items from pacakge
        let jsonData = try! jsonDataFromFile("default_navigation")
        items = try! JSONDecoder().decode([NavigationItem].self, from: jsonData)
        
        try! realm.write {
        
            // Store default items in realm
            for item in items {
                realm.add(item)
            }
        }
    }
    
}

public class NavigationItem: Object, ObservableObject, Codable {
    /**
     * Used as the caption in the navigation
     */
    @objc dynamic var title: String = ""
    /**
     * Name of the view it opens
     */
    @objc dynamic var view: String? = nil
    /**
     * Defines the position in the navigation
     */
    @objc dynamic var order: Int = 0
    /**
     *  0 = Item
     *  1 = Heading
     *  2 = Line
     */
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
