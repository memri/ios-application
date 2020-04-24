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
        - Open the subview in a popup: .openViewAsPopup()
        - requires implementing subview (which is good to prepare for the refactor)
        - also requires a version of Main only for the subview
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
    - Evolve EditorRow
        - e.g. "phoneNumbers": ["EditorRow", {
            "title": "{.type}",
            "type-hierarchy": "phoneNumber",
            "field": "{.number}",
            "formatter": "{.format()}"
        }]
         - e.g. "addresses": ["EditorRow", {
             "title": "{.name or .type}",
             "type-hierarchy": "address"
         }, [ ... ]]
        - make sure that fully custom rows have an archive button (for person broken heart)
            - requires separate views for editMode and view mode
        - add .each to the title of a group to execute it for each element
            - e.g. "phoneNumbers.each": {}
    - By default use ItemCell to render each item of a list. Search for generalEditor virtual
      renderer. Implement a type:* virtual renderer that renders using the buttons. Implement the
      buttons using subview.
    - in ReadOnly mode hide the fields that are nil or empty sets (add a way to force display)
    - Add editor elements to GUIElement such as datepicker, textfield, etc
    - Implement ForEach in GuiElement
    - Change Measurements to a list of type Measurement that includes a unit
 
    LATER:
    - Create a nice scrolling version of ProfilePicture in a reusable element
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
    
    func getSortedKeys(_ groups: [String:[String]]) -> [String]{
        
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
        let item = main.computedView.resultSet.item!
        let renderConfig = self.renderConfig
        let groups = getGroups(item) ?? [:]
        let sortedKeys = getSortedKeys(groups)
        print(sortedKeys)
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
    
    func getSectionTitle(_ groupKey:String) -> String? {
        renderConfig.renderDescription?[groupKey]?.properties["sectiontitle"] as? String
    }
    
    func isDescriptionForGroup(_ groupKey:String) -> Bool {
        renderConfig.renderDescription?[groupKey]?.properties["for"] as? String == "group"
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
                actionName: .openViewByName,
                actionArgs: [
                    "choose-item-by-query",
                    [
                        "query": className,
                        "type": className,
                        "actionName": "addSelectionToList",
                        "actionArgs": "", // [self.item, groupKey],
                        "title": "Add Selected"
                    ]
                ])
            : nil
        
        return Group{
            if renderDescription[groupKey] != nil {
                if self.getSectionTitle(groupKey) == "" {
                    EmptyView()
                }
                else{
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
                Button(action:{ self.main.executeAction(action!)}) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex:"#777"))
                        .font(.system(size: 18, weight: .semibold))
                }
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
        
        return Group {
            
//            func getVars(_ name:String, _ value:Any?,
//                            _ item:DataItem)-> [String:() -> Any] {
//                return [
//                    "readonly": { !self.main.currentSession.editMode },
//                    "title": { self.groupKey.camelCaseToWords().uppercased() },
//                    "displayname": { name.camelCaseToWords().capitalizingFirstLetter() },
//                    "name": { name },
//                    ".": { value ?? item[name] as Any }
//                ]
//            }
            
//            self.getVars(self.groupKey, groupElement, nil, self.item))
//            self.getVars(self.groupKey, groupKey, nil, self.item))
//            self.getVars(self.groupKey, "", $0, $0))
//            self.getVars(self.groupKey, groupElement, nil, self.item))
//            self.getVars("", prop, nil, self.item)


            
            Section (header: self.getHeader(renderDescription, groupContainsNodes)){
                if renderDescription[groupKey] != nil {
                    // TODO: not sure if the !groupIsEdge condition is necessary
                    if self.getSectionTitle(groupKey) == "" || !groupContainsNodes {
                        ForEach(groups[groupKey]!, id:\.self) { groupElement in
                            self.renderConfig.render(
                                item: self.item,
                                part: self.groupKey,
                                variables: self.getVars(self.groupKey, groupElement, nil, self.item)
                            )
                        }
                    }
                    else {
                    // if title is not empty
                        Divider()
                        if groupContainsNodes {
                            // when you render one GUIElement for the whole group (potentially unwrapped by using wrapStack
                            if self.isDescriptionForGroup(groupKey) {
                                renderConfig.render(
                                    item: item,
                                    part: groupKey,
                                    variables: self.getVars(self.groupKey, groupKey, nil, self.item)
                                )
                            }
                            else {
                                // The normal case for edges: loop over
                                ForEach(self.getArray(item, groupKey), id:\.id) { otherItem in
                                    self.renderConfig.render(
                                        item: otherItem,
                                        part: self.groupKey,
                                        variables: self.getVars(self.groupKey, "", otherItem, otherItem))
                                }
                            }
                        }
                        Divider()
                        
                    }
                }
                else {
                    Divider()
                    ForEach(properties, id: \.self){ prop in
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
                    renderConfig.render(item: item, part: prop, variables: variables)
                }
                else if readOnly {
                    if [.string, .bool, .date, .int, .double].contains(propType){
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
        
        func getType(_ item:DataItem) -> String {
            var type = item.objectSchema["type"] == nil ? className : item.getString("type")
            if type == "" { type = className }
            return type ?? ""
        }
        
        return ScrollView {
            VStack (alignment: .leading, spacing: 5) {
                ForEach(collection, id: \.self) { collectionItem in
                    HStack (spacing:0) {
                        HStack (spacing:0) {
                            Text(getType(collectionItem).camelCaseToWords().capitalizingFirstLetter())
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
        .fixedSize(horizontal: false, vertical: true)
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
