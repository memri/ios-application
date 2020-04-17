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
    
    var name: String = "generalEditor"
    var item: DataItem? = nil
    
    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs.generalEditor ?? GeneralEditorConfig()
    }
    
    var body: some View {
        let item = main.computedView.resultSet.item!
        
        return ScrollView {
            VStack(alignment: .leading, spacing:0){
                if renderConfig.groups != nil{
                    ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
                        self.drawSection(
                            header: "\(key)".uppercased(),
                            item: item,
                            properties: self.renderConfig.groups![key]!)
                    }
                }

                drawSection(
                    header: "OTHER",
                    item: item,
                    properties: getProperties(item))
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
    }
    
    func drawSection(header: String, item:DataItem, properties: [String]) -> some View {
        Section(header:Text(header).generalEditorHeader()) {
            Divider()
            ForEach(properties, id: \.self){ prop in
                GeneralEditorRow(item: item,
                                 prop: prop,
                                 readOnly: self.renderConfig.readOnly.contains(prop),
                                 isLast: properties.last == prop)
            }
            Divider()
        }
    }
    
    func getProperties(_ item:DataItem) -> [String]{
        return item.objectSchema.properties.filter {
            return !self.renderConfig.excluded.contains($0.name)
                && !self.renderConfig.allGroupValues().contains($0.name)
        }.map({$0.name})
    }
    
}

struct GeneralEditorRow: View {
    @EnvironmentObject var main: Main
    
    var item: DataItem? = nil
    var prop: String = ""
    var readOnly: Bool = false
    var isLast: Bool = false
    
    @State var testing: Bool = false

    var body: some View {
        // Get the type from the schema, because when the value is nil the type cannot be determined
        let propType = item!.objectSchema[prop]?.type

        return VStack (spacing: 0) {
            VStack(alignment: .leading, spacing: 4){
                Text(prop
                    .camelCaseToWords()
                    .lowercased()
                    .capitalizingFirstLetter()
                )
                .generalEditorLabel()
                
                if self.readOnly {
                    if propType == PropertyType.string
                      || propType == PropertyType.bool
                      || propType == PropertyType.date
                      || propType == PropertyType.int
                      || propType == PropertyType.double {
                        defaultRow(self.item!.getString(self.prop))
                    }
                    else if propType == PropertyType.object { listLabelRow }
                    else { defaultRow() }
                }
                else {
                    if propType == PropertyType.string { stringRow() }
                    else if propType == PropertyType.bool { boolRow() }
                    else if propType == PropertyType.date { dateRow }
                    else if propType == PropertyType.int { intRow() }
                    else if propType == PropertyType.double { doubleRow() }
                    else if prop == "labels" && propType == PropertyType.object { listLabelRow }
                    else { defaultRow() }
                }
            }
            .fullWidth()
            .padding(.bottom, 10)
            .padding(.horizontal, 36)
            .background(readOnly ? Color(hex:"#f9f9f9") : Color(hex:"#f7fcf5"))
            
            if !isLast {
                Divider().padding(.leading, 35)
            }
        }
    }
    
    func stringRow() -> some View {
        let binding = Binding<String>(
            get: { self.item!.getString(self.prop) },
            set: {
                if self.main.currentSession.isEditMode == .active {
                    self.item!.set(self.prop, $0)
                }
            }
        )
        
        return TextField("", text: binding)
            .generalEditorCaption()
    }
    
    func boolRow() -> some View {
        let binding = Binding<Bool>(
            get: { self.item![self.prop] as? Bool ?? false },
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
        .toggleStyle(GeneralEditorToggleStyle())
        .generalEditorCaption()
    }
    
    func intRow() -> some View {
        let binding = Binding<Int>(
            get: { self.item![self.prop] as? Int ?? 0 },
            set: {
                if self.main.currentSession.isEditMode == .active {
                    self.item!.set(self.prop, $0)
                    self.main.objectWillChange.send()
                }
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    func doubleRow() -> some View {
        let binding = Binding<Double>(
            get: { self.item![self.prop] as? Double ?? 0 },
            set: {
                if self.main.currentSession.isEditMode == .active {
                    self.item!.set(self.prop, $0)
                    self.main.objectWillChange.send()
                }
            }
        )
        
        return TextField("", value: binding, formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .generalEditorCaption()
    }
    
    var dateRow: some View {
        Text(self.item!.getString(prop))
            .generalEditorCaption()
    }
    
    func defaultRow(_ caption:String? = nil) -> some View {
        Text(caption ?? (prop.camelCaseToWords().lowercased().capitalizingFirstLetter()))
              .generalEditorCaption()
    }
    
    var listLabelRow: some View {
        return WrappingHStack(self.item![prop] as! RealmSwift.List<Label>){ label in
           VStack {
               Text(label.name)
                   .font(.system(size: 16, weight: .semibold))
                   .foregroundColor(Color.white) // TODO color calculation
                   .padding(5)
                   .padding(.horizontal, 8)
           }
           .background(Color(hex:label.color ?? "##fff"))
           .cornerRadius(5)
       }
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
        var width = CGFloat.zero
        var height = CGFloat.zero

        // TODO I cant get Geometry reader to work without collapsing the row
//                    GeometryReader { geometry in
        return ZStack(alignment: .topLeading) {
            ForEach(self.data, id: \.id) { item in
                self.content(item)
                    .padding([.trailing, .bottom], 5)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > 360) {
                            width = 0
                            height -= d.height
                        }
                        
                        let result = width
                        if item == self.data.last! {
                            width = 0 //last item
                        }
                        else {
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

private extension View {
    func generalEditorLabel() -> some View { self.modifier(GeneralEditorLabel()) }
    func generalEditorCaption() -> some View { self.modifier(GeneralEditorCaption()) }
    func generalEditorHeader() -> some View { self.modifier(GeneralEditorHeader()) }
}

private struct GeneralEditorLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(hex: "#38761d"))
            .font(.system(size: 14, weight: .regular))
            .padding(.top, 10)
    }
}

private struct GeneralEditorCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(Color(hex: "#223322"))
    }
}

private struct GeneralEditorHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 15, weight: .regular))
            .foregroundColor(Color(hex:"#434343"))
            .padding(.bottom, 5)
            .padding(.top, 24)
            .padding(.horizontal, 36)
            .foregroundColor(Color(hex: "#333"))
    }
}

private struct GeneralEditorToggleStyle: ToggleStyle {
    let width: CGFloat = 60

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: width, height: width / 2)
                    .foregroundColor(configuration.isOn ? Color(hex:"#38761d") : Color.gray)
                
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: (width / 2) - 4, height: width / 2 - 6)
                    .padding(4)
                    .foregroundColor(.white)
                    .onTapGesture {
                        withAnimation {
                            configuration.$isOn.wrappedValue.toggle()
                        }
                }
            }
        }
    }
}

struct GeneralEditorView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralEditorView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
