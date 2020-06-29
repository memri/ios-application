//
//  ChartHelper.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 5/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

struct ChartHelper {
	static func generateXYChartSetFromDataItems(_ items: [DataItem], xAxis: (DataItem) -> Double?, yAxis: (DataItem) -> Double?, labelKey: ((DataItem) -> String?)?) -> ChartSetXY {
		let points = items.compactMap { (item) -> ChartPointXY? in
			guard
				let x: Double = xAxis(item),
				let y: Double = yAxis(item)
			else { return nil }
			let label: String? = labelKey.flatMap { $0(item) }
			return ChartPointXY(x: x, y: y, label: label, itemID: item.memriID)
		}
		return ChartSetXY(points: points)
	}

	static func generateLabelledYChartSetFromDataItems(_ items: [DataItem], labelKey: (DataItem) -> String?, yAxis: (DataItem) -> Double?) -> ChartSetLabelledY {
		let points = items.compactMap { (item) -> ChartPointLabelledY? in
			guard
				let label: String = labelKey(item),
				let y: Double = yAxis(item)
			else { return nil }
			return ChartPointLabelledY(label: label, y: y, itemID: item.memriID)
		}
		return ChartSetLabelledY(points: points)
	}
}
