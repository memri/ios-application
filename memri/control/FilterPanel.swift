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

    
    @State var sorters = [SortButton(name: "Date created", selected: true),
                          SortButton(name: "Date modified", selected: false),
                          SortButton(name: "Date accessed", selected: false),
                          SortButton(name: "Select property...", selected: false)]

    @State var browseSettings = [BrowseSetting(name: "Default", selected: true),
                                 BrowseSetting(name: "Browse by type", selected: false),
                                 BrowseSetting(name: "Browse by folder", selected: false),
                                 BrowseSetting(name: "Year-Month-Day view", selected: false)]
    
    init(){
        // TODO: move to list
        UITableView.appearance().separatorColor = .clear
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0){
            VStack(alignment: .leading, spacing: 0){
                HStack(alignment: .top, spacing: 3) {
                    ForEach(self.main.renderers.tuples.filter{(key, item) -> Bool in
                        return item.canDisplayResultSet(items: self.main.items)
                    }, id: \.0) { index, item in
                        Action(action: item)
                            .frame(width: 35, height: 35, alignment: .center)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
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
            
            VStack(alignment: .leading){
                Text("ORDER ON:")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 15)
                    .padding(.bottom, 6)
                    .foregroundColor(Color(hex: "#434343"))
                
                ForEach(self.sorters) { sorter in
                    Group {
                        if (sorter.selected) {
                            HStack {
                                Text(sorter.name)
                                    .foregroundColor(sorter.color)
                                    .fontWeight(sorter.fontWeight)
                                    .padding(.vertical, 10)
                                
                                // descending: "arrow.down"
                                Image(systemName: "arrow.up")
                                    .foregroundColor(Color(hex: "#6aa84f"))
                            
                            }
                            .padding(.vertical, -8)
                        }
                        else {
                            Text(sorter.name)
                                .foregroundColor(sorter.color)
                                .fontWeight(sorter.fontWeight)
                                .padding(.vertical, 10)
                        }
                    }
                }
                
            }
            .padding(.trailing, 30)
            .padding(.leading, 20)
            .frame(minHeight: 0, maxHeight: .infinity, alignment: Alignment.top)
            .background(Color.white)
            .padding(.vertical, 1)
            .padding(.leading, 1)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight:0, maxHeight: 215, alignment: .topLeading)
        .background(Color(hex: "#eee"))
    }
}


struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
