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

class MainNavigation {
    var items: [NavigationItem]
    
    private var realm:Realm
    
    required init(_ rlm:Realm) {
        realm = rlm
    }
    
    /**
     *
     */
    public func load(_ callback: () -> Void) {
        
    }
    /**
     *
     */
    public func install() {
        // Load default navigation items from pacakge
        let jsonData = try! jsonDataFromFile("default_navigation")
        items =  try! JSONDecoder().decode([NavigationItem].self, from: jsonData)
        
        realm
    }
    
}

class NavigationItem: Object, ObservableObject, Codable {
        
    public var id = UUID()

    /**
     * Used as the caption in the navigation
     */
    public var title: String
    /**
     * Name of the view it opens
     */
    public var view: String?
    /**
     * Defines the position in the navigation
     */
    public var count: Int = 0
    /**
     *  0 = Item
     *  1 = Heading
     *  2 = Line
     */
    public var type: String = "item"
    
    public convenience required init(from decoder: Decoder) throws {
        jsonErrorHandling(decoder) {
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.view = try decoder.decodeIfPresent("view") ?? self.view
            self.count = try decoder.decodeIfPresent("count") ?? self.count
            self.type = try decoder.decodeIfPresent("type") ?? self.type
        }
    }
}
