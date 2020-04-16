//
//  GeneralEditorView.swift
//  memri
//
//  Created by Koen van der Veen on 14/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import RealmSwift

private extension View {
    func generalEditorCaption() -> some View {
        ModifiedContent(content: self, modifier: Caption())
    }
    
    func generalEditorHeader() -> some View {
        ModifiedContent(content: self, modifier: Header())
    }
}

private struct Caption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .light))
            .foregroundColor(Color(hex: "#333"))
    }
}

private struct Header: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 15, weight: .regular))
            .foregroundColor(Color(hex:"#434343"))
            .padding(.bottom, 3)
            .padding(.top, 24)
            .padding(.horizontal, 36)
            .foregroundColor(Color(hex: "#333"))
    }
}

struct _GeneralEditorView: View {
    @EnvironmentObject var main: Main
    var name: String="generalEditor"
    var item: DataItem? = nil
    let horizontalPadding = CGFloat(36)
    
    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs[name] as? GeneralEditorConfig ?? GeneralEditorConfig()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                if renderConfig.groups != nil{
                    ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
                        Section(header:Text("\(key)".uppercased()).generalEditorHeader()) {

                            ForEach(self.renderConfig.groups![key]!, id: \.self){ prop in
                                GeneralEditorRow(item: self.item!,
                                                 prop: prop,
                                                 horizontalPadding: self.horizontalPadding,
                                                 readOnly: self.renderConfig.readOnly.contains(prop))
                            }
                        }
                    }
                }

                Section(header:Text("OTHER").generalEditorHeader()) {
                    ForEach(getProperties(), id: \.self){prop in
                        GeneralEditorRow(item: self.item!,
                                         prop: prop,
                                         horizontalPadding: self.horizontalPadding,
                                         readOnly: self.renderConfig.readOnly.contains(prop))
                    }
                }
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
    }
    
//    extension View {
//        func myButtonStyle() -> some View {
//            Modified(content: self, modifier: MyButtonStyle())
//        }
//    }
    
//    @ViewBuilder
//    public var EditorRow: some View {
//
//    }
    
//    func item(for text: String) -> some View {
//        Text(text)
//            .padding(.all, 5)
//            .font(.body)
//            .background(Color.blue)
//            .foregroundColor(Color.white)
//            .cornerRadius(5)
//    }
    
//    Text("Text 1")
//    .modifier(StandardTitle())
    
    init(item: DataItem){
        self.item = item        
    }

    func getProperties() -> [String]{
        return item!.objectSchema.properties.filter {
            return !self.renderConfig.excluded.contains($0.name)
                && !self.renderConfig.allGroupValues().contains($0.name)
        }.map({$0.name})
    }
    
}

struct GeneralEditorRow: View {
    @EnvironmentObject var main: Main
    
    var item: DataItem? = nil
    var prop: String = ""
    var horizontalPadding: CGFloat = CGFloat(0)
    var readOnly: Bool = false
    
