//
// LineChartModel.swift
// Copyright © 2020 memri. All rights reserved.

import Charts
import Foundation
import SwiftUI

struct LineChartModel {
    var sets: [ChartSetXY]
    var lineWidth: CGFloat = 0
    var hideGridLines: Bool = false
    var forceMinYOfZero: Bool = true
    var primaryColor = CVUColor.system(.systemBlue)
    var showValueLabels: Bool = true
    var valueLabelFont = UIFont.systemFont(ofSize: 14)

    func generateData() -> LineChartData {
        let dataSets: [LineChartDataSet] = sets.map { set in
            let dataSet = LineChartDataSet(entries: set.points.indexed()
                .sorted(by: { $0.x <= $1.x }).map { indexedPoint in
                    let originalDataIndex = indexedPoint
                        .index // Important that we indexed before sorting the data above
                    return ChartDataEntry(
                        x: indexedPoint.x,
                        y: indexedPoint.y,
                        data: ChartEntryInfo(
                            dataIndex: originalDataIndex,
                            label: indexedPoint.label
                        )
                    )
                })
            dataSet.drawValuesEnabled = showValueLabels
            dataSet.lineWidth = lineWidth
            dataSet.valueFormatter = ChartLabelFormatter()
            dataSet.valueFont = valueLabelFont
            dataSet.setColor(primaryColor.uiColor)
            return dataSet
        }
        return LineChartData(dataSets: dataSets)
    }
}

class ChartLabelFormatter: IValueFormatter {
    func stringForValue(
        _ value: Double,
        entry: ChartDataEntry,
        dataSetIndex _: Int,
        viewPortHandler _: ViewPortHandler?
    ) -> String {
        if let info = (entry.data as? ChartEntryInfo), let label = info.label {
            return label
        }
        else {
            return NumberFormatter().string(from: NSNumber(value: value)) ?? ""
        }
    }
}
