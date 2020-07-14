//
//  ChartModel.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Foundation

struct ChartSetLabelledY {
	var points: [ChartPointLabelledY]
}

struct ChartSetXY {
	var points: [ChartPointXY]
}

struct ChartPointLabelledY {
	var label: String
	var y: Double
	var itemID: String
}

struct ChartPointXY {
	var x: Double
	var y: Double
	var label: String?
	var itemID: String
}

struct ChartEntryInfo {
	var dataIndex: Int // Doesn't always equal index on chart (eg. line chart sorts by x)
	var label: String?
}
