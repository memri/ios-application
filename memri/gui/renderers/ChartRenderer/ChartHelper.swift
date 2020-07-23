//
// ChartHelper.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

struct ChartHelper {
    static func generateXYChartSetFromItems(
        _ items: [Item],
        xAxis: (Item) -> Double?,
        yAxis: (Item) -> Double?,
        labelExpression: ((Item) -> String?)?
    ) -> ChartSetXY {
        let points = items.compactMap { (item) -> ChartPointXY? in
            guard
                let x: Double = xAxis(item),
                let y: Double = yAxis(item),
                !x.isNaN,
                !y.isNaN
            else { return nil }
            let label: String? = labelExpression.flatMap { $0(item) }
            return ChartPointXY(x: x, y: y, label: label, itemID: item.getString("uid"))
        }
        return ChartSetXY(points: points)
    }

    static func generateLabelledYChartSetFromItems(
        _ items: [Item],
        labelExpression: (Item) -> String?,
        yAxis: (Item) -> Double?
    ) -> ChartSetLabelledY {
        let points = items.compactMap { (item) -> ChartPointLabelledY? in
            guard
                let label: String = labelExpression(item),
                let y: Double = yAxis(item),
                !y.isNaN
            else { return nil }
            return ChartPointLabelledY(label: label, y: y, itemID: item.getString("uid"))
        }
        return ChartSetLabelledY(points: points)
    }
}
