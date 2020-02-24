//
//  Search.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct Search: View {
    @State var searchText=""
    @State var showFilters=false
    @State var sorters = [SortButton(name: "Select property", selected: false),
                          SortButton(name: "Date modified", selected: false),
                          SortButton(name: "Date accessed", selected: false),
                          SortButton(name: "Date created", selected: true)]

    @State var browseSettings = [BrowseSetting(name: "Default", selected: true),
                                BrowseSetting(name: "Browse by type", selected: false),
                                BrowseSetting(name: "Browse by folder", selected: false),
                                BrowseSetting(name: "Year-Month-Day view", selected: false)]

    @State var viewTypeButtons = [ViewTypeButton(imgName: "line.horizontal.3", selected:                                   true),
                                  ViewTypeButton(imgName: "square.grid.3x2.fill", selected: false),
                                  ViewTypeButton(imgName: "calendar", selected: false),
                                  ViewTypeButton(imgName: "location.fill", selected: false),
                                  ViewTypeButton(imgName: "chart.bar.fill", selected: false)]



    var body: some View {
        VStack{
            HStack{
                TextField("type your search query here", text: $searchText)
                    .onTapGesture {
                        print("abc")
                        self.showFilters=true
                }
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "star.fill")
                }.padding(.horizontal , 5)
                 .font(Font.system(size: 20, weight: .medium))
                 .foregroundColor(.gray)


                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "chevron.down")
                }.padding(.horizontal , 5)
                 .font(Font.system(size: 20, weight: .medium))
                 .foregroundColor(.gray)

            }.padding(.horizontal , 15)

            HStack(alignment: .top){
                VStack(alignment: .leading){
                    HStack(alignment: .bottom){
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(self.viewTypeButtons) { viewTypeButton in
                                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                                    Image(systemName: viewTypeButton.imgName)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 6)
                                .background(viewTypeButton.backGroundColor)
                                .foregroundColor(viewTypeButton.foreGroundColor)
                                
                            }
                        }
                    }
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
                    Text("SORT").font(.headline)                                .padding(.vertical, 6)

                    ForEach(self.sorters) { sorter in
                        Text(sorter.name)
                            .foregroundColor(sorter.color)
                            .fontWeight(sorter.fontWeight)
                            .padding(.vertical, 10)

                    }

                }.padding(.horizontal, 20)
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.topLeading)
                .padding(.vertical, 10)
        }
    }

    init(){
        // THIS HIDEN THE LIST LINES
        UITableView.appearance().separatorColor = .clear
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search()
    }
}
