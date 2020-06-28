//
//  MapRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

let registerChartRenderer = {
	Renderers.register(
		name: "chart",
		title: "Bar",
		order: 500,
		icon: "chart.bar",
		view: AnyView(ChartRendererView(type: .bar)),
		renderConfigType: CascadingChartConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)

	Renderers.register(
		name: "chart.line",
		title: "Line",
		order: 510,
		icon: "chart.line",
		view: AnyView(ChartRendererView(type: .line)),
		renderConfigType: CascadingChartConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

class CascadingChartConfig: CascadingRenderConfig {
	var type: String? = "chart"

	var press: Action? { cascadeProperty("press") }

	var chartTitle: String? { cascadeProperty("chartTitle") }
	var xAxisKey: String? { cascadeProperty("xAxisKey") }
	var labelKey: String? { cascadeProperty("labelKey") }
	var yAxisKey: String? { cascadeProperty("yAxisKey") }
	var yAxisMustStartAtZero: Bool { cascadeProperty("yAxisMustStartAtZero") ?? false }
	//    var chartType: ChartType { cascadeProperty("chartType").flatMap(ChartType.init(rawValue:)) ?? .bar }
}

enum ChartType: String {
	case line
	case bar
}

struct ChartRendererView: View {
	@EnvironmentObject var context: MemriContext

	let name = "chart"
	let type: ChartType

	var renderConfig: CascadingChartConfig {
		(context.cascadingView.renderConfig as? CascadingChartConfig) ?? CascadingChartConfig([], ViewArguments())
	}

	var missingDataView: some View {
		Text("You need to define x/y axes in CVU")
	}

	var chartTitle: String? {
		if let title = renderConfig.chartTitle { return title }

		// Autogenerate title
		switch type {
		case .bar:
			return renderConfig.yAxisKey?.camelCaseToTitleCase()
		case .line:
			return "\(renderConfig.yAxisKey?.camelCaseToTitleCase() ?? "-") vs \(renderConfig.xAxisKey?.camelCaseToTitleCase() ?? "-")"
		}
	}

	@ViewBuilder
	var chartTitleView: some View {
		chartTitle.map {
			Text($0.camelCaseToTitleCase())
				.font(.title)
		}
	}

	var chartView: AnyView {
		let dataItems = context.items
		switch type {
		case .bar:
			guard let labelKey = renderConfig.labelKey, let yAxisKey = renderConfig.yAxisKey else { return missingDataView.eraseToAnyView() }
			let data = ChartHelper.generateLabelledYChartSetFromDataItems(dataItems, labelKey: labelKey, yAxisKey: yAxisKey)

			return VStack(spacing: 0) {
				chartTitleView
				BarChartSwiftUIView(model: BarChartModel(sets: [data], forceMinYOfZero: renderConfig.yAxisMustStartAtZero),
									onPress: { self.onPress(index: $0) })
			}
			.padding(10)
			.eraseToAnyView()
		case .line:
			guard let xAxisKey = renderConfig.xAxisKey, let yAxisKey = renderConfig.yAxisKey else { return missingDataView.eraseToAnyView() }
			let data = ChartHelper.generateXYChartSetFromDataItems(dataItems, xAxisKey: xAxisKey, yAxisKey: yAxisKey, labelKey: renderConfig.labelKey)
			return VStack(spacing: 0) {
				chartTitleView
				LineChartSwiftUIView(model: LineChartModel(sets: [data], forceMinYOfZero: renderConfig.yAxisMustStartAtZero),
									 onPress: { self.onPress(index: $0) })
			}
			.padding(10)
			.eraseToAnyView()
		}
	}

	func onPress(index: Int) {
		if let press = renderConfig.press {
			context.executeAction(press, with: context.items[safe: index])
		}
	}

	var body: some View {
		chartView
	}
}

struct ChartRendererView_Previews: PreviewProvider {
	static var previews: some View {
		ChartRendererView(type: .bar).environmentObject(RootContext(name: "", key: "").mockBoot())
	}
}
