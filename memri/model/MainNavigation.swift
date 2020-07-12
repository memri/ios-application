//
//  SwiftUIView.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import RealmSwift
import SwiftUI

extension StringProtocol {
	var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
	var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

public class MainNavigation: ObservableObject {
	var items: Results<NavigationItem>

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

	private var realm: Realm

	required init(_ rlm: Realm) {
		realm = rlm
		items = realm.objects(NavigationItem.self).sorted(byKeyPath: "sequence")
	}

	public func getItems() -> [NavigationItem] {
		let needle = filterText.lowercased()

		return items.filter {
			return needle == "" || $0.type == "item" && ($0.title ?? "").lowercased().contains(needle)
		}
	}
}
