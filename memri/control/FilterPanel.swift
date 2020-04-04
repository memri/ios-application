//
//  FIlterpannel.swift
//  memri
//
//  Created by Koen van der Veen on 25/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct FilterPanel: View {
    @EnvironmentObject var main: Main
    @State var showFilters=false

    
    @State var sorters = [SortButton(name: "Select property", selected: false),
                          SortButton(name: "Date modified", selected: false),
                          SortButton(name: "Date accessed", selected: false),
                          SortButton(name: "Date created", selected: true)]

    @State var browseSettings = [BrowseSetting(name: "Default", selected: true),
                                BrowseSetting(name: "Browse by type", selected: false),
                                BrowseSetting(name: "Browse by folder", selected: false),
                                BrowseSetting(name: "Year-Month-Day view", selected: false)]

 
    
    var body: some View {
        VStack{
            if self.main.currentSession.showFilterPanel {
                HStack(){
                    VStack(alignment: .leading){
                        HStack(alignment: .bottom){
                            HStack(alignment: .top) {
                                ForEach(self.main.renderObjectTuples, id: \.0) { index, item in
                                    Group{
                                        if item.canDisplayResultSet(items: self.main.computedView.resultSet.items){
                                            Action(action: item)
                                        }
                                    }
                                }
                            }
                        }.offset(x: 4)
                        
                        VStack(alignment: .leading){
                            ForEach(self.browseSettings) { browseSetting in
                                Text(browseSetting.name)
                                    .foregroundColor(browseSetting.color)
                                    .fontWeight(browseSetting.fontWeight)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 10)
                            }
                        }
                        
                    }.padding(.horizontal , 20)
                        .frame(minWidth: 0, maxWidth: .infinity,alignment: Alignment.topLeading)
                    
                    VStack(alignment: .leading){
                        Text("SORT")
                            .font(.headline)
                            .padding(.vertical, 6)
                        
                        ForEach(self.sorters) { sorter in
                            Text(sorter.name)
                                .foregroundColor(sorter.color)
                                .fontWeight(sorter.fontWeight)
                                .padding(.vertical, 10)
                        }
                        
                    }.padding(.horizontal, 20)
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.topLeading)
                    .padding(.vertical, 10)
            }else{
                EmptyView()
            }
        }

    }
    init(){
        // TODO: move to list
        UITableView.appearance().separatorColor = .clear
    }
}


struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
