//
//  ChartHelper.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 5/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

struct ChartHelper {
	static func generateXYChartSetFromItems(_ items: [Item], xAxis: (Item) -> Double?, yAxis: (Item) -> Double?, labelKey: ((Item) -> String?)?) -> ChartSetXY {
		let points = items.compactMap { (item) -> ChartPointXY? in
			guard
				let x: Double = xAxis(item),
				let y: Double = yAxis(item),
				!x.isNaN,
				!y.isNaN
			else { return nil }
			let label: String? = labelKey.flatMap { $0(item) }
			return ChartPointXY(x: x, y: y, label: label, itemID: item.getString("uid"))
		}
		return ChartSetXY(points: points)
	}

	static func generateLabelledYChartSetFromItems(_ items: [Item], labelKey: (Item) -> String?, yAxis: (Item) -> Double?) -> ChartSetLabelledY {
		let points = items.compactMap { (item) -> ChartPointLabelledY? in
			guard
				let label: String = labelKey(item),
				let y: Double = yAxis(item),
				!y.isNaN
			else { return nil }
			return ChartPointLabelledY(label: label, y: y, itemID: item.getString("uid"))
		}
		return ChartSetLabelledY(points: points)
	}
}
