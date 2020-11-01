//
//  GeneralEditorRows.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct DefaultGeneralEditorRow: View {
    @EnvironmentObject var context: MemriContext
    
    var item: Item
    var prop: String
    var readOnly: Bool
    var isLast: Bool
    var renderConfig: CascadingRendererConfig
    var arguments: ViewArguments
    
    var body: some View {
        // Get the type from the schema, because when the value is nil the type cannot be determined
        let propType = item.objectSchema[prop]?.type
        let propValue: Any? = self.item.get(self.prop)
        
        return VStack(spacing: 0) {
            if propValue == nil && readOnly {
                EmptyView()
            }
            else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prop
                        .camelCaseToWords()
                        .lowercased()
                        .capitalizingFirst())
                        .generalEditorLabel()
                    
                    if renderConfig.hasGroup(prop) {
                        renderConfig.render(item: item, group: prop, arguments: arguments)
                    }
                    else if readOnly {
                        if [.string, .bool, .date, .int, .double].contains(propType) {
                            defaultRow(ExprInterpreter.evaluateString(propValue, defaultValue: ""))
                        }
                        else if propType == .object {
                            if propValue is Item {
                                MemriButton(item: propValue as? Item)
                                    .environmentObject(self.context)
                            }
                            else {
                                defaultRow()
                            }
                        }
                        else { defaultRow() }
                    }
                    else {
                        switch propType {
                        case .string:
                            stringRow()
                        case .bool:
                            boolRow()
                        case .date:
                            dateRow()
                        case .int:
                            intRow()
                        case .double:
                            doubleRow()
                        default:
                            defaultRow()
                        }
                    }
                }
                .fullWidth()
                .padding(.bottom, 10)
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                if !isLast {
                    Divider().padding(.leading, 35)
                }
            }
        }
    }
    
    func stringRow() -> some View {
        let binding = Binding<String>(
            get: { self.item.getString(self.prop) ?? "" },
            set: {
                self.item.set(self.prop, $0)
        }
        )
        
        return MemriTextField(value: binding,
                              clearButtonMode: .whileEditing,
                              isEditing: $context.editMode,
                              isSharedEditingBinding: true)
        .generalEditorCaption()
    }
    
    func boolRow() -> some View {
        let binding = Binding<Bool>(
            get: { self.item[self.prop] as? Bool ?? false },
            set: { _ in
                do {
                    try self.item.toggle(self.prop)
                    self.context.objectWillChange.send()
                }
                catch {}
        }
        )
        
        return Toggle(isOn: binding) {
            Text(prop
                .camelCaseToWords()
                .lowercased()
                .capitalizingFirst())
        }
        .generalEditorCaption()
    }
    
    func intRow() -> some View {
        let binding = Binding<Int>(
            get: { self.item[self.prop] as? Int ?? 0 },
            set: {
                self.item.set(self.prop, $0)
                self.context.objectWillChange.send()
        }
        )
        
        return MemriTextField(value: binding,
                              clearButtonMode: .whileEditing,
                              isEditing: $context.editMode,
                              isSharedEditingBinding: true)
        .generalEditorCaption()
    }
    
    func doubleRow() -> some View {
        let binding = Binding<Double>(
            get: { self.item[self.prop] as? Double ?? 0 },
            set: {
                self.item.set(self.prop, $0)
                self.context.objectWillChange.send()
        }
        )
        
        return MemriTextField(value: binding,
                              clearButtonMode: .whileEditing,
                              isEditing: $context.editMode,
                              isSharedEditingBinding: true)
        .generalEditorCaption()
    }
    
    @ViewBuilder
    func dateRow() -> some View {
        let binding = Binding<Date>(
            get: { self.item[self.prop] as? Date ?? Date() },
            set: {
                self.item.set(self.prop, $0)
                self.context.objectWillChange.send()
        }
        )
        
        DatePicker("", selection: binding, displayedComponents: .date)
            .labelsHidden()
    }
    
    func defaultRow(_ caption: String? = nil) -> some View {
        Text(caption ?? prop.camelCaseToWords().lowercased().capitalizingFirst())
            .generalEditorCaption()
    }
}

public extension View {
    func generalEditorLabel() -> some View { modifier(GeneralEditorLabel()) }
    func generalEditorCaption() -> some View { modifier(GeneralEditorCaption()) }
    func generalEditorHeader() -> some View { modifier(GeneralEditorHeader()) }
    func generalEditorInput() -> some View { modifier(GeneralEditorInput()) }
}

private struct GeneralEditorInput: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fullHeight()
            .font(.system(size: 16, weight: .regular))
            .padding(10)
//            .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
            .generalEditorCaption()
    }
}

private struct GeneralEditorLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(hex: "#38761d"))
            .font(.system(size: 14, weight: .regular))
            .padding(.top, 10)
    }
}

private struct GeneralEditorCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(Color(hex: "#223322"))
    }
}

private struct GeneralEditorHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 15, weight: .regular))
            .foregroundColor(Color(hex: "#434343"))
            .padding(.bottom, 5)
            .padding(.top, 24)
            .padding(.horizontal)
            .foregroundColor(Color(hex: "#333"))
    }
}
