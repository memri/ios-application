//
//  FIlterpannel.swift
//  memri
//
//  Created by Koen van der Veen on 25/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct BrowseSetting: Identifiable {
    var id = UUID()
    var name: String
    var selected: Bool
    var color: Color {self.selected ? Color(hex: "#6aa84f") : Color(hex: "#434343")}
    var fontWeight: Font.Weight? {self.selected ? .semibold : .regular}
}

struct FilterPanel: View {
    @EnvironmentObject var main: Main
    
    @State var browseSettings = [BrowseSetting(name: "Default", selected: true),
                                 BrowseSetting(name: "Year-Month-Day view", selected: false)]
    
    private func allOtherFields() -> [String] {
        var list:[String] = []
        
        if let item = self.main.cascadingView.resultSet.items.first {
            var excludeList = self.main.cascadingView.sortFields
            excludeList.append(self.main.cascadingView.datasource.sortProperty ?? "")
            excludeList.append("uid")
            excludeList.append("deleted")
            
            let properties = item.objectSchema.properties
            for prop in properties {
                if !excludeList.contains(prop.name) && prop.type != .object && prop.type != .linkingObjects {
                    list.append(prop.name)
                }
            }
        }
        
        return list
    }
    
    private func toggleAscending() {
        realmWriteIfAvailable(main.realm) {
            self.main.currentSession.currentView.datasource?.sortAscending.value
                = !(self.main.cascadingView.datasource.sortAscending ?? true)
        }
        self.main.scheduleCascadingViewUpdate()
    }
    
    private func changeOrderProperty(_ fieldName:String) {
        realmWriteIfAvailable(main.realm) {
            self.main.currentSession.currentView.datasource?.sortProperty = fieldName
        }
        self.main.scheduleCascadingViewUpdate()
    }
    
    private func rendererCategories() -> [(String, FilterPanelRendererButton)] {
        return self.main.renderers.tuples.filter{(key, renderer) -> Bool in
            return !key.contains(".") && renderer.canDisplayResults(self.main.items)
        }
    }
    
    private func renderersAvailable() -> [(String, FilterPanelRendererButton)] {
        if let currentCategory = self.main.cascadingView.activeRenderer.split(separator: ".").first {
            return self.main.renderers.all.filter { (key, renderer) -> Bool in
                return renderer.rendererName.split(separator: ".").first == currentCategory
            }.sorted(by: { $0.1.order < $1.1.order })
        }
        return []
    }
    
    private func isActive(_ renderer:FilterPanelRendererButton) -> Bool {
        self.main.cascadingView.activeRenderer.split(separator: ".").first! == renderer.rendererName
    }
    
    var body: some View {
        let main = self.main
        let cascadingView = self.main.cascadingView
        
        return HStack(alignment: .top, spacing: 0){
            VStack(alignment: .leading, spacing: 0){
                HStack(alignment: .top, spacing: 3) {
                    ForEach(rendererCategories(), id: \.0) { (key, renderer) in
                        
                        Button(action: { main.executeAction(renderer) } ) {
                            Image(systemName: renderer.getString("icon"))
                                .fixedSize()
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(self.isActive(renderer)
                                    ? renderer.getColor("activeColor")
                                    : renderer.getColor("inactiveColor"))
                                .background(self.isActive(renderer)
                                    ? renderer.getColor("activeBackgroundColor")
                                    : renderer.getColor("inactiveBackgroundColor"))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .background(Color.white)
                .padding(.top, 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0){
                        ForEach(renderersAvailable(), id:\.0) { (key, renderer) in
                            Group {
                                Button(action:{ main.executeAction(renderer) }) {
                                    if cascadingView.activeRenderer == renderer.rendererName {
                                        Text(LocalizedStringKey(renderer.getString("title")))
                                            .foregroundColor(Color(hex: "#6aa84f"))
                                            .fontWeight(.semibold)
                                            .font(.system(size: 16))
                                            .padding(.vertical, 12)
                                    }
                                    else {
                                        Text(LocalizedStringKey(renderer.getString("title")))
                                            .foregroundColor(Color(hex: "#434343"))
                                            .fontWeight(.regular)
                                            .font(.system(size: 16))
                                            .padding(.vertical, 12)
                                    }
                                }
                                Rectangle()
                                    .frame(minHeight: 1, maxHeight: 1)
                                    .foregroundColor(Color(hex: "#efefef"))
                            }
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .background(Color.white)
                .padding(.top, 1)
            }
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
            .padding(.bottom, 1)
            
            ScrollView {
                VStack (alignment: .leading, spacing: 7) {
                    Text("SORT ON:")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 15)
                        .padding(.bottom, 6)
                        .foregroundColor(Color(hex: "#434343"))
                    
                    if (cascadingView.datasource.sortProperty != nil) {
                        Button(action:{ self.toggleAscending() }) {
                            Text(cascadingView.datasource.sortProperty ?? "")
                                .foregroundColor(Color(hex: "#6aa84f"))
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .padding(.vertical, 2)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            
                            // descending: "arrow.down"
                            Image(systemName: cascadingView.datasource.sortAscending == false
                                ? "arrow.down"
                                : "arrow.up")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color(hex: "#6aa84f"))
                                .frame(minWidth: 10, maxWidth: 10)
                        }
                        
                        Rectangle()
                            .frame(minHeight: 1, maxHeight: 1)
                            .foregroundColor(Color(hex: "#efefef"))
                    }
                    
                    ForEach(cascadingView.sortFields.filter {
                        return cascadingView.datasource.sortProperty != $0
                    }, id:\.self) { fieldName in
                        Group {
                            Button(action:{ self.changeOrderProperty(fieldName) }) {
                                Text(fieldName)
                                    .foregroundColor(Color(hex: "#434343"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .padding(.vertical, 2)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Rectangle()
                                .frame(minHeight: 1, maxHeight: 1)
                                .foregroundColor(Color(hex: "#efefef"))
                        }
                    }
                    
                    ForEach(allOtherFields(), id:\.self) { fieldName in
                        Group {
                            Button(action:{ self.changeOrderProperty(fieldName) }) {
                                Text(fieldName)
                                    .foregroundColor(Color(hex: "#434343"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .padding(.vertical, 2)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Rectangle()
                                .frame(minHeight: 1, maxHeight: 1)
                                .foregroundColor(Color(hex: "#efefef"))
                        }
                    }
                }
                .padding(.trailing, 30)
                .padding(.leading, 20)
            }
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
            .padding(.vertical, 1)
            .padding(.leading, 1)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight:0, maxHeight: 220, alignment: .topLeading)
        .background(Color(hex: "#eee"))
    }
}

struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
