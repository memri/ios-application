//
//  Array+Segments.swift
//  memri
//
//  Created by Toby Brennan on 22/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

extension Array {
	func segments(ofSize size: Int) -> [Self] {
		stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}
