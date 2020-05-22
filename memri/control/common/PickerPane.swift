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
                Text(selected?.computedTitle ?? emptyValue)
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
                title: self.title,
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
        self.main.closeStack.append {
            self.presentationMode.wrappedValue.dismiss()
        }
        
        // TODO scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
        return SubView(
            main: self.main,
            view: SessionView(value: [
                "queryOptions": queryOptions,
                "title": title,
                "userState": UserState([
                    "selection": ["type": self.item.genericType, "uid": self.item.uid]
                ]),
                // "editMode": true // TODO REfactor: also allow edit mode toggle on session view
                // TODO REfactor: allow only 1 or more selected items
                "renderDescriptions": [
                    ViewRendererDefinition(#"[renderer = "list"]"#,
                        parsed: ["press": [
                            Action("setProperty", [self.item, self.propName]),
                            Action("closePopup")
                        ]]
                    ),
                    ViewRendererDefinition(#"[renderer = "thumbnail"]"#,
                        parsed: ["press": [
                            Action("setProperty", [self.item, self.propName]),
                            Action("closePopup")
                        ]]
                    )
                ]
            ]),
            dataItem: self.item,
            args: ViewArguments(["showCloseButton": true])
        )
    }
}
