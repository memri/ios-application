//
//  Other.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
	var genericType: String {
		objectSchema.className
	}
}

extension SyncState {
	override public var description: String {
		"{"
			+ (actionNeeded != nil ? "\n        actionNeeded: \(actionNeeded ?? "")" : "")
			+ (isPartiallyLoaded ? "\n        isPartiallyLoaded: \(isPartiallyLoaded)" : "")
			+ (changedInThisSession ? "\n        changedInThisSession: \(changedInThisSession)" : "")
			+ (updatedFields.count > 0 ? "\n        updatedFields: [\(updatedFields.map { $0 }.joined(separator: ", "))]" : "")
			+ "\n    }"
	}
}

extension Note {
	override var computedTitle: String {
		"\(title ?? "")"
	}
}

extension PhoneNumber {
	override var computedTitle: String {
		phoneNumber ?? ""
	}
}

extension Website {
	override var computedTitle: String {
		url ?? ""
	}
}

extension Country {
	override var computedTitle: String {
		"\(name ?? "")"
	}
}

extension Address {
	override var computedTitle: String {
		//        \(type ?? "")
		"""
		\(street ?? "")
		\(city ?? "")
		\(postalCode == nil ? "" : postalCode! + ",") \(state ?? "")
		\(edge("country")?.item()?.computedTitle ?? "")
		"""
	}
}

extension Company {
	override var computedTitle: String {
		name ?? ""
	}
}

extension OnlineProfile {
	override var computedTitle: String {
		handle ?? ""
	}
}

extension Diet {
	override var computedTitle: String {
		type ?? ""
	}
}

extension MedicalCondition {
	override var computedTitle: String {
		type ?? ""
	}
}

class Person: SchemaPerson {
	override var computedTitle: String {
		"\(firstName ?? "") \(lastName ?? "")"
	}

	/// Age in years
	var age: Int? {
		if let birthDate = birthDate {
			return Int(birthDate.distance(to: Date()) / 365 * 24 * 60 * 60)
		}
		return nil
	}

	required init() {
		super.init()

		functions["age"] = { _ in self.age }
	}
}

extension AuditItem {
	override var computedTitle: String {
		"Logged \(action ?? "unknown action") on \(date?.description ?? "")"
	}

	convenience init(date: Date? = nil, contents: String? = nil, action: String? = nil,
					 appliesTo: [Item]? = nil) throws {
		self.init()
		self.date = date ?? self.date
		self.contents = contents ?? self.contents
		self.action = action ?? self.action

		if let appliesTo = appliesTo {
			for item in appliesTo {
				_ = try link(item, type: "appliesTo")
			}
		}
	}
}

extension Label {
	override var computedTitle: String {
		name ?? ""
	}
}

extension Photo {
	override var computedTitle: String {
		caption ?? ""
	}
}

extension Video {
	override var computedTitle: String {
		caption ?? ""
	}
}

extension Audio {
	override var computedTitle: String {
		caption ?? ""
	}
}

extension Importer {
	override var computedTitle: String {
		name ?? ""
	}
}

extension Indexer {
	override var computedTitle: String {
		name ?? ""
	}

	internal convenience init(name: String? = nil, itemDescription: String? = nil,
							  query: String? = nil, icon: String? = nil,
							  bundleImage: String? = nil, runDestination: String? = nil) {
		self.init()
		self.name = name ?? self.name
		self.itemDescription = itemDescription ?? self.itemDescription
		self.query = query ?? self.query
		self.icon = icon ?? self.icon
		self.bundleImage = bundleImage ?? self.bundleImage
		self.runDestination = runDestination ?? self.runDestination
	}
}

extension IndexerRun {
	internal convenience init(name: String? = nil, query: String? = nil, indexer: Indexer? = nil,
							  progress: Int? = nil) {
		self.init()
		self.name = name ?? self.name
		self.query = query ?? self.query
		self.progress.value = progress ?? self.progress.value

		if let indexer = indexer { set("indexer", indexer) }
	}
}
