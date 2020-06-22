//
//  GeneralEditorSection.swift
//  memri
//
//  Created by Ruben Daniels on 6/15/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

struct GeneralEditorSection: View {
    @EnvironmentObject var context: MemriContext

    var item: DataItem
    var renderConfig: CascadingGeneralEditorConfig
    var groupKey: String
    var groups:[String:[String]]

    var body: some View {
        let renderConfig = self.renderConfig
        let editMode = self.context.currentSession.isEditMode
        let properties = groupKey == "other"
            ? self.getProperties(item)
            : self.groups[self.groupKey] ?? []
        let groupIsList = item.objectSchema[groupKey]?.isArray ?? false
        let showDividers = self.hasSectionTitle(groupKey)
        let listHasItems = groupIsList && (item[groupKey] as? ListBase)?.count ?? 0 > 0
        
        return Section (header: self.getHeader(groupIsList, listHasItems)) {
            if groupIsList && !listHasItems && !editMode {
                EmptyView()
            }
            // Render using a view specified renderer
            else if renderConfig.hasGroup(groupKey) {
                if showDividers { Divider() }
                
                if self.isDescriptionForGroup(groupKey) {
                    renderConfig.render(
                        item: item,
                        group: groupKey,
                        arguments: self.getViewArguments(self.groupKey, groupKey, nil, self.item)
                    )
                }
                else {
                    if groupIsList {
                        ForEach(self.getArray(item, groupKey), id:\.id) { otherItem in
                            self.renderConfig.render(
                                item: otherItem,
                                group: self.groupKey,
                                arguments: self.getViewArguments(self.groupKey, "", otherItem, otherItem))
                        }
                    }
                    else {
                        // TODO: Error handling
                        ForEach(groups[groupKey] ?? [], id:\.self) { groupElement in
                            self.renderConfig.render(
                                item: self.item,
                                group: self.groupKey,
                                arguments: self.getViewArguments(self.groupKey, groupElement,
                                                                 nil, self.item)
                            )
                        }
                    }
                }
                
                if showDividers { Divider() }
            }
            // Render lists with their default renderer
            else if groupIsList {
                Divider()
                ScrollView {
                    VStack (alignment: .leading, spacing: 0) {
                        ForEach(getArray(item, groupKey), id:\.id) { item in
                            ItemCell(
                                item: item,
                                rendererNames: ["generalEditor"],
                                arguments: self.getViewArguments(self.groupKey, self.groupKey,
                                                                 item, self.item)
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
                        context: self._context,
                        item: self.item,
                        prop: prop,
                        readOnly: !editMode || renderConfig.readOnly.contains(prop),
                        isLast: properties.last == prop,
                        renderConfig: renderConfig,
                        arguments: self.getViewArguments("", prop, self.item[prop], self.item)
                    )
                }
                Divider()
            }
        }
    }

    func getArray(_ item:DataItem, _ prop:String) -> [DataItem] {
        dataItemListToArray(item[prop] ?? [])
    }
    
    func getProperties(_ item:DataItem) -> [String]{
        return item.objectSchema.properties.filter {
            return !self.renderConfig.excluded.contains($0.name)
                && !self.renderConfig.allGroupValues().contains($0.name)
                && !$0.isArray
        }.map({$0.name})
    }
    
    func getViewArguments(_ groupKey:String, _ name:String, _ value:Any?,
                          _ item:DataItem)-> ViewArguments {
        
        return ViewArguments(renderConfig.viewArguments.asDict().merging([
            "subject": self.item,
            "readOnly": !self.context.currentSession.isEditMode,
            "sectionTitle": groupKey.camelCaseToWords().uppercased(),
            "displayName": name.camelCaseToWords().capitalizingFirstLetter(),
            "name": name,
            ".": value as Any
        ], uniquingKeysWith: { current, new in new }))
    }
    
    func hasSectionTitle(_ groupKey:String) -> Bool {
        renderConfig.getGroupOptions(groupKey)["sectionTitle"] as? String != ""
    }
    
    func getSectionTitle(_ groupKey:String) -> String? {
        let title = renderConfig.getGroupOptions(groupKey)["sectionTitle"]
        
        if let title = title as? String {
            return title
        }
        else if let expr = title as? Expression {
            let args = getViewArguments(self.groupKey, self.groupKey, nil, self.item)
            do {
                return try expr.execForReturnType(args)
            }
            catch let error {
                debugHistory.error("\(error)")
                return nil
            }
        }
        
        return nil
    }
    
    func isDescriptionForGroup(_ groupKey:String) -> Bool {
        if !renderConfig.hasGroup(groupKey) { return false }
        return renderConfig.getGroupOptions(groupKey)["foreach"] as? Bool == false
    }
    
//    func getType(_ groupKey:String) -> String {
//        renderConfig.renderDescription?[groupKey]?.type ?? ""
//    }
    
    func getHeader(_ isArray: Bool, _ listHasItems: Bool) -> some View {
        let editMode = self.context.currentSession.isEditMode
        let className = self.item.objectSchema[groupKey]?.objectClassName ?? ""
        let readOnly = self.renderConfig.readOnly.contains(groupKey)
        
        let action = isArray && editMode && !readOnly
            ? ActionOpenViewByName(context,
                arguments: [
                    "name": "choose-item-by-query",
                    "viewArguments": ViewArguments([
                        "query": className,
                        "type": className,
                        "subject": item,
                        "property": groupKey,
                        "title": "Choose a \(className)",
                        "dataItem": item
                    ])
                ],
                values: [
                    "icon": "plus",
                    "renderAs": RenderType.popup
                ])
            : nil
        
        return Group {
            if isArray && !listHasItems && !editMode {
                EmptyView()
            }
            else if renderConfig.hasGroup(groupKey) {
                if self.hasSectionTitle(groupKey) {
                    self.constructSectionHeader(
                        title: self.getSectionTitle(groupKey) ?? groupKey,
                        action: action
                    )
                }
                else {
                    EmptyView()
                }
            }
            else {
                self.constructSectionHeader(
                    title: (groupKey == "other" && groups.count == 0) ? "all" : groupKey,
                    action: action
                )
            }
        }
    }
    
    func constructSectionHeader(title:String, action:Action? = nil) -> some View {
        HStack (alignment: .bottom) {
            Text(title.camelCaseToWords().uppercased())
                .generalEditorHeader()
            
            if action != nil {
                Spacer()
                // NOTE: Allowed force unwrapping
                ActionButton(action: action!)
                    .foregroundColor(Color(hex:"#777"))
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.bottom, 10)
            }
        }.padding(.trailing, 20)
    }
}
