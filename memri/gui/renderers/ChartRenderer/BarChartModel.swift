//
// BarChartModel.swift
// Copyright © 2020 memri. All rights reserved.

import Charts
import Foundation
import SwiftUI

struct BarChartModel {
    var sets: [ChartSetLabelledY]
    var hideGridLines: Bool = true
    var forceMinYOfZero: Bool = true
	var primaryColor: ColorDefinition = ColorDefinition.system(.systemBlue)
	var showValueLabels: Bool = true
	var valueLabelFont: UIFont = UIFont.systemFont(ofSize: 14)

    func generateData() -> BarChartData {
        let dataSets: [BarChartDataSet] = sets.map { set in
            let dataSet = BarChartDataSet(entries: set.points.indexed().map { indexedPoint in
                BarChartDataEntry(
                    x: Double(indexedPoint.offset),
                    y: indexedPoint.y,
                    data: ChartEntryInfo(dataIndex: indexedPoint.index)
                )
      })
			dataSet.drawValuesEnabled = showValueLabels
			dataSet.valueFont = valueLabelFont
			dataSet.setColor(primaryColor.uiColor)
            return dataSet
        }
        return BarChartData(dataSets: dataSets)
    }

    func getLabels() -> [String] {
        sets.first?.points.map { $0.label } ?? []
    }
}
