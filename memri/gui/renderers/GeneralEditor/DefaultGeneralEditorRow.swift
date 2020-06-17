//
//  DefaultGeneralEditorRow.swift
//  memri
//
//  Created by Ruben Daniels on 6/15/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift
import memriUI

struct DefaultGeneralEditorRow: View {
    @EnvironmentObject var context: MemriContext
    
    var item: DataItem
    var prop: String
    var readOnly: Bool
    var isLast: Bool
    var renderConfig: CascadingRenderConfig
    var arguments: ViewArguments
    
    var body: some View {
        // Get the type from the schema, because when the value is nil the type cannot be determined
        let propType = item.objectSchema[prop]?.type

        return VStack (spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                Text(prop
                    .camelCaseToWords()
                    .lowercased()
                    .capitalizingFirstLetter()
                )
                .generalEditorLabel()
                
                if renderConfig.hasGroup(prop) {
                    renderConfig.render(item: item, group: prop, arguments: arguments)
                }
                else if readOnly {
                    if [.string, .bool, .date, .int, .double].contains(propType){
                        defaultRow(self.item.getString(self.prop))
                    }
                    else if propType == .object {
                        if self.item[self.prop] is DataItem {
                            MemriButton(context: self._context,
                                        item: self.item[self.prop] as! DataItem)
                        }
                        else {
                            defaultRow()
                        }
                    }
                    else { defaultRow() }
                }
                else {
                    if propType == .string { stringRow() }
                    else if propType == .bool { boolRow() }
                    else if propType == .date { dateRow() }
                    else if propType == .int { intRow() }
                    else if propType == .double { doubleRow() }
                    else if propType == .object { defaultRow() }
                    else { defaultRow() }
                }
            }
            .fullWidth()
            .padding(.bottom, 10)
            .padding(.horizontal, 36)
            .background(readOnly ? Color(hex:"#f9f9f9") : Color(hex:"#f7fcf5"))
            
            if !isLast {
                Divider().padding(.leading, 35)
            }
        }
    }
    
    func stringRow() -> some View {
        let binding = Binding<String>(
            get: { self.item.getString(self.prop) },
            set: {
                self.item.set(self.prop, $0)
            }
        )
        
        return MemriTextField(value: binding)
            .generalEditorCaption()
    }
    
    func boolRow() -> some View {
        let binding = Binding<Bool>(
            get: { self.item[self.prop] as? Bool ?? false },
            set: { _ in
                self.item.toggle(self.prop)
                self.context.objectWillChange.send()
            }
        )
        
        return Toggle(isOn: binding) {
            Text(prop
                .camelCaseToWords()
                .lowercased()
                .capitalizingFirstLetter())
        }
        .toggleStyle(MemriToggleStyle())
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
        
        return MemriTextField(value: binding)
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
        
        return MemriTextField(value: binding)
            .generalEditorCaption()
    }
    
    func dateRow() -> some View {
        let binding = Binding<Date>(
            get: { self.item[self.prop] as? Date ?? Date() },
            set: {
                self.item.set(self.prop, $0)
                self.context.objectWillChange.send()
            }
        )
        
        return DatePicker("", selection: binding, displayedComponents: .date)
            .frame(width: 300, height: 80, alignment: .center)
            .clipped()
            .padding(8)
        
    }
    
    func defaultRow(_ caption:String? = nil) -> some View {
        Text(caption ?? (prop.camelCaseToWords().lowercased().capitalizingFirstLetter()))
              .generalEditorCaption()
    }
}

public extension View {
    func generalEditorLabel() -> some View { self.modifier(GeneralEditorLabel()) }
    func generalEditorCaption() -> some View { self.modifier(GeneralEditorCaption()) }
    func generalEditorHeader() -> some View { self.modifier(GeneralEditorHeader()) }
    func generalEditorInput() -> some View { self.modifier(GeneralEditorInput()) }
}

private struct GeneralEditorInput: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fullHeight()
            .font(.system(size:16, weight: .regular))
            .padding(10)
            .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
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
            .foregroundColor(Color(hex:"#434343"))
            .padding(.bottom, 5)
            .padding(.top, 24)
            .padding(.horizontal, 36)
            .foregroundColor(Color(hex: "#333"))
    }
}