    @State var testing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4){
            Text(prop
                .camelCaseToWords()
                .lowercased()
                .capitalizingFirstLetter()
            )
            .foregroundColor(Color(hex: "#38761d"))
            .font(.system(size: 14, weight: .regular))
            .padding(.top, 10)
            
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
                    .generalEditorCaption()
                }
                else{
                    Text(self.item!.getString(self.prop))
                        .generalEditorCaption()
                }
            }
            else if self.item![prop] is Bool{
                VStack<Toggle<Text>> {
                    let binding = Binding<Bool>(
                        get: { self.item![self.prop] as! Bool },
                        set: { _ in
                            if self.main.currentSession.isEditMode == .active {
                                self.item!.toggle(self.prop)
                                self.main.objectWillChange.send()
                            }
                        }
                    )
                    
                    return Toggle(isOn: binding) {
                        Text(prop
                            .camelCaseToWords()
                            .lowercased()
                            .capitalizingFirstLetter())
                    }
                }
                .generalEditorCaption()
                
//                Button(action: {

//                }) {
//                    Image(systemName: self.item![prop]! as! Bool ? "checkmark.square" : "square")
//                        .font(Font.system(size: 24, weight: .semibold))
//                        .foregroundColor(Color(hex: "#333"))
//                        .padding(.bottom, 8)
//                }
            }
            else if self.item![prop] is Date {
                Text(self.item!.getString(prop))
                    .generalEditorCaption()
            }
            else if self.item![prop] is RealmSwift.List<Label>{
                WrappingHStack(self.item![prop] as! RealmSwift.List<Label>){ label in
                    VStack {
                        Text(label.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.white) // TODO color calculation
                            .padding(5)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 0, minHeight: 20, alignment: .center)
                    }
                    .background(Color(hex:label.color ?? "##fff"))
                    .cornerRadius(5)
                }
                .frame(minHeight: 72) // Huge hack
            }
            else{
                Text(prop
                  .camelCaseToWords()
                  .lowercased()
                  .capitalizingFirstLetter())
                    .generalEditorCaption()
            }
        }
        .fullWidth()
        .padding(.bottom, 10)
        .padding(.horizontal, self.horizontalPadding)
        .background(Color(UIColor.systemGreen).opacity(0.1))
        .border(Color(hex:"#efefef"), width: 1)
    }
}

//ForEach<Data, ID, Content> where Data : RandomAccessCollection, ID : Hashable {
//ForEach<Data, ID, Content> where Data : RandomAccessCollection, ID : Hashable
struct WrappingHStack<Content: View>:View { // , T: RandomAccessCollection , ID: Hashable
    
    let data: RealmSwift.List<Label>
    let content: (_ item:RealmSwift.List<Label>.Element) -> Content
    
    init(_ data:RealmSwift.List<Label>, @ViewBuilder content: @escaping (_ item:RealmSwift.List<Label>.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.data, id: \.id) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width)
                        {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.data.last! {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if item == self.data.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
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
//
//var body: some View {
//        VStack{
//            if self.item != nil{
//                ScrollView{
//                    VStack(alignment: .leading){
//
//                        if renderConfig.groups != nil{
//                            ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
//                                VStack(alignment: .leading){
//
//                                    HStack{
//                                        Text("\(key)".uppercased())
//                                            .font(Font.system(size: 15, weight: .regular))
//                                            .foregroundColor(Color(hex:"#434343"))
//                                            .padding(.bottom, 3)
//                                    }.padding(.top, 24)
//                                     .padding(.horizontal, self.horizontalPadding)
//                                     .foregroundColor(Color(hex: "#333"))
//
//                                    ForEach(self.renderConfig.groups![key]!, id: \.self){ prop in
//                                        GeneralEditorRow(item: self.item!,
//                                                         prop: prop,
//                                                         horizontalPadding: self.horizontalPadding,
//                                                         readOnly: self.renderConfig.readOnly.contains(prop))
//                                    }
//
//                                }
//                            }
//                        }
//                        HStack(){
//                            Text("OTHER")
//                                .font(Font.system(size: 15, weight: .regular))
//                                .foregroundColor(Color(hex:"#434343"))
//                                .padding(.bottom, 3)
//                        }.padding(.top, 24)
//                         .padding(.horizontal, self.horizontalPadding)
//                         .foregroundColor(Color(hex: "#333"))
//                        ForEach(getProperties(), id: \.self){prop in
//                            VStack(alignment: .leading){
//
//                                if !self.renderConfig.excluded.contains(prop) && !self.renderConfig.allGroupValues().contains(prop){
//
//
//                                        GeneralEditorRow(item: self.item!,
//                                                         prop: prop,
//                                                         horizontalPadding: self.horizontalPadding,
//                                                         readOnly: self.renderConfig.readOnly.contains(prop))
//                                }
//
//                            }
//                        }
//                    }
//                }
//            } else{
//                EmptyView()
//            }
//        }
//    }
//
//    init(item: DataItem){
//        self.item = item
//    }
//
//    func getProperties() -> [String]{
//        let properties = item!.objectSchema.properties
//        return properties.map({$0.name})
//    }
//
//}
