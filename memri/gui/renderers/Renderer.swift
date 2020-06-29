//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import RealmSwift

public class RenderConfig: Object, Codable {
	@objc dynamic var name: String = ""
	@objc dynamic var icon: String = ""
	@objc dynamic var category: String = ""

	let items = List<ActionDescription>()
	let options1 = List<ActionDescription>()
	let options2 = List<ActionDescription>()

	public required convenience init(from decoder: Decoder) throws {
		self.init()

		jsonErrorHandling(decoder) {
			self.name = try decoder.decodeIfPresent("name") ?? self.name
			self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
			self.category = try decoder.decodeIfPresent("category") ?? self.category

			decodeIntoList(decoder, "items", self.items)
			decodeIntoList(decoder, "options1", self.options1)
			decodeIntoList(decoder, "options2", self.options2)
		}
	}
}
