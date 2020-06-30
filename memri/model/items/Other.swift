//
//  Other.swift
//  memri
//
//  Created by Ruben Daniels on 6/25/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Note {
	override var computedTitle: String {
		"\(title ?? "")"
	}
}

extension PhoneNumber {
	override var computedTitle: String {
		number ?? ""
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
		"""
		\(street ?? "")
		\(city ?? "")
		\(postalCode ?? ""), \(state ?? "")
		\(country?.computedTitle ?? "")
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
		name ?? ""
	}
}

extension MedicalCondition {
	override var computedTitle: String {
		name ?? ""
	}
}

class Person: SchemaPerson {
	override var computedTitle: String {
		"\(firstName ?? "") \(lastName ?? "")"
	}

	required init() {
		super.init()

		functions["age"] = { _ in
			Date().distance(to: self.birthDate ?? Date())
		}
	}

	public required init(from decoder: Decoder) throws {
		try super.init(from: decoder)
	}
}

extension AuditItem {
	override var computedTitle: String {
		"Logged \(action ?? "unknown action") on \(date?.description ?? "")"
	}

	convenience init(date: Date? = nil, contents: String? = nil, action: String? = nil,
					 appliesTo: [Item]? = nil) {
		self.init()
		self.date = date ?? self.date
		self.contents = contents ?? self.contents
		self.action = action ?? self.action

		if let appliesTo = appliesTo {
			let edges = appliesTo.map { Relationship(self.memriID, $0.memriID, self.genericType, $0.genericType) }

			//            let edgeName = "appliesTo"
//
			//            item["~appliesTo"] =  edges
			// TODO:
			self.appliesTo.append(objectsIn: edges)
			//            for item in appliesTo{
			//                item.changelog.append(objectsIn: edges)
			//            }
		}
	}
}

extension Label {
	override var computedTitle: String {
		name
	}
}

extension Photo {
	override var computedTitle: String {
		name
	}
}

extension Video {
	override var computedTitle: String {
		name
	}
}

extension Audio {
	override var computedTitle: String {
		name
	}
}

extension Importer {
	override var computedTitle: String {
		name
	}
}

extension Indexer {
	override var computedTitle: String {
		name
	}
}
