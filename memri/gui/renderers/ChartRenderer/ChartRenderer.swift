//
// ChartRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import SwiftUI

class ChartRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "chart", icon: "chart.bar", makeController: ChartRendererController.init, makeConfig: ChartRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? ChartRendererConfig) ?? ChartRendererConfig()
    }
    
    let context: MemriContext
    let config: ChartRendererConfig
    
    func makeView() -> AnyView {
        ChartRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        ChartRendererConfig(head, tail, host)
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    var chartTitle: String? {
        config.chartTitle
    }
    var chartSubtitle: String? {
        config.chartSubtitle
    }

    var items: [Item] {
        context.items
    }
    
    
    func makeBarChartModel() -> BarChartModel? {
        guard
            let labelExpression = config.labelExpression,
            let yAxisExpression = config.yAxisExpression
            else { return nil }
        
        let data = ChartHelper.generateLabelledYChartSetFromItems(
            items,
            labelExpression: { self.resolveExpression(labelExpression, forItem: $0) },
            yAxis: { self.resolveExpression(yAxisExpression, forItem: $0) }
        )
        
        return BarChartModel(
            sets: [data],
            hideGridLines: config.hideGridLines,
            forceMinYOfZero: config.yAxisStartAtZero,
            primaryColor: config.primaryColor,
            barLabelFont: config.barLabelFont.uiFont,
            showValueLabels: config.showValueLabels,
            valueLabelFont: config.valueLabelFont.uiFont
        )
    }
    
    func makeLineChartModel() -> LineChartModel? {
        guard
            let xAxisExpression = config.xAxisExpression,
            let yAxisExpression = config.yAxisExpression
            else { return nil }
        
        let data = ChartHelper.generateXYChartSetFromItems(
            items,
            xAxis: { self.resolveExpression(xAxisExpression, forItem: $0) },
            yAxis: { self.resolveExpression(yAxisExpression, forItem: $0) },
            labelExpression: {
                self.resolveExpression(self.config.labelExpression, forItem: $0)
        }
        )
        
        return LineChartModel(
            sets: [data],
            lineWidth: config.lineWidth,
            hideGridLines: config.hideGridLines,
            forceMinYOfZero: config.yAxisStartAtZero,
            primaryColor: config.primaryColor,
            showValueLabels: config.showValueLabels,
            valueLabelFont: config.valueLabelFont.uiFont
        )
    }
    
    
    func onPress(index: Int) {
        if let press = config.press {
            context.executeAction(press, with: context.items[safe: index])
        }
    }
}

class ChartRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
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
    
    var barLabelFont: CVUFont {
        get { cascadeProperty("barLabelFont") ?? CVUFont(size: 13) }
        set(value) { setState("barLabelFont", value) }
    }
	
	var showValueLabels: Bool {
		get { cascadeProperty("showValueLabels") ?? true }
		set(value) { setState("showValueLabels", value) }
	}
	
    var valueLabelFont: CVUFont {
        get { cascadeProperty("valueLabelFont") ?? CVUFont(size: 14) }
        set(value) { setState("valueLabelFont", value) }
    }
    
    let showContextualBarInEditMode: Bool = false
}

enum ChartType: String, CaseIterable {
    case line
    case bar
}

struct ChartRendererView: View {
    @ObservedObject var controller: ChartRendererController


    var missingDataView: some View {
        Text("You need to define x/y axes in CVU")
    }
    
    var chartTitleView: some View {
        VStack {
            controller.chartTitle.map {
                Text($0)
                    .font(.title)
            }
            controller.chartSubtitle.map {
                Text($0)
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.body)
            }
        }
    }

    var chartView: AnyView {
        switch controller.config.chartType {
        case .bar:
            guard let model = controller.makeBarChartModel() else {
                return missingDataView.eraseToAnyView()
            }

            return VStack(spacing: 0) {
                chartTitleView
                BarChartSwiftUIView(
                    model: model,
                    onPress: { self.controller.onPress(index: $0) }
                )
            }
            .padding(10)
            .eraseToAnyView()
        case .line:
            guard let model = controller.makeLineChartModel() else {
                return missingDataView.eraseToAnyView()
            }
            
            return VStack(spacing: 0) {
                chartTitleView
                LineChartSwiftUIView(
                    model: model,
                    onPress: { self.controller.onPress(index: $0) }
                )
            }
            .padding(10)
            .eraseToAnyView()
        }
    }


    var body: some View {
        chartView
			.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(controller.config.backgroundColor?.color ?? Color(.systemBackground))
    }
}

struct ChartRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ChartRendererView(controller: ChartRendererController(context: try! RootContext(name: "").mockBoot(), config: nil))
    }
}
