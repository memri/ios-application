//
//  FIlterpannel.swift
//  memri
//
//  Created by Koen van der Veen on 25/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct SortButton: Identifiable {
    var id = UUID()
    var name: String
    var selected: Bool
    var color: Color {self.selected ? Color(hex: "#6aa84f") : Color(hex: "#434343")}
    var fontWeight: Font.Weight? {self.selected ? .semibold : .regular}
}

struct BrowseSetting: Identifiable {
    var id = UUID()
    var name: String
    var selected: Bool
    var color: Color {self.selected ? Color(hex: "#6aa84f") : Color(hex: "#434343")}
    var fontWeight: Font.Weight? {self.selected ? .semibold : .regular}
}

struct FilterPanel: View {
    @EnvironmentObject var main: Main
    @State var showFilters = false

    
    @State var browseSettings = [BrowseSetting(name: "Default", selected: true),
                                 BrowseSetting(name: "Browse by type", selected: false),
                                 BrowseSetting(name: "Browse by folder", selected: false),
                                 BrowseSetting(name: "Year-Month-Day view", selected: false)]
    
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
                    
                    ForEach(self.main.computedView.sortFields, id:\.self) { fieldName in
                        Button(action:{}) {
                            if (self.main.computedView.queryOptions.sortProperty == fieldName) {
                                Text(fieldName)
                                    .foregroundColor(Color(hex: "#6aa84f"))
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                
                                // descending: "arrow.down"
//                                Image(systemName: "arrow.up")
//                                    .foregroundColor(Color(hex: "#6aa84f"))
//                                    .padding(.vertical, 0)
                            }
                            else {
                                Text(fieldName)
                                    .foregroundColor(Color(hex: "#434343"))
                                    .fontWeight(.regular)
                                    .padding(.vertical, 10)
                            }
                        }
                        .border(Color.red, width: 1)
                    }
                    Text("Select property...")
                        .foregroundColor(Color(hex: "#434343"))
                        .fontWeight(.regular)
                        .padding(.vertical, 10)
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
