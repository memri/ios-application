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
	var chartSubtitle: String? { cascadeProperty("chartSubtitle") }

	var xAxisExpression: Expression? { cascadeProperty("xAxis", type: Expression.self) }
	var yAxisExpression: Expression? { cascadeProperty("yAxis", type: Expression.self) }
	var labelExpression: Expression? { cascadeProperty("label", type: Expression.self) }
	
	var lineWidth: CGFloat { cascadePropertyAsCGFloat("lineWidth") ?? 0 }

	var yAxisStartAtZero: Bool { cascadeProperty("yAxisStartAtZero") ?? false }
	var hideGridLines: Bool { cascadeProperty("hideGridlines") ?? false }
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
		(context.cascadingView?.renderConfig as? CascadingChartConfig) ?? CascadingChartConfig([])
	}

	var missingDataView: some View {
		Text("You need to define x/y axes in CVU")
	}

	var chartTitle: String? {
		if let title = renderConfig.chartTitle { return title }

		// Autogenerate title - TODO: Implement this for expressions
//		switch type {
//		case .bar:
//			return renderConfig.yAxisKey?.camelCaseToTitleCase()
//		case .line:
//			return "\(renderConfig.yAxisKey?.camelCaseToTitleCase() ?? "-") vs \(renderConfig.xAxisKey?.camelCaseToTitleCase() ?? "-")"
//		}
		return nil
	}

	func resolveExpression<T>(_ expression: Expression?,
							  toType _: T.Type = T.self,
							  forItem dataItem: Item) -> T? {
		let args = try? ViewArguments
			.clone(context.cascadingView?.viewArguments, [".": dataItem], managed: false)

		return try? expression?.execForReturnType(T.self, args: args)
	}

	var chartTitleView: some View {
		VStack {
			chartTitle.map {
				Text($0)
					.font(.title)
			}
			renderConfig.chartSubtitle.map {
				Text($0)
					.foregroundColor(Color(.secondaryLabel))
					.font(.body)
			}
		}
	}

	var chartView: AnyView {
		let dataItems = context.items
		switch type {
		case .bar:
			guard let labelExpression = renderConfig.labelExpression, let yAxisExpression = renderConfig.yAxisExpression else { return missingDataView.eraseToAnyView() }
			let data = ChartHelper.generateLabelledYChartSetFromItems(dataItems,
																	  labelExpression: {
																	  	self.resolveExpression(labelExpression, forItem: $0)
																	  },
																	  yAxis: {
																	  	self.resolveExpression(yAxisExpression, forItem: $0)
                                                                          })

			return VStack(spacing: 0) {
				chartTitleView
				BarChartSwiftUIView(model: BarChartModel(sets: [data], hideGridLines: renderConfig.hideGridLines, forceMinYOfZero: renderConfig.yAxisStartAtZero),
									onPress: { self.onPress(index: $0) })
			}
			.padding(10)
			.eraseToAnyView()
		case .line:
			guard let xAxisExpression = renderConfig.xAxisExpression, let yAxisExpression = renderConfig.yAxisExpression else { return missingDataView.eraseToAnyView() }
			let data = ChartHelper.generateXYChartSetFromItems(dataItems,
															   xAxis: {
															   	self.resolveExpression(xAxisExpression, forItem: $0)
															   },
															   yAxis: {
															   	self.resolveExpression(yAxisExpression, forItem: $0)
															   },
															   labelExpression: {
															   	self.resolveExpression(self.renderConfig.labelExpression, forItem: $0)
                                                                   })
			return VStack(spacing: 0) {
				chartTitleView
				LineChartSwiftUIView(model: LineChartModel(sets: [data], lineWidth: renderConfig.lineWidth, hideGridLines: renderConfig.hideGridLines, forceMinYOfZero: renderConfig.yAxisStartAtZero),
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
		ChartRendererView(type: .bar).environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
