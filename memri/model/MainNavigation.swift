//
// MainNavigation.swift
// Copyright © 2020 memri. All rights reserved.

import RealmSwift
import SwiftUI

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

public class MainNavigation: ObservableObject {
    var filterText: String {
        get {
            Settings.shared.get("device/navigation/filterText") ?? ""
        }
        set(newFilter) {
            Settings.shared.set("device/navigation/filterText", newFilter)

            scheduleUIUpdate?(nil)
        }
    }

    public var scheduleUIUpdate: ((((_ context: MemriContext) -> Bool)?) -> Void)?

    required init() {
        
    }
    
    public func getItems() -> [NavigationItem] {
        let needle = filterText.lowercased()
        let items = DatabaseController.sync {
            $0.objects(NavigationItem.self).sorted(byKeyPath: "sequence")
        }

        return items?.filter {
            return needle == "" || $0.itemType == "item" && ($0.title ?? "").lowercased()
                .contains(needle)
        } ?? []
    }
}
