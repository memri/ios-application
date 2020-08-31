//
// ChartRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import SwiftUI
//
//let registerChartRenderer = {
//    Renderers.register(
//        name: "chart",
//        title: "Chart",
//        order: 500,
//        icon: "chart.bar",
//        view: AnyView(ChartRendererView()),
//        renderConfigType: CascadingChartConfig.self,
//        canDisplayResults: { _ -> Bool in true }
//    )
//}

class CascadingChartConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var type: String? = "chart"
	
    var showSortInConfig: Bool = false
    
    @ArrayBuilder<ConfigPanelModel.ConfigItem>
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        ConfigPanelModel.ConfigItem(displayName: "Chart type", propertyName: "chartType", type: .special(.chartType), isItemSpecific: false)
        ConfigPanelModel.ConfigItem(displayName: "Chart title", propertyName: "chartTitle", type: .string, isItemSpecific: false)
        ConfigPanelModel.ConfigItem(displayName: "Chart subtitle", propertyName: "chartSubtitle", type: .string, isItemSpecific: false)
        if chartType == .line {
            ConfigPanelModel.ConfigItem(displayName: "X-axis", propertyName: "xAxis", type: .number, isItemSpecific: true)
        }
        ConfigPanelModel.ConfigItem(displayName: "Y-axis", propertyName: "yAxis", type: .number, isItemSpecific: true)
        ConfigPanelModel.ConfigItem(displayName: "Label", propertyName: "label", type: .string, isItemSpecific: true)
        ConfigPanelModel.ConfigItem(displayName: "Hide gridlines", propertyName: "hideGridlines", type: .bool, isItemSpecific: false)
        if chartType == .line {
            ConfigPanelModel.ConfigItem(displayName: "Line width", propertyName: "lineWidth", type: .number, isItemSpecific: false)
        }
    }

    var press: Action? {
        get { cascadeProperty("press") }
        set(value) { setState("press", value) }
    }
    
    var chartType: ChartType {
        get { cascadeProperty("chartType", type: String.self).flatMap(ChartType.init) ?? .bar }
        set(value) { setState("chartType", value.rawValue) }
    }

    var chartTitle: String? {
        get { cascadeProperty("chartTitle") }
        set(value) { setState("chartTitle", value) }
    }

    var chartSubtitle: String? {
        get { cascadeProperty("chartSubtitle") }
        set(value) { setState("chartSubtitle", value) }
    }

    var xAxisExpression: Expression? {
        get { cascadeProperty("xAxis", type: Expression.self) }
        set(value) { setState("xAxis", value) }
    }

    var yAxisExpression: Expression? {
        get { cascadeProperty("yAxis", type: Expression.self) }
        set(value) { setState("yAxis", value) }
    }

    var labelExpression: Expression? {
        get { cascadeProperty("label", type: Expression.self) }
        set(value) { setState("label", value) }
    }

    var lineWidth: CGFloat {
        get { cascadePropertyAsCGFloat("lineWidth") ?? 0 }
        set(value) { setState("lineWidth", value) }
    }

    var yAxisStartAtZero: Bool {
        get { cascadeProperty("yAxisStartAtZero") ?? false }
        set(value) { setState("yAxisStartAtZero", value) }
    }

    var hideGridLines: Bool {
        get { cascadeProperty("hideGridlines") ?? false }
        set(value) { setState("hideGridlines", value) }
    }
    
    var barLabelFont: FontDefinition {
        get { cascadeProperty("barLabelFont") ?? FontDefinition(size: 13) }
        set(value) { setState("barLabelFont", value) }
    }
	
	var showValueLabels: Bool {
		get { cascadeProperty("showValueLabels") ?? true }
		set(value) { setState("showValueLabels", value) }
	}
	
    var valueLabelFont: FontDefinition {
        get { cascadeProperty("valueLabelFont") ?? FontDefinition(size: 14) }
        set(value) { setState("valueLabelFont", value) }
    }
    
    let showContextualBarInEditMode: Bool = false
}

enum ChartType: String, CaseIterable {
    case line
    case bar
}

struct ChartRendererView: View {
    @EnvironmentObject var context: MemriContext

    let name = "chart"

    var renderConfig: CascadingChartConfig {
        (context.currentView?.renderConfig as? CascadingChartConfig) ?? CascadingChartConfig()
    }

    var missingDataView: some View {
        Text("You need to define x/y axes in CVU")
    }

    var chartTitle: String? {
        if let title = renderConfig.chartTitle { return title }
        return nil
    }

    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem item: Item
    ) -> T? {
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
        switch renderConfig.chartType {
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
                        hideGridLines: renderConfig.hideGridLines,
                        forceMinYOfZero: renderConfig.yAxisStartAtZero,
						primaryColor: renderConfig.primaryColor,
                        barLabelFont: renderConfig.barLabelFont.uiFont,
						showValueLabels: renderConfig.showValueLabels,
						valueLabelFont: renderConfig.valueLabelFont.uiFont
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
						forceMinYOfZero: renderConfig.yAxisStartAtZero,
						primaryColor: renderConfig.primaryColor,
						showValueLabels: renderConfig.showValueLabels,
						valueLabelFont: renderConfig.valueLabelFont.uiFont
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
			.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
    }
}

struct ChartRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ChartRendererView()
            .environmentObject(try! RootContext(name: "").mockBoot())
    }
}
