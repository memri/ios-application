//
//  PickerPane.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct Picker: View {
    @EnvironmentObject var context: MemriContext
    
    let item: DataItem
    let selected: DataItem?
    let title: String
    let emptyValue: String
    let propDataItem: DataItem
    let propName: String
    let datasource: Datasource
    
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
                propDataItem: self.propDataItem,
                propName: self.propName,
                selected: self.selected,
                datasource: self.datasource
            ).environmentObject(self.context)
        }
        .generalEditorInput()
    }
}

struct PickerPane: View {
    @EnvironmentObject var context: MemriContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let item: DataItem
    let title: String
    let propDataItem: DataItem
    let propName: String
    let selected: DataItem?
    let datasource: Datasource
    
    var body: some View {
        self.context.closeStack.append {
            self.presentationMode.wrappedValue.dismiss()
        }
        
        // TODO scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
        return SubView(
            context: self.context,
            view: SessionView(value: [
                "datasource": datasource,
                "userState": UserState([
                    "selection": [["type": item.genericType, "memriID": item.memriID]]
                ]),
                // "editMode": true // TODO REfactor: also allow edit mode toggle on session view
                // TODO REfactor: allow only 1 or more selected items
                "viewDefinition": CVUStoredDefinition(value: ["definition": """
                    [view] {
                        title: "\(title)"
                        
                        [renderer = list] {
                            press: [
                                setProperty {
                                    arguments {
                                        subject: {{subject}}
                                        property: \(propName)
                                    }
                                }
                                closePopup
                            ]
                        }
                        
                        [renderer = thumbnail] {
                            press: [
                                setProperty {
                                    arguments {
                                        subject: {{subject}}
                                        property: \(propName)
                                    }
                                }
                                closePopup
                            ]
                        }
                    }
                """])
            ]),
            dataItem: self.item,
            args: ViewArguments(["showCloseButton": true, "subject": propDataItem])
        )
    }
}
