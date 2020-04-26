//
//  PickerPane.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct Picker: View {
    @EnvironmentObject var main: Main
    
    let item: DataItem
    let selected: DataItem?
    let title: String
    let emptyValue: String
    let propName: String
    let queryOptions: QueryOptions
    
    @State var isShowing = false
    
    var body: some View {
        return Button (action:{
            self.isShowing.toggle()
        }) {
            HStack {
                Text(title)
                    .generalEditorCaption()
                    .lineLimit(1)
                Spacer()
                Image (systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.gray)
            }
        }
        .sheet(isPresented: $isShowing) {
            PickerPane(
                item: self.item,
                title: self.emptyValue,
                propName: self.propName,
                selected: self.selected,
                queryOptions: self.queryOptions
            ).environmentObject(self.main)
        }
        .generalEditorInput()
    }
}

struct PickerPane: View {
    @EnvironmentObject var main: Main
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let item: DataItem
    let title: String
    let propName: String
    let selected: DataItem?
    let queryOptions: QueryOptions
    
    var body: some View {
        let dataItems = try! self.main.cache.query(queryOptions) // TODO refactor: error handlings
        
        // TODO scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
        return NavigationView {
            SwiftUI.List{
                ForEach(dataItems, id:\.id) { dataItem in
                    VStack (alignment: .leading, spacing:0) {
                        Button(action:{
                            try! self.main.realm.write {
                                self.item[self.propName] = dataItem
                            }
                            self.main.scheduleUIUpdate{_ in true}
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                if self.selected == dataItem {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.blue)
                                }
                                Text(dataItem.computeTitle)
                                    .padding(10)
                            }
                        }
                        .padding(.leading, self.selected == dataItem ? 5 : 20)
                        .fullWidth()
                        
                        Rectangle()
                            .frame(minHeight:1, maxHeight: 1)
                            .foregroundColor(Color(hex:"#efefef"))
                            .padding(.leading, 20)
                            .offset(x: 0, y: 2)
                    }
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: 20,
                        bottom: 0,
                        trailing: 0))
                }
            }
            .navigationBarItems(leading:
                Button(action:{ self.presentationMode.wrappedValue.dismiss() }) {
                    Text("close")
                })
            .navigationBarTitle(Text(title), displayMode: .inline)
        }
    }
}
