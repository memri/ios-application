//
//  GeneralEditorView.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

struct _GeneralEditorView: View {
    @EnvironmentObject var main: Main
    var name: String="thumbnail"
    var item: DataItem? = nil
//    @State var stringProp: String = ""
    @State var stringVals: [String] = []
    
    let horizontalPadding = CGFloat(36)
    

    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs[name] as? GeneralEditorConfig ?? GeneralEditorConfig()
    }

    
    var body: some View {
//        for i in 0..<stringVals.count{
//            let binding = Binding<String>(
//                get: { self.stringVals },
//                set: { self.stringVals = $0}
//            )
//        }
        
        return VStack{
            if self.item != nil{
                ScrollView{
                    if renderConfig.groups != nil{
                        ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
                            Text("ABC")
                        }
                    }
                    
                    ForEach(getProperties(), id: \.self){prop in
                        VStack(alignment: .leading){
                            
                            HStack{
                                Text("GROUP NAME")
                                    .font(Font.system(size: 18, weight: .medium))
                            }.padding(.top, 24)
//                             .padding(.bottom, 2)
                             .padding(.horizontal, self.horizontalPadding)
                             .foregroundColor(Color(hex: "#333"))

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
                                    VStack<TextField<Text>> {
                                        let binding = Binding<String>(
                                            get: { self.item!.getString(prop) },
                                            set: {
                                                if self.main.currentSession.isEditMode == .active {
                                                self.item!.set(prop, $0)
                                                }
                                            }
                                        )
                                        return TextField("", text: binding)
                                    }
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
                                .padding(.horizontal, self.horizontalPadding)
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
    
    init(item: DataItem){
        self.item = item
        var vals = getProperties().filter{prop in item[prop] is String}.map{prop in item[prop] as! String}
        
        _stringVals = State(initialValue: vals)
//        print(self.stringVals)
//        self.stringProps = getProperties().compactMap{prop in item[prop] as? String ?? nil}
        
//            {item[$0]}.filter{$0 is String}
        
        
//        self.stringProps = item.objectSchema.properties.map({$0.name})
//        self.item =
//        self.stringProp = "ABC"
    }

    func getProperties() -> [String]{
        let properties = item!.objectSchema.properties
        return properties.map({$0.name})
    }
    
}

struct GeneralEditorView: View {
    @EnvironmentObject var main: Main
    var body: some View {
        _GeneralEditorView(item: main.computedView.resultSet.item!)
    }

    
}

struct GeneralEditorView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralEditorView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
