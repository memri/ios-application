//
//  GeneralEditorView.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

struct GeneralEditorView: View {
    @EnvironmentObject var main: Main
    var name: String="thumbnail"
    
    var item: DataItem? {
        if main.computedView.resultSet.item != nil{
            return main.computedView.resultSet.item
        }else{
//            self.main.objectWillChange.send()
            return main.computedView.resultSet.item
        }
    }
    

    
    var body: some View {
        VStack{
            if self.item != nil{
                ScrollView{
                    ForEach(getProperties(), id: \.self){prop in
                        VStack(alignment: .leading){
                            HStack{
                                Text("GROUP NAME")
                                    .font(Font.system(size: 18, weight: .medium))
                            }.padding(.top, 24)
                             .padding(.bottom, 6)
                             .padding(.horizontal, 36)
                             .foregroundColor(Color(hex: "#333"))

                            VStack(alignment: .leading, spacing: 12){
                                Text(prop.camelCaseToWords().lowercased().capitalizingFirstLetter())
                                    .foregroundColor(Color(red: 0.21, green: 0.46, blue: 0.11))
                                    .offset(y: 8)
                                    .padding(.bottom, 8)
                                if self.item![prop] is String {
//                                    TextField("abc",
//                                              $main.computedView.resultSet.item!.uid!)

//                                    TextField(text: )
                                    Text(self.item!.getString(prop))
                                        .padding(.bottom, 8)
                                        .font(Font.system(size: 18, weight: .medium))
                                        .foregroundColor(Color(hex: "#333"))
                                }
                                else if self.item![prop] is Bool{
                                    Button(action: {
                                        self.item!.toggle(prop)
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
                                        .font(Font.system(size: 18, weight: .medium))
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
                                }.fullWidth()
                                .padding(.horizontal, 36)
                                .background(Color(UIColor.systemGreen).opacity(0.1))
                                .border(Color(UIColor.systemGray).opacity(0.2), width: 1)

                        }
                    }
                }
            } else{
                EmptyView()
            }
        }
    }
    
    
    func getProperties() -> [String]{
        let properties = item!.objectSchema.properties
        return properties.map({$0.name})
    }
    
}

struct GeneralEditorView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralEditorView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
