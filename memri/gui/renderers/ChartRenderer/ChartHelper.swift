//
//  ChartHelper.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 5/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

struct ChartHelper {
    static func generateXYChartSetFromItems(_ items: [Item], xAxisKey: String, yAxisKey: String, labelKey: String? = nil) -> ChartSetXY {
        let points = items.compactMap { (item) -> ChartPointXY? in
            guard
                let x: Double = item.get(xAxisKey),
                let y: Double = item.get(yAxisKey)
            else { return nil }
            let label: String? = labelKey.flatMap { item.get($0) }
            return ChartPointXY(x: x, y: y, label: label, itemID: item.memriID)
        }
        return ChartSetXY(points: points)
    }

    static func generateLabelledYChartSetFromItems(_ items: [Item], labelKey: String, yAxisKey: String) -> ChartSetLabelledY {
        let points = items.compactMap { (item) -> ChartPointLabelledY? in
            guard
                let label: String = item.get(labelKey),
                let y: Double = item.get(yAxisKey)
            else { return nil }
            return ChartPointLabelledY(label: label, y: y, itemID: item.memriID)
        }
        return ChartSetLabelledY(points: points)
    }
}
