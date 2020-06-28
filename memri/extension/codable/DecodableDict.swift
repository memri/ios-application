//
//  DecodableDict.swift
//  memri
//
//  Created by Koen van der Veen on 13/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Decodable {
	init(from: Any) throws {
		let data = try JSONSerialization.data(withJSONObject: from, options: .prettyPrinted)
		let decoder = JSONDecoder()
		self = try decoder.decode(Self.self, from: data)
	}
}
