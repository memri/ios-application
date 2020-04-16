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
                                 BrowseSetting(name: "Browse by type", selected: false),
                                 BrowseSetting(name: "Browse by folder", selected: false),
                                 BrowseSetting(name: "Year-Month-Day view", selected: false)]
    
    private func allOtherFields() -> [String] {
        var list:[String] = []
        
        if let item = self.main.computedView.resultSet.items.first {
            var excludeList = self.main.computedView.sortFields
            excludeList.append(self.main.computedView.queryOptions.sortProperty ?? "")
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
                = !(self.main.computedView.queryOptions.sortAscending.value ?? true)
        }
        self.main.scheduleComputeView()
    }
    private func changeOrderProperty(_ fieldName:String) {
        try! self.main.realm.write {
            self.main.currentSession.currentView.queryOptions?.sortProperty = fieldName
        }
        self.main.scheduleComputeView()
    }
    
    private func isActive(_ renderer:Renderer) -> Bool {
        return self.main.computedView.rendererName == renderer.name
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0){
            VStack(alignment: .leading, spacing: 0){
                HStack(alignment: .top, spacing: 3) {
                    ForEach(self.main.renderers.tuples.filter{(key, renderer) -> Bool in
                        return renderer.canDisplayResultSet(items: self.main.items)
                    }, id: \.0) { (index, renderer:Renderer) in
                        
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

                VStack(alignment: .leading, spacing: 0){
                    ForEach(self.browseSettings) { browseSetting in
                        Group {
                            Text(browseSetting.name)
                                .foregroundColor(browseSetting.color)
                                .fontWeight(browseSetting.fontWeight)
                                .font(.system(size: 16))
                                .padding(.vertical, 12)
                            Rectangle()
                                .frame(minHeight: 1, maxHeight: 1)
                                .foregroundColor(Color(hex: "#efefef"))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .background(Color.white)
                .padding(.top, 1)
            }
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
            ScrollView {
                VStack (alignment: .leading) {
                    Text("SORT ON:")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 15)
                        .padding(.bottom, 6)
                        .foregroundColor(Color(hex: "#434343"))
                    
                    if (self.main.computedView.queryOptions.sortProperty != nil) {
                        Button(action:{ self.toggleAscending() }) {
                            Text(self.main.computedView.queryOptions.sortProperty!)
                                .foregroundColor(Color(hex: "#6aa84f"))
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.top, -12)
                                .padding(.bottom, -8)
                            
                            // descending: "arrow.down"
                            Image(systemName: self.main.computedView.queryOptions.sortAscending.value == false
                                ? "arrow.down"
                                : "arrow.up")
                                .foregroundColor(Color(hex: "#6aa84f"))
                        }
                    }
                    
                    ForEach(self.main.computedView.sortFields.filter {
                        return self.main.computedView.queryOptions.sortProperty != $0
                    }, id:\.self) { fieldName in
                        Button(action:{ self.changeOrderProperty(fieldName) }) {
                            Text(fieldName)
                                .foregroundColor(Color(hex: "#434343"))
                                .fontWeight(.regular)
                                .padding(.vertical, 8)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Divider()
                    
                    ForEach(allOtherFields(), id:\.self) { fieldName in
                        Button(action:{ self.changeOrderProperty(fieldName) }) {
                            Text(fieldName)
                                .foregroundColor(Color(hex: "#434343"))
                                .fontWeight(.regular)
                                .padding(.vertical, 8)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
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
        FilterPanel().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
