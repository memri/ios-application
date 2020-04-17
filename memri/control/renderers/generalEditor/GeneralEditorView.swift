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
     - Generalize List<>
        - Have a basic way to render them
        - Give them a section by default (below the specified ones)
     - Implement File/Image viewer/editor
     - in ReadOnly mode hide the fields that are nil or empty sets unless they are in groups
    - Add editor elements to GUIElement such as datepicker, textfield, etc
 */

struct GeneralEditorView: View {
    @EnvironmentObject var main: Main
    
    var name: String = "generalEditor"
    
    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs.generalEditor ?? GeneralEditorConfig()
    }
    
    func getOptions(_ groupKey:String, _ name:String, _ item:DataItem) -> [String:() -> Any] {
        return [
            "readonly": { !self.main.currentSession.editMode },
            "title": { groupKey.camelCaseToWords().uppercased() },
            "displayname": { name.camelCaseToWords().capitalizingFirstLetter() },
            "name": { name },
            ".": { item[name] as Any }
        ]
    }
    
    func getTitle(_ groupKey:String) -> String? {
        renderConfig.renderDescription?[groupKey]?.properties["title"] as? String
    }
    
    var body: some View {
        let item = main.computedView.resultSet.item!
        let renderConfig = self.renderConfig
        let groups = renderConfig.groups
        let renderDescription = renderConfig.renderDescription!
        
        return ScrollView {
            VStack (alignment: .leading, spacing: 0) {
                if groups != nil {
                    ForEach(Array(groups!.keys), id: \.self) { groupKey in
                        Group {
                            if renderDescription[groupKey] != nil {
                                if self.getTitle(groupKey) == "" {
                                    VStack (spacing: 0) {
                                        ForEach(groups![groupKey]!, id:\.self) { name in
                                            renderConfig.render(item, groupKey,
                                                self.getOptions(groupKey, name, item))
                                        }
                                    }
                                }
                                else {
                                    Section(header:
                                        Text((self.getTitle(groupKey) ?? groupKey)
                                          .camelCaseToWords()
                                          .uppercased())
                                            .generalEditorHeader()) {

                                        Divider()
                                        ForEach(groups![groupKey]!, id:\.self) { name in
                                            renderConfig.render(item, groupKey,
                                                self.getOptions(groupKey, name, item))
                                        }
                                        Divider()
                                    }
                                }
                            }
                            else {
                                self.drawSection(
                                    header: "\(groupKey)".uppercased(),
                                    item: item,
                                    properties: self.renderConfig.groups![groupKey]!)
                            }
                        }
                    }
                }

                drawSection(
                    header: "OTHER",
                    item: item,
                    properties: getProperties(item))
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
    }
    
    func drawSection(header: String, item: DataItem, properties: [String]) -> some View {
        let editMode = self.main.currentSession.editMode
        
        return Section(header:Text(header).generalEditorHeader()) {
            Divider()
            ForEach(properties, id: \.self){ prop in
                Group {
                    if self.renderConfig.renderDescription![prop] != nil {
                        self.renderConfig.render(item, prop, self.getOptions("", prop, item))
                    }
                    else {
                        GeneralEditorRow(item: item, prop: prop,
                            readOnly: !editMode || self.renderConfig.readOnly.contains(prop),
                            isLast: properties.last == prop)
                    }
                }
            }
            Divider()
        }
    }
    func getProperties(_ item:DataItem) -> [String]{
        return item.objectSchema.properties.filter {
            return !self.renderConfig.excluded.contains($0.name)
                && !self.renderConfig.allGroupValues().contains($0.name)
        }.map({$0.name})
    }
    
}

//public struct EditorGroup<Content: View> : View {
//
//    let groupKey:String
//    let content: (_ item:Data.Element) -> Content
//
//    init(_ key:String, @ViewBuilder content: @escaping (_ item:Data.Element) -> Content) {
//        self.groupKey = key
//        self.content = content
//    }
//
//    @ViewBuilder
//    public var body: some View {
//        if renderDescription[groupKey] != nil {
//            if (renderDescription[groupKey]?.properties["title"] as? String) == "" {
//                VStack (spacing: 0) {
//                    ForEach(groups![groupKey]!, id:\.self) { name in
//                        renderConfig.render(item, groupKey,
//                            self.getOptions(groupKey, name, item))
//                    }
//                }
//            }
//            else {
//                Section(header:
//                    Text((renderDescription[groupKey]?.properties["title"] as? String ?? groupKey)
//                        .camelCaseToWords().uppercased()).generalEditorHeader()) {
//
//                    Divider()
//                    ForEach(groups![groupKey]!, id:\.self) { name in
//                        renderConfig.render(item, groupKey,
//                            self.getOptions(groupKey, name, item))
//                    }
//                    Divider()
//                }
//            }
//        }
//        else {
//            self.drawSection(
//                header: "\(groupKey)".uppercased(),
//                item: item,
//                properties: self.renderConfig.groups![groupKey]!)
//        }
//    }
//}

struct GeneralEditorRow: View {
    @EnvironmentObject var main: Main
    
    var item: DataItem? = nil
    var prop: String = ""
    var readOnly: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        // Get the type from the schema, because when the value is nil the type cannot be determined
        let propType = item!.objectSchema[prop]?.type

        return VStack (spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                Text(prop
                    .camelCaseToWords()
                    .lowercased()
                    .capitalizingFirstLetter()
                )
                .generalEditorLabel()
                
                if self.readOnly {
                    if propType == .string
                      || propType == .bool
                      || propType == .date
                      || propType == .int
                      || propType == .double {
                        defaultRow(self.item!.getString(self.prop))
                    }
                    else if propType == .object { listLabelRow() }
                    else { defaultRow() }
                }
                else {
                    if propType == .string { stringRow() }
                    else if propType == .bool { boolRow() }
                    else if propType == .date { dateRow() }
                    else if propType == .int { intRow() }
                    else if propType == .double { doubleRow() }
                    else if propType == .object { listLabelRow() }
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
            get: { self.item!.getString(self.prop) },
            set: {
                self.item!.set(self.prop, $0)
            }
        )
        
        return TextField("", text: binding)
            .generalEditorCaption()
    }
    
    func boolRow() -> some View {
        let binding = Binding<Bool>(
            get: { self.item![self.prop] as? Bool ?? false },
            set: { _ in
                self.item!.toggle(self.prop)
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
            get: { self.item![self.prop] as? Int ?? 0 },
            set: {
                self.item!.set(self.prop, $0)
                self.main.objectWillChange.send()
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    func doubleRow() -> some View {
        let binding = Binding<Double>(
            get: { self.item![self.prop] as? Double ?? 0 },
            set: {
                self.item!.set(self.prop, $0)
                self.main.objectWillChange.send()
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    func dateRow() -> some View {
        let binding = Binding<Date>(
            get: { self.item![self.prop] as? Date ?? Date() },
            set: {
                self.item!.set(self.prop, $0)
                self.main.objectWillChange.send()
            }
        )
        return DatePicker("", selection: binding, displayedComponents: .date)
            .frame(width: 300, height: 80, alignment: .center)
            .clipped()
            .padding(8)
        
    }
    
    func listLabelRow() -> some View {
        let className = self.item!.objectSchema[self.prop]?.objectClassName
        let collection = DataItemFamily(rawValue: className!.lowercased())!
            .getCollection(self.item![self.prop] as Any)
        
        return ForEach(collection, id: \.self) { item in
            self.defaultRow((item).computeTitle)
        }
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
