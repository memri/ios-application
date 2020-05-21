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
            excludeList.append(self.main.cascadingView.queryOptions.sortProperty ?? "")
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
        try! self.main.realm.write {
            self.main.currentSession.currentView.queryOptions?.sortAscending.value
                = !(self.main.cascadingView.queryOptions.sortAscending.value ?? true)
        }
        self.main.scheduleComputeView()
    }
    
    private func changeOrderProperty(_ fieldName:String) {
        try! self.main.realm.write {
            self.main.currentSession.currentView.queryOptions?.sortProperty = fieldName
        }
        self.main.scheduleComputeView()
    }
    
    private func rendererCategories() -> [(String, Renderer)] {
        return self.main.renderers.tuples.filter{(key, renderer) -> Bool in
            return !key.contains(".") && renderer.canDisplayResultSet(items: self.main.items)
        }
    }
    
    private func renderersAvailable() -> [(String, Renderer)] {
        if let currentCategory = self.main.cascadingView.rendererName.split(separator: ".").first {
            return self.main.renderers.all.filter { (key, renderer) -> Bool in
                return renderer.name.split(separator: ".").first == currentCategory
            }.sorted(by: { $0.1.order < $1.1.order })
        }
        return []
    }
    
    private func isActive(_ renderer:Renderer) -> Bool {
        return self.main.cascadingView.rendererName.split(separator: ".").first! == renderer.name
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0){
            VStack(alignment: .leading, spacing: 0){
                HStack(alignment: .top, spacing: 3) {
                    ForEach(rendererCategories(), id: \.0) { (key, renderer:Renderer) in
                        
                        Button(action: {self.main.executeAction(renderer)} ) {
                            Image(systemName: renderer.icon)
                                .fixedSize()
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(Color(self.isActive(renderer)
                                    ? renderer.activeColor!
                                    : renderer.inactiveColor!))
                                .background(Color(self.isActive(renderer)
                                    ? renderer.activeBackgroundColor!
                                    : renderer.inactiveBackgroundColor!))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .background(Color.white)
                .padding(.top, 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0){
                        ForEach(renderersAvailable(), id:\.0) { (key, renderer:Renderer) in
                            Group {
                                Button(action:{ self.main.executeAction(renderer) }) {
                                    if self.main.cascadingView.rendererName == renderer.name {
                                        Text(renderer.title ?? "Unnamed Renderer")
                                            .foregroundColor(Color(hex: "#6aa84f"))
                                            .fontWeight(.semibold)
                                            .font(.system(size: 16))
                                            .padding(.vertical, 12)
                                    }
                                    else {
                                        Text(renderer.title ?? "Unnamed Renderer")
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
                    
                    if (self.main.cascadingView.queryOptions.sortProperty != nil) {
                        Button(action:{ self.toggleAscending() }) {
                            Text(self.main.cascadingView.queryOptions.sortProperty!)
                                .foregroundColor(Color(hex: "#6aa84f"))
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .padding(.vertical, 2)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            
                            // descending: "arrow.down"
                            Image(systemName: self.main.cascadingView.queryOptions.sortAscending.value == false
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
                    
                    ForEach(self.main.cascadingView.sortFields.filter {
                        return self.main.cascadingView.queryOptions.sortProperty != $0
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
