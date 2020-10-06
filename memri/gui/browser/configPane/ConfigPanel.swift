//
//  ConfigPanel.swift
//  memri
//
//  Created by Toby Brennan on 28/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

struct ConfigPanel: View {
	@EnvironmentObject var context: MemriContext
    @ObservedObject var keyboard = KeyboardResponder.shared
    @State var shouldMoveAboveKeyboard = false
    
    var body: some View {
        let configItems = getConfigItems()
        return NavigationView {
            if configItems.isEmpty {
                noConfigItem
            } else {
                SwiftUI.List {
                    sortItem
                    ForEach(configItems, id: \.propertyName) { configItem in
                        self.getConfigView(configItem)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationBarTitle(Text("Config"), displayMode: .inline)
                .navigationBarHidden(keyboard.keyboardVisible)
            }
        }
        .environment(\.verticalSizeClass, .compact)
        .clipShape(RoundedRectangle(cornerRadius: shouldMoveAboveKeyboard ? 15 : 0))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(shouldMoveAboveKeyboard ? Color(.systemFill) : .clear))
        .modifier(KeyboardModifier(enabled: shouldMoveAboveKeyboard, overrideHeightWhenVisible: 120))
    }
    
    var showSortItem: Bool {
        currentRendererConfig?.showSortInConfig ?? true
    }
    
    @ViewBuilder
    var noConfigItem: some View {
        if showSortItem {
            ConfigPanelSortView()
        } else {
            Text("No configurable settings")
                .navigationBarItems(trailing: EmptyView())
                .padding()
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    var sortItem: some View {
        if showSortItem {
            NavigationLink(destination: ConfigPanelSortView()) {
                Text("Sort order")
            }
        }
    }
    
    func getConfigView(_ configItem: ConfigPanelModel.ConfigItem) -> AnyView {
        if configItem.isItemSpecific {
            return NavigationLink(destination: ConfigPanelSelectionView(configItem: configItem)) {
                Text(configItem.displayName)
            }.eraseToAnyView()
        } else {
            switch configItem.type {
            case .bool:
                return ConfigPanelBoolView(configItem: configItem).eraseToAnyView()
            case .number:
                return ConfigPanelNumberView(configItem: configItem).eraseToAnyView()
            case .special(.chartType):
                return NavigationLink(destination: ConfigPanelEnumSelectionView(configItem: configItem, type: ChartType.self)) {
                    Text(configItem.displayName)
                }.eraseToAnyView()
            case .special(.timeLevel):
                return NavigationLink(destination: ConfigPanelEnumSelectionView(configItem: configItem, type: TimelineModel.DetailLevel.self)) {
                    Text(configItem.displayName)
                }.eraseToAnyView()
            default:
                return NavigationLink(destination: ConfigPanelStringView(configItem: configItem, shouldMoveAboveKeyboard: $shouldMoveAboveKeyboard)) {
                    Text(configItem.displayName)
                }.eraseToAnyView()
            }
        }
    }
}

private extension ConfigPanel {
    var currentRendererConfig: ConfigurableRenderConfig? {
        context.currentView?.renderConfig as? ConfigurableRenderConfig
    }
    
	func getConfigItems() -> [ConfigPanelModel.ConfigItem] {
		return currentRendererConfig?.configItems(context: context) ?? []
	}

}

struct ConfigPanelBoolView: View {
    @EnvironmentObject var context: MemriContext
    var configItem: ConfigPanelModel.ConfigItem
    
    var body: some View {
        Toggle(isOn: self.bindingForBoolExp(configItem: configItem)) {
            Text(configItem.displayName)
        }
    }
    
    func bindingForBoolExp(configItem: ConfigPanelModel.ConfigItem) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak context] in context?.currentView?.renderConfig?.cascadeProperty(configItem.propertyName, type: Bool.self) ?? false },
            set: { [weak context] in
                context?.currentView?.renderConfig?.setState(configItem.propertyName, $0)
                context?.scheduleUIUpdate()
        })
    }
}

