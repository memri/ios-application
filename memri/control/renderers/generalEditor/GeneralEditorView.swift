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
    - Permutations of groups:
        - Custom group (each field is a row renderer based on its type)
            - if it is an object type, then a virtual renderer definition is sought
                - otherwise it is rendered as a memri button,
                    - clicking on that button allows to change
                    - when empty a button to choose one is presented
        - Custom group (group is customly rendered - doesnt have to render any fields)
        - List group (group is customly rendered - e.g. labels)
        - List group (each item is customly rendered based on an inline definition)
        - List group (each item is rendered based on virtual renderer definition)
            - in readonly mode rendering is fully custom (but could be as simple as an editor row)
            - in readwrite mode:
                - there's the ability to change the type of relationship as well as setting a name
                    - this needs to be loaded from the type hierarchy
                - either:
                    - choose an item from a list (and display as a memri button)
                      (e.g. diets, labels, medicalConditions)
                    - enter the fields immediately in the editor
                      (e.g. addresses, phoneNr, measurements, publicKeys, websites, companies, etc)
                        - with the option to choose from a list
    - Interaction:
        - Clicking on a memri button in readonly mode goes to either:
            - the item in the default editor
            - or a list of all items that also have a link to that item
              (e.g. everyone on a diet, or with that label)
        - Clicking on a memri button in readwrite mode allows to change it into something else.
          Though in most cases in readwrite mode it doesnt show the memri button
    - By default use ItemCell to render each item of a list. Search for generalEditor virtual
      renderer. Implement a type:* virtual renderer that renders using the buttons. Implement the
      buttons using subview.
    - in ReadOnly mode hide the fields that are nil or empty sets (add a way to force display)
    - Add editor elements to GUIElement such as datepicker, textfield, etc
    - Implement ForEach in GuiElement
    - Change Measurements to a list of type Measurement that includes a unit
 
    LATER:
    - Create a nice scrolling version of ProfilePicture in a reusable element
        - https://blckbirds.com/post/stretchy-header-and-parallax-scrolling-in-swiftui/
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
        var alreadyUsed:[String] = []

        for (key, value) in groups {
            if value.first != key { alreadyUsed = alreadyUsed + value }
        }
        
        (Array(groups.keys) + objectSchema.properties.map{ $0.name }).filter {
            return (objectSchema[$0] == nil || objectSchema[$0]!.objectClassName != nil)
                && !self.renderConfig.excluded.contains($0)
                && !alreadyUsed.contains($0)
        }.forEach({
            filteredGroups[$0] = groups[$0] ?? [$0]
        })
        
        return filteredGroups.count > 0 ? filteredGroups : nil
    }
    
    func getSortedKeys(_ groups: [String:[String]]) -> [String] {
        var keys = Array(self.renderConfig.sequence)
        for k in groups.keys{
            if !keys.contains(k) {
                keys.append(k)
            }
        }
        
        keys = keys.filter{ !self.renderConfig.excluded.contains($0) }
        
        if !keys.contains("other"){
            keys.append("other")
        }
        
        return keys
    }
    
    var body: some View {
        let item = main.computedView.resultSet.singletonItem!
        let renderConfig = self.renderConfig
        let groups = getGroups(item) ?? [:]
        let sortedKeys = getSortedKeys(groups)
        
        return ScrollView {
            VStack (alignment: .leading, spacing: 0) {
                if groups.count > 0 {
                    ForEach(sortedKeys, id: \.self) { groupKey in
                        GeneralEditorSection(
                            item: item,
                            renderConfig: renderConfig,
                            groupKey: groupKey,
                            groups: groups)
                    }
                }
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
    
    func getVars(_ groupKey:String, _ name:String, _ value:Any?,
                    _ item:DataItem)-> [String:() -> Any] {
        
        return [
            "readonly": { !self.main.currentSession.editMode },
            "sectiontitle": { groupKey.camelCaseToWords().uppercased() },
            "displayname": { name.camelCaseToWords().capitalizingFirstLetter() },
            "name": { name },
            ".": { value ?? item[name] as Any }
        ]
    }
    
    func hasSectionTitle(_ groupKey:String) -> Bool {
        return !(renderConfig.renderDescription?[groupKey]?._properties["sectiontitle"] as? String == "")
    }
    
    func getSectionTitle(_ groupKey:String) -> String? {
        renderConfig.renderDescription?[groupKey]?.getString("sectiontitle", self.item)
    }
    
    func isDescriptionForGroup(_ groupKey:String) -> Bool {
        return renderConfig.renderDescription?[groupKey]?._properties["for"] as? String == "group"
    }
    
    func getType(_ groupKey:String) -> String {
        renderConfig.renderDescription?[groupKey]?.type ?? ""
    }
    
    func getHeader(_ renderDescription: [String:GUIElementDescription],
                   _ isArray: Bool) -> some View{
        
        let editMode = self.main.currentSession.editMode
        let isArray = item.objectSchema[groupKey]?.isArray ?? false
        let className = (self.item.objectSchema[groupKey]?.objectClassName ?? "").lowercased()
        let readOnly = self.renderConfig.readOnly.contains(groupKey)
        
        let actionDescription = isArray && editMode && !readOnly
            ? ActionDescription(
                icon: "plus",
                actionName: .openViewByName,
                actionArgs: [
                    "choose-item-by-query",
                    [
                        "query": className,
                        "type": className,
                        "actionName": "addSelectionToList",
                        "actionArgs": "", // [self.item, groupKey],
                        "title": "Add Selected",
                        ".": item
                    ]
                ],
                actionType: .popup)
            : nil
        
        return Group{
            if renderDescription[groupKey] != nil {
                if !self.hasSectionTitle(groupKey) {
                    EmptyView()
                }
                else {
                    self.constructSectionHeader(
                        title: self.getSectionTitle(groupKey) ?? groupKey,
                        action: actionDescription
                    )
                }
            }
            else {
                self.constructSectionHeader(
                    title: (groupKey == "other" && groups.count == 0) ? "all" : groupKey,
                    action: actionDescription
                )
            }
        }
    }
    
    func constructSectionHeader(title:String, action:ActionDescription? = nil) -> some View {
        HStack (alignment: .bottom) {
            Text(title.camelCaseToWords().uppercased())
                .generalEditorHeader()
            
            if action != nil {
                Spacer()
                Action(action: action!)
                    .foregroundColor(Color(hex:"#777"))
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.bottom, 10)
            }
        }.padding(.trailing, 20)
    }

    var body: some View {
        let renderDescription = renderConfig.renderDescription!
        let editMode = self.main.currentSession.editMode
        
        let properties = groupKey == "other"
            ? self.getProperties(item)
            : self.groups[self.groupKey]!
        let groupContainsNodes = item.objectSchema[groupKey]?.isArray ?? false
        let showDividers = self.getSectionTitle(groupKey) != ""
        
        return Group {
            Section (header: self.getHeader(renderDescription, groupContainsNodes)){
                // Render using a view specified renderer
                if renderDescription[groupKey] != nil {
                    if showDividers { Divider() }
                    
                    if self.isDescriptionForGroup(groupKey) {
                        renderConfig.render(
                            item: item,
                            part: groupKey,
                            variables: self.getVars(self.groupKey, groupKey, nil, self.item)
                        )
                    }
                    else {
                        if groupContainsNodes {
                            ForEach(self.getArray(item, groupKey), id:\.id) { otherItem in
                                self.renderConfig.render(
                                    item: otherItem,
                                    part: self.groupKey,
                                    variables: self.getVars(self.groupKey, "", otherItem, otherItem))
                            }
                        }
                        else {
                            ForEach(groups[groupKey]!, id:\.self) { groupElement in
                                self.renderConfig.render(
                                    item: self.item,
                                    part: self.groupKey,
                                    variables: self.getVars(self.groupKey, groupElement, nil, self.item)
                                )
                            }
                        }
                    }
                    
                    if showDividers { Divider() }
                }
                // Render lists with their default renderer
                else if groupContainsNodes {
                    Divider()
                    ScrollView {
                        VStack (alignment: .leading, spacing: 0) {
                            ForEach(getArray(item, groupKey), id:\.id) { item in
                                ItemCell(
                                    item: item,
                                    rendererNames: ["generalEditor"],
                                    variables: self.getVars(self.groupKey, self.groupKey, item, self.item)
                                )
                            }
                        }
//                        .padding(.top, 10)
                    }
                    .frame(maxHeight: 1000)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                }
                // Render groups with the default render row
                else {
                    Divider()
                    ForEach(properties, id: \.self){ prop in
                        
                        // TODO: Refactor: rows that are single links to an item
                        
                        DefaultGeneralEditorRow(
                            main: self._main,
                            item: self.item,
                            prop: prop,
                            readOnly: !editMode || self.renderConfig.readOnly.contains(prop),
                            isLast: properties.last == prop,
                            renderConfig: self.renderConfig,
                            variables: self.getVars("", prop, nil, self.item)
                        )
                    }
                    Divider()
                    
                }
            }
        }
    }
}

struct DefaultGeneralEditorRow: View {
    @EnvironmentObject var main: Main
    
    var item: DataItem
    var prop: String
    var readOnly: Bool
    var isLast: Bool
    var renderConfig: GeneralEditorConfig
    var variables: [String:() -> Any]
    
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
                
                if renderConfig.renderDescription![prop] != nil {
                    renderConfig.render(item: item, part: prop, variables: variables)
                }
                else if readOnly {
                    if [.string, .bool, .date, .int, .double].contains(propType){
                        defaultRow(self.item.getString(self.prop))
                    }
                    else if propType == .object { defaultRow(self.item.computedTitle) }
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

struct GeneralEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let main = RootMain(name: "", key: "").mockBoot()
        
        return ZStack {
            VStack(alignment: .center, spacing: 0) {
                TopNavigation()
                GeneralEditorView()
                Search()
            }.fullHeight()
            
            ContextPane()
        }.environmentObject(main)
    }
}
