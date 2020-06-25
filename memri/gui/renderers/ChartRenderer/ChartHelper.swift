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
                item.hasProperty(xAxisKey),
                item.hasProperty(yAxisKey),
                let x: Double = item.get(xAxisKey),
                let y: Double = item.get(yAxisKey)
            else { return nil }
            let label: String? = labelKey.flatMap { item.hasProperty($0) ? item.get($0) : nil }
            return ChartPointXY(x: x, y: y, label: label, itemID: item.memriID)
        }
        return ChartSetXY(points: points)
    }

    static func generateLabelledYChartSetFromItems(_ items: [Item], labelKey: String, yAxisKey: String) -> ChartSetLabelledY {
        let points = items.compactMap { (item) -> ChartPointLabelledY? in
            guard
                item.hasProperty(labelKey),
                item.hasProperty(yAxisKey),
                let label: String = item.get(labelKey),
                let y: Double = item.get(yAxisKey)
            else { return nil }
            return ChartPointLabelledY(label: label, y: y, itemID: item.memriID)
        }
        return ChartSetLabelledY(points: points)
    }
}
