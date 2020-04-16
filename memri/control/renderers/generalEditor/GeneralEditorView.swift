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
    var name: String="generalEditor"
    var item: DataItem? = nil
    let horizontalPadding = CGFloat(36)
    

    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs[name] as? GeneralEditorConfig ?? GeneralEditorConfig()
    }

    
    var body: some View {
        
        return VStack{
            if self.item != nil{
                ScrollView{
                    VStack(alignment: .leading){
                        if renderConfig.groups != nil{
                            ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
                                VStack(alignment: .leading){

                                    HStack{
                                        Text("\(key)".uppercased())
                                            .font(Font.system(size: 18, weight: .medium))
                                    }.padding(.top, 24)
                                     .padding(.horizontal, self.horizontalPadding)
                                     .foregroundColor(Color(hex: "#333"))
                                    
                                    ForEach(self.renderConfig.groups![key]!, id: \.self){ prop in
                                        GeneralEditorRow(item: self.item!,
                                                         prop: prop,
                                                         horizontalPadding: self.horizontalPadding,
                                                         readOnly: self.renderConfig.readOnly.contains(prop))
                                    }
                                    
                                }
                            }
                        }
                        HStack(){
                            Text("MISC")
                                .font(Font.system(size: 18, weight: .medium))
                        }.padding(.top, 24)
                         .padding(.horizontal, self.horizontalPadding)
                         .foregroundColor(Color(hex: "#333"))
                        ForEach(getProperties(), id: \.self){prop in
                            VStack(alignment: .leading){
                                
                                if !self.renderConfig.excluded.contains(prop) && !self.renderConfig.allGroupValues().contains(prop){


                                        GeneralEditorRow(item: self.item!,
                                                         prop: prop,
                                                         horizontalPadding: self.horizontalPadding,
                                                         readOnly: self.renderConfig.readOnly.contains(prop))
                                }

                            }
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