struct ConfigPanelNumberView: View {
    @EnvironmentObject var context: MemriContext
    var configItem: ConfigPanelModel.ConfigItem
    
    var body: some View {
        Stepper(configItem.displayName, value: bindingForNumber(configItem: configItem))
    }
    
    func bindingForNumber(configItem: ConfigPanelModel.ConfigItem) -> Binding<Double> {
        Binding<Double>(
            get: { [weak context] in context?.currentView?.renderConfig?.cascadeProperty(configItem.propertyName, type: Double.self) ?? 0 },
            set: { [weak context] in
                context?.currentView?.renderConfig?.setState(configItem.propertyName, $0)
                context?.scheduleUIUpdate()
        })
    }
}

struct ConfigPanelStringView: View {
    @EnvironmentObject var context: MemriContext
    
	var configItem: ConfigPanelModel.ConfigItem
    @Binding var shouldMoveAboveKeyboard: Bool
	
	var body: some View {
		VStack(alignment: .leading) {
            Text("\(configItem.displayName):")
			MemriTextField(value: self.bindingForExp(configItem: configItem),
						   placeholder: configItem.displayName,
                           clearButtonMode: .whileEditing,
                           returnKeyType: UIReturnKeyType.done,
						   showPrevNextButtons: false)
                .onEditingBegan {
                    self.shouldMoveAboveKeyboard = true
            }
            .onEditingEnded {
                self.shouldMoveAboveKeyboard = false
            }
				.padding(5)
				.background(Color(.systemFill).cornerRadius(5))
		}
		.padding()
	}
	
    func bindingForExp(configItem: ConfigPanelModel.ConfigItem) -> Binding<String> {
        Binding<String>(
        get: { [weak context] in context?.currentView?.renderConfig?.cascadeProperty(configItem.propertyName, type: String.self) ?? "" },
        set: { [weak context] in
            context?.currentView?.renderConfig?.setState(configItem.propertyName, $0)
            context?.scheduleUIUpdate()
    })
	}
}


struct ConfigPanelSelectionView: View {
	@EnvironmentObject var context: MemriContext
	
	var configItem: ConfigPanelModel.ConfigItem
	
	
	var body: some View {
		let options = getRelevantFields()
        let currentSelection = self.currentSelection
		
		return SwiftUI.List {
			ForEach(options, id: \.propertyName) { option in
				Button(action: { self.onSelect(option) }) {
					Text(option.displayName)
                        .if(option.propertyName == currentSelection) { $0.bold() }
				}
			}
		}
        .listStyle(PlainListStyle())
		.navigationBarTitle(Text(configItem.displayName), displayMode: .inline)
	}
	
    func onSelect(_ selected: ConfigPanelModel.PossibleExpression) {
        context.currentView?.renderConfig?.setState(configItem.propertyName, Expression(selected.expressionString, startInStringMode: false, lookup: context.views.lookupValueOfVariables, execFunc: context.views.executeFunction))
        context.scheduleUIUpdate()
	}
	
	static let excludedFields = ["uid", "deleted", "externalId", "version", "allEdges"]
	
    var currentSelection: String {
        (context.currentView?.renderConfig?.cascadeProperty(configItem.propertyName, type: Expression.self)?.code ?? "").trimmingCharacters(in: CharacterSet(charactersIn: " .{}()"))
    }
    
	func getRelevantFields() -> [ConfigPanelModel.PossibleExpression] {
		guard let item = context.currentView?.resultSet.items.first else { return [] }
		
		let properties = item.objectSchema.properties
        let computedProperties = item.computedVars
		
        let propertyOptions = properties.compactMap { prop -> ConfigPanelModel.PossibleExpression? in
            if configItem.type.supportedRealmTypes.contains(prop.type), !ConfigPanelSelectionView.excludedFields.contains(prop.name), !prop.name.hasPrefix("_") {
                return ConfigPanelModel.PossibleExpression(propertyName: prop.name)
            }
            else {
                return nil
            }
        }
        
        let computedPropertyOptions = computedProperties.compactMap { prop -> ConfigPanelModel.PossibleExpression? in
            if configItem.type.supportedRealmTypes.contains(prop.type) {
                return ConfigPanelModel.PossibleExpression(propertyName: prop.propertyName, isComputed: true)
            }
            else {
                return nil
            }
        }
        
        return (propertyOptions + computedPropertyOptions).sorted(by: { $0.propertyName < $1.propertyName })
	}
}

