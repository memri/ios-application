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

	var press: Action? {
        get { cascadeProperty("press") }
        set (value) { setState("press", value) }
    }

	var chartTitle: String? {
        get { cascadeProperty("chartTitle") }
        set (value) { setState("chartTitle", value) }
    }
	var chartSubtitle: String? {
        get { cascadeProperty("chartSubtitle") }
        set (value) { setState("chartSubtitle", value) }
    }

	var xAxisExpression: Expression? {
        get { cascadeProperty("xAxis", type: Expression.self) }
        set (value) { setState("xAxis", value) }
    }
	var yAxisExpression: Expression? {
        get { cascadeProperty("yAxis", type: Expression.self) }
        set (value) { setState("yAxis", value) }
    }
	var labelExpression: Expression? {
        get { cascadeProperty("label", type: Expression.self) }
        set (value) { setState("label", value) }
    }
    
    var lineWidth: CGFloat {
        get { cascadePropertyAsCGFloat("lineWidth") ?? 0 }
        set (value) { setState("lineWidth", value) }
    }

	var yAxisStartAtZero: Bool {
        get { cascadeProperty("yAxisStartAtZero") ?? false }
        set (value) { setState("yAxisStartAtZero", value) }
    }
	var hideGridLines: Bool {
        get { cascadeProperty("hideGridlines") ?? false }
        set (value) { setState("hideGridlines", value) }
    }
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
		(context.currentView?.renderConfig as? CascadingChartConfig) ?? CascadingChartConfig()
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
							  forItem item: Item) -> T? {
		let args = ViewArguments(context.currentView?.viewArguments, item)

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
			guard
                let labelExpression = renderConfig.labelExpression,
                let yAxisExpression = renderConfig.yAxisExpression
            else { return missingDataView.eraseToAnyView() }
			
            let data = ChartHelper.generateLabelledYChartSetFromItems(
                dataItems,
                labelExpression: { self.resolveExpression(labelExpression, forItem: $0) },
                yAxis: { self.resolveExpression(yAxisExpression, forItem: $0) }
            )

			return VStack(spacing: 0) {
				chartTitleView
				BarChartSwiftUIView(
                    model: BarChartModel(
                        sets: [data],
                        hideGridLines:
                        renderConfig.hideGridLines,
                        forceMinYOfZero: renderConfig.yAxisStartAtZero
                    ),
                    onPress: { self.onPress(index: $0) }
                )
			}
			.padding(10)
			.eraseToAnyView()
		case .line:
			guard
                let xAxisExpression = renderConfig.xAxisExpression,
                let yAxisExpression = renderConfig.yAxisExpression
            else { return missingDataView.eraseToAnyView() }
            
			let data = ChartHelper.generateXYChartSetFromItems(
                dataItems,
                xAxis: { self.resolveExpression(xAxisExpression, forItem: $0) },
                yAxis: { self.resolveExpression(yAxisExpression, forItem: $0) },
                labelExpression: {
                    self.resolveExpression(self.renderConfig.labelExpression, forItem: $0)
                }
            )
			return VStack(spacing: 0) {
				chartTitleView
				LineChartSwiftUIView(
                    model: LineChartModel(
                        sets: [data],
                        lineWidth: renderConfig.lineWidth,
                        hideGridLines: renderConfig.hideGridLines,
                        forceMinYOfZero: renderConfig.yAxisStartAtZero
                    ),
                    onPress: { self.onPress(index: $0) }
                )
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
