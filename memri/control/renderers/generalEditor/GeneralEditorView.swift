//
//  GeneralEditorView.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

/*
 TODO:
    - Add + button behavior near grouped sections
    - Fix sequence of the group sections
    - in ReadOnly mode hide the fields that are nil or empty sets (add a way to force display)
    - Add editor elements to GUIElement such as datepicker, textfield, etc
 
    LATER:
    - Implement Image picker
    - Implement Color picker
    - Implement the buttons as a non-property section
    - Implement social profile section for person
    - Add customer renderer for starred and labels for person
 */


struct GeneralEditorView: View {
    @EnvironmentObject var main: Main
    
    var name: String = "generalEditor"
    
    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs.generalEditor ?? GeneralEditorConfig()
    }
    
    func getGroups(_ item:DataItem) -> [String:[String]]? {
        let groups = self.renderConfig.groups ?? [:]
        var filteredGroups: [String:[String]] = [:]
        let objectSchema = item.objectSchema
        
        (Array(groups.keys) + objectSchema.properties.map{ $0.name }).filter {
            return (objectSchema[$0] == nil || objectSchema[$0]!.objectClassName != nil)
                && !self.renderConfig.excluded.contains($0)
        }.forEach({
            filteredGroups[$0] = groups[$0] ?? [$0]
        })
        
        return filteredGroups.count > 0 ? filteredGroups : nil
    }
    
    var body: some View {
        let item = main.computedView.resultSet.item!
        let renderConfig = self.renderConfig
        let groups = getGroups(item) ?? [:]
        
        return ScrollView {
            VStack (alignment: .leading, spacing: 0) {
                if groups.count > 0 {
                    ForEach(Array(groups.keys), id: \.self) { groupKey in
                        GeneralEditorSection(
                            item: item,
                            renderConfig: renderConfig,
                            groupKey: groupKey,
                            groups: groups)
                    }
                }

                GeneralEditorSection(
                    item: item,
                    renderConfig: renderConfig,
                    groupKey: "other",
                    groups: groups)
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
    }
}

struct GeneralEditorSection: View {
    @EnvironmentObject var main: Main

    var item: DataItem
    var renderConfig: GeneralEditorConfig
    var groupKey: String
    var groups:[String:[String]]
    
    func getArray(_ item:DataItem, _ prop:String) -> [DataItem] {
        let className = item.objectSchema[prop]?.objectClassName
        let family = DataItemFamily(rawValue: className!.lowercased())!
        return family.getCollection(item[prop] as Any)
    }
    
    func getProperties(_ item:DataItem) -> [String]{
        return item.objectSchema.properties.filter {
            return !self.renderConfig.excluded.contains($0.name)
                && !self.renderConfig.allGroupValues().contains($0.name)
                && $0.objectClassName == nil
        }.map({$0.name})
    }
    
    func getVariablesDict(_ groupKey:String, _ name:String, _ value:Any?,
                    _ item:DataItem) -> [String:() -> Any] {
        return [
            "readonly": { !self.main.currentSession.editMode },
            "title": { groupKey },
            "displayname": { name.camelCaseToWords().capitalizingFirstLetter() },
            "name": { name },
            ".": { value ?? item[name] as Any }
        ]
    }
    
    func getTitle(_ groupKey:String) -> String? {
        renderConfig.renderDescription?[groupKey]?.properties["title"] as? String
    }
    
    func renderForGroup(_ groupKey:String) -> Bool {
        renderConfig.renderDescription?[groupKey]?.properties["for"] as? String == "group"
    }
    
    func getType(_ groupKey:String) -> String {
        renderConfig.renderDescription?[groupKey]?.type ?? ""
    }
    
    var body: some View {
        let renderDescription = renderConfig.renderDescription!
        let editMode = self.main.currentSession.editMode
        let isArray = item.objectSchema[groupKey]?.isArray ?? false
        let className = self.item.objectSchema[groupKey]?.objectClassName ?? ""
        let readOnly = self.renderConfig.readOnly.contains(groupKey)
        
        let properties = groupKey == "other"
            ? self.getProperties(item)
            : self.groups[self.groupKey]!
        
        return Group {
            if renderDescription[groupKey] != nil {
                if self.getTitle(groupKey) == "" {
                    Section (header: EmptyView()) {
                        ForEach(groups[groupKey]!, id:\.self) { name in
                            self.renderConfig.render(self.item, self.groupKey,
                                self.getVariablesDict(self.groupKey, name, nil, self.item))
                        }
                    }
                }
                else {
                    Section(
                        header: self.sectionHeader(
                            title: self.getTitle(groupKey) ?? groupKey,
                            action: isArray && editMode && !readOnly
                                ? ActionDescription(
                                    actionName: .openViewByName,
                                    actionArgs: [
                                        "choose-item-by-query",
                                        [
                                            "query": className,
                                            "type": className,
                                            "actionName": "addSelectionToList",
                                            "actionArgs": [], // TODO below
//                                            "actionArgs": [self.item, groupKey],
//                                            "actionArgs": "[{previousSession.resultSet.item}, \"\(groupKey)\"]",
                                            "title": "Add Selected"
                                        ]
                                    ])
                                : nil
                        )
                    ) {
                        Divider()
                        if isArray {
                            if self.renderForGroup(groupKey) {
                                renderConfig.render(item, groupKey,
                                    self.getVariablesDict(groupKey, groupKey, nil, item))
                            }
                            else {
                                ForEach(self.getArray(item, groupKey), id:\.id) {
                                    self.renderConfig.render(self.item, self.groupKey,
                                        self.getVariablesDict(self.groupKey, "", $0, self.item))
                                }
                            }
                        }
                        else {
                            ForEach(groups[groupKey]!, id:\.self) { name in
                                self.renderConfig.render(self.item, self.groupKey,
                                    self.getVariablesDict(self.groupKey, name, nil, self.item))
                            }
                        }
                        Divider()
                    }
                }
            }
            else {
                Section(header: sectionHeader(
                    title: groupKey == "other"
                        ? groups.count > 0 ? "other" : "all"
                        : groupKey,
                    action: isArray && editMode && !readOnly
                        ? ActionDescription(actionName: .noop)
                        : nil
                )) {
                    Divider()
                    ForEach(properties, id: \.self){ prop in
                        GeneralEditorRow(
                            main: self._main,
                            item: self.item,
                            prop: prop,
                            readOnly: !editMode || self.renderConfig.readOnly.contains(prop),
                            isLast: properties.last == prop,
                            renderConfig: self.renderConfig,
                            options: self.getVariablesDict("", prop, nil, self.item)
                        )
                    }
                    Divider()
                }
            }
        }
    }
    
    func sectionHeader(title:String, action:ActionDescription? = nil) -> some View {
        HStack (alignment: .bottom) {
            Text(title.camelCaseToWords().uppercased())
                .generalEditorHeader()
            
            if action != nil {
                Spacer()
                Button(action:{ self.main.executeAction(action!) }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex:"#777"))
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.bottom, 10)
            }
        }.padding(.trailing, 20)
    }
}

