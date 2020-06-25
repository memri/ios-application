//
//  LineChartSwiftUIView.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Charts
import Foundation
import SwiftUI

struct LineChartSwiftUIView: UIViewRepresentable {
    var model: LineChartModel
    var onPress: ((Int) -> Void)?

    func makeUIView(context: Context) -> LineChartView {
        let chartView: LineChartView = LineChartView()
        chartView.delegate = context.coordinator
        chartView.legend.enabled = false
        chartView.xAxis.drawGridLinesEnabled = model.showGridLines
        chartView.xAxis.labelPosition = .bottom
        chartView.leftAxis.drawGridLinesEnabled = model.showGridLines
        chartView.rightAxis.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.xAxis.spaceMin = 10
        chartView.xAxis.spaceMax = 10
        chartView.maxHighlightDistance = 50
        
        if model.forceMinYOfZero { chartView.leftAxis.axisMinimum = 0 }

        return chartView
    }

    func updateUIView(_ chartView: LineChartView, context _: Context) {
        chartView.data = model.generateData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Implementing ChartViewDelegate

    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: LineChartSwiftUIView
        
        

        init(_ parent: LineChartSwiftUIView) {
            self.parent = parent
        }
        
        //Fire when selected and then tapped
//        var selectedIndex: Int?
//        func chartValueTapped(_ chartView: ChartViewBase, dataset: Int, index: Int) {
//            if selectedIndex == index {
//                //Pressed twice
//                parent.onPress?(index)
//            } else {
//                selectedIndex = index
//            }
//        }
//
//        func chartNothingTapped(_ chartView: ChartViewBase) {
//            selectedIndex = nil
//        }
        
        //Fire when double-tapped
        func chartValueDoubleTapped(_ chartView: ChartViewBase, entry: ChartDataEntry, dataset: Int, index: Int) {
            //Pressed twice
            guard let info = entry.data as? ChartEntryInfo else { return }
            parent.onPress?(info.dataIndex) //Using this index in case we have sorted the items
        }
    }
}
