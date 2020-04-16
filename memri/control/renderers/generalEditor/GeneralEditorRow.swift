//
//  GeneralEditorRow.swift
//  memri
//
//  Created by Koen van der Veen on 16/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift


struct GeneralEditorRow: View {
    
    @EnvironmentObject var main: Main
    var item: DataItem? = nil
    var prop: String = ""
    var horizontalPadding: CGFloat = CGFloat(0)
    var readOnly: Bool = false


    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Text(prop
                .camelCaseToWords()
                .lowercased()
                .capitalizingFirstLetter()
            )
                .foregroundColor(Color(red: 0.21, green: 0.46, blue: 0.11))
                .offset(y: 8)
                .padding(.bottom, 8)
            if self.item![prop] is String {
                if !self.readOnly{
                    VStack<TextField<Text>> {
                        let binding = Binding<String>(
                            get: { self.item!.getString(self.prop) },
                            set: {
                                if self.main.currentSession.isEditMode == .active {
                                    self.item!.set(self.prop, $0)
                                }
                        }
                        )
                        return TextField("", text: binding)
                    }
                }else{
                    Text(self.item!.getString(self.prop))
                }
                
            }
            else if self.item![prop] is Bool{
                Button(action: {
                    self.item!.toggle(self.prop)
                    self.main.objectWillChange.send()
                }) {
                    Image(systemName: self.item![prop]! as! Bool ? "checkmark.square" : "square")
                        .font(Font.system(size: 24, weight: .semibold))
                        .padding(.bottom, 8)
                        .foregroundColor(Color(hex: "#333"))
                    
                }
            }
            else if self.item![prop] is Date {
                Text(self.item!.getString(prop))
                    .padding(.bottom, 8)
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#333"))
            }
            else if self.item![prop] is RealmSwift.List<Label>{
                ForEach(self.item![prop] as! RealmSwift.List<Label>){ label in
                    Text(label.name)
                        .padding(.bottom, 8)
                }
            }else{
                Text(prop.camelCaseToWords().lowercased().capitalizingFirstLetter())
                    .padding(.bottom, 8)
                    .foregroundColor(Color(UIColor.systemGray))
            }
            }
        .fullWidth()
        .padding(.horizontal, self.horizontalPadding)
        .background(Color(UIColor.systemGreen).opacity(0.1))
        .border(Color(UIColor.systemGray).opacity(0.2), width: 1)
        }
}


struct GeneralEditorRow_Previews: PreviewProvider {
    static var previews: some View {
        GeneralEditorRow()
    }
}