struct GeneralEditorRow: View {
    @EnvironmentObject var main: Main
    
    var item: DataItem
    var prop: String
    var readOnly: Bool
    var isLast: Bool
    var renderConfig: GeneralEditorConfig
    var options: [String:() -> Any]
    
    var body: some View {
        // Get the type from the schema, because when the value is nil the type cannot be determined
        let propType = item.objectSchema[prop]?.type
        let isArray = item.objectSchema[prop]?.isArray ?? false

        return VStack (spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                if !isArray {
                    Text(prop
                        .camelCaseToWords()
                        .lowercased()
                        .capitalizingFirstLetter()
                    )
                    .generalEditorLabel()
                }
                
                if renderConfig.renderDescription![prop] != nil {
                    renderConfig.render(item, prop, options)
                }
                else if readOnly {
                    if propType == .string
                      || propType == .bool
                      || propType == .date
                      || propType == .int
                      || propType == .double {
                        defaultRow(self.item.getString(self.prop))
                    }
                    else if propType == .object {
                        if isArray { listRow() }
                        else { defaultRow(self.item.computeTitle) }
                    }
                    else { defaultRow() }
                }
                else {
                    if propType == .string { stringRow() }
                    else if propType == .bool { boolRow() }
                    else if propType == .date { dateRow() }
                    else if propType == .int { intRow() }
                    else if propType == .double { doubleRow() }
                    else if propType == .object {
                        if isArray { listRow() }
                        else { defaultRow() }
                    }
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
        
        return TextField("", text: binding)
            .generalEditorCaption()
    }
    
    func boolRow() -> some View {
        let binding = Binding<Bool>(
            get: { self.item[self.prop] as? Bool ?? false },
            set: { _ in
                self.item.toggle(self.prop)
                self.main.objectWillChange.send()
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
                self.main.objectWillChange.send()
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    func doubleRow() -> some View {
        let binding = Binding<Double>(
            get: { self.item[self.prop] as? Double ?? 0 },
            set: {
                self.item.set(self.prop, $0)
                self.main.objectWillChange.send()
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    func dateRow() -> some View {
        let binding = Binding<Date>(
            get: { self.item[self.prop] as? Date ?? Date() },
            set: {
                self.item.set(self.prop, $0)
                self.main.objectWillChange.send()
            }
        )
        return DatePicker("", selection: binding, displayedComponents: .date)
            .frame(width: 300, height: 80, alignment: .center)
            .clipped()
            .padding(8)
        
    }
    
    func listRow() -> some View {
        let className = self.item.objectSchema[self.prop]?.objectClassName
        let collection = DataItemFamily(rawValue: className!.lowercased())!
            .getCollection(self.item[self.prop] as Any)
        
        return ScrollView {
            VStack (alignment: .leading, spacing: 5) {
                ForEach(collection, id: \.self) { collectionItem in
                    HStack (spacing:0) {
                        HStack (spacing:0) {
                            Text(className!.camelCaseToWords().capitalizingFirstLetter())
                                .padding(.trailing, 5)
                                .padding(.leading, 6)
                                .padding(.vertical, 3)
                                .foregroundColor(Color.white)
                                .font(.system(size: 14, weight: .bold))
                                
                            Text(collectionItem.computeTitle)
                                .padding(.leading, 6)
                                .padding(.trailing, 9)
                                .padding(.vertical, 3)
                                .background(Color.gray)
                                .foregroundColor(Color.white)
                                .font(.system(size: 14, weight: .bold))
                            .zIndex(10)
                        }
                        .background(Color.purple)
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        if !self.readOnly {
                            Button (action: {}) {
                                Image(systemName: "archivebox")
                                    .foregroundColor(Color(hex:"#777"))
                            }
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
        .frame(maxHeight: 300)
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

struct GeneralEditorView_Previews: PreviewProvider {
    static var previews: some View {
        return GeneralEditorView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
