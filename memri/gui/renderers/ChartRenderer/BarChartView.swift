//
//  LineChartSwiftUIView.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

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
        chartView.xAxis.labelFont = .systemFont(ofSize: 12)
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.valueFormatter = BarChartXAxisFormatter()
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.doubleTapToZoomEnabled = false
        if model.forceMinYOfZero { chartView.leftAxis.axisMinimum = 0 }

        return chartView
    }

    func updateUIView(_ chartView: BarChartView, context _: Context) {
        chartView.data = model.generateData()

        let labels = model.getLabels()
        chartView.xAxis.labelCount = labels.count
        (chartView.xAxis.valueFormatter as? BarChartXAxisFormatter)?.values = labels
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
        
        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            guard let info = entry.data as? ChartEntryInfo else { return }
            parent.onPress?(info.dataIndex)
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
