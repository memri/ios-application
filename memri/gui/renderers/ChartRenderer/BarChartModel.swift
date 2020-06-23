//
//  LineChartRendererModel.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Charts
import Foundation
import SwiftUI

struct BarChartModel {
    var sets: [ChartSetLabelledY]
    var forceMinYOfZero: Bool = true

    func generateData() -> BarChartData {
        let dataSets: [BarChartDataSet] = sets.map { set in
            let dataSet = BarChartDataSet(entries: set.points.indexed().map { indexedPoint in
                BarChartDataEntry(x: Double(indexedPoint.offset), y: indexedPoint.y, data: ChartEntryInfo(dataIndex: indexedPoint.index))
      })
            return dataSet
        }
        return BarChartData(dataSets: dataSets)
    }

    func getLabels() -> [String] {
        sets.first?.points.map { $0.label } ?? []
    }
}
