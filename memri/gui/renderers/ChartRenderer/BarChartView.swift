//
// BarChartView.swift
// Copyright © 2020 memri. All rights reserved.

import Charts
import Foundation
import SwiftUI

struct BarChartSwiftUIView: UIViewRepresentable {
    var model: BarChartModel
    var onPress: ((Int) -> Void)?

    func makeUIView(context: Context) -> BarChartView {
        let chartView: BarChartView = BarChartView()
        chartView.delegate = context.coordinator
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.valueFormatter = BarChartXAxisFormatter()
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.doubleTapToZoomEnabled = false

        return chartView
    }

    func updateUIView(_ chartView: BarChartView, context _: Context) {
        chartView.xAxis.labelFont = model.barLabelFont
        chartView.leftAxis.drawGridLinesEnabled = !model.hideGridLines
        if model.forceMinYOfZero { chartView.leftAxis.axisMinimum = 0 }
        
        
        chartView.data = model.generateData()

        let labels = model.getLabels()
        chartView.xAxis.labelCount = labels.count
        (chartView.xAxis.valueFormatter as? BarChartXAxisFormatter)?.values = labels

        chartView.notifyDataSetChanged()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Implementing ChartViewDelegate

    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: BarChartSwiftUIView

        init(_ parent: BarChartSwiftUIView) {
            self.parent = parent
        }

        // Fire when double-tapped
        func chartValueDoubleTapped(
            _: ChartViewBase,
            entry: ChartDataEntry,
            dataset _: Int,
            index _: Int
        ) {
            // Pressed twice
            guard let info = entry.data as? ChartEntryInfo else { return }
            parent.onPress?(info.dataIndex) // Using this index in case we have sorted the items
        }
    }
}

class BarChartXAxisFormatter: IAxisValueFormatter {
    var values: [String] = []
    var defaultLabel: String = "-"
    func stringForValue(_ value: Double, axis _: AxisBase?) -> String {
        let i = Int(value)
        return values[safe: i] ?? defaultLabel
    }
}