struct ComputedPropertyLink {
    var propertyName: String
    var type: PropertyType
}


struct ConfigPanelSortView: View {
    @EnvironmentObject var context: MemriContext

    
    
    var body: some View {
        let options = getSortFields()
        let currentSort = self.context.currentView?.datasource.sortProperty ?? ""
        
        return SwiftUI.List {
            ForEach(options, id: \.propertyName) { option in
                Button(action: { self.onSelect(option) }) {
                    HStack {
                        Text(option.displayName)
                        .if(currentSort == option.propertyName) { $0.bold() }
                        if currentSort == option.propertyName {
                            self.sortDirectionImage
                        }
                    }
                }
            }
        }
        .navigationBarItems(trailing: toggleOrderButton)
        .navigationBarTitle(Text("Sort"), displayMode: .inline)
    }
    
    func onSelect(_ selected: ConfigPanelModel.PossibleExpression) {
        if context.currentView?.datasource.sortProperty == selected.propertyName {
            // Toggle direction
            toggleAscending()
        } else {
            // Change sort property
            changeOrderProperty(selected.propertyName)
        }
    }
    
    
    func toggleAscending() {
        let ds = context.currentView?.datasource
        ds?.sortAscending = !(ds?.sortAscending ?? true)
        context.scheduleCascadableViewUpdate()
    }
    
    func changeOrderProperty(_ fieldName: String) {
        context.currentView?.datasource.sortProperty = fieldName
        context.scheduleCascadableViewUpdate()
    }
    
    static let excludedFields = ["uid", "deleted", "externalId", "version", "allEdges"]
    
    func getSortFields() -> [ConfigPanelModel.PossibleExpression] {
        guard let item = context.currentView?.resultSet.items.first else { return [] }
        
        let properties = item.objectSchema.properties
        
        return properties.compactMap { prop -> ConfigPanelModel.PossibleExpression? in
            if !ConfigPanelSelectionView.excludedFields.contains(prop.name), !prop.name.hasPrefix("_") {
                return ConfigPanelModel.PossibleExpression(propertyName: prop.name)
            }
            else {
                return nil
            }
        }
    }
    
    var sortDirectionImage: some View {
        Image(systemName: context.currentView?.datasource.sortAscending == false
            ? "arrow.down"
            : "arrow.up")
    }
    var toggleOrderButton: some View {
        Button(action: toggleAscending) {
            sortDirectionImage
            .padding(5)
            .contentShape(Rectangle())
        }
    }
    
    

}


struct ConfigPanelEnumSelectionView<EnumType: CaseIterable & RawRepresentable>: View where EnumType.RawValue == String {
    @EnvironmentObject var context: MemriContext
    var configItem: ConfigPanelModel.ConfigItem

    init(configItem: ConfigPanelModel.ConfigItem, type _: EnumType.Type) {
        self.configItem = configItem
    }
    
    
    var currentSelection: String? {
        context.currentView?.renderConfig?.cascadeProperty(configItem.propertyName, type: String.self)
    }
    
    func onSelect(_ selected: String) {
        context.currentView?.renderConfig?.setState(configItem.propertyName, selected)
        context.scheduleUIUpdate()
    }
    
    var body: some View {
        let options = EnumType.allCases
        let currentSelection = self.currentSelection
        
        return SwiftUI.List {
            ForEach(Array(options), id: \.rawValue) { option in
                Button(action: { self.onSelect(option.rawValue) }) {
                    Text(option.rawValue.camelCaseToWords())
                        .if(option.rawValue == currentSelection) { $0.bold() }
                }
            }
        }
        .navigationBarTitle(Text(configItem.displayName), displayMode: .inline)
    }
}
