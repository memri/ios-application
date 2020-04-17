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

struct _GeneralEditorView: View {
    @EnvironmentObject var main: Main
    var name: String="generalEditor"
    var item: DataItem? = nil
    
    var renderConfig: GeneralEditorConfig {
        return self.main.computedView.renderConfigs[name] as? GeneralEditorConfig ?? GeneralEditorConfig()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing:0){
                if renderConfig.groups != nil{
                    ForEach(Array(renderConfig.groups!.keys), id: \.self){key in
                        self.drawSection(
                            header: "\(key)".uppercased(),
                            properties: self.renderConfig.groups![key]!)
                    }
                }

                drawSection(
                    header: "OTHER",
                    properties: getProperties())
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
        }
    }
    
    func drawSection(header caption: String, properties list: [String]) -> some View {
        Section(header:Text(caption).generalEditorHeader()) {
            Divider()
            ForEach(list, id: \.self){ prop in
                GeneralEditorRow(item: self.item!,
                                 prop: prop,
                                 readOnly: self.renderConfig.readOnly.contains(prop),
                                 isLast: list.last == prop)
            }
            Divider()
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

//protocol OptionalProtocol {
//    func wrappedType() -> Any.Type
//}
//
//extension Optional : OptionalProtocol {
//    func wrappedType() -> Any.Type {
//        return Wrapped.self
//    }
//}

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
                    if propType == PropertyType.string { defaultRow(self.item!.getString(self.prop)) }
                    else if propType == PropertyType.bool { defaultRow(self.item!.getString(self.prop)) }
                    else if propType == PropertyType.date { defaultRow(self.item!.getString(self.prop)) }
                    else if propType == PropertyType.int { defaultRow(self.item!.getString(self.prop)) }
                    else if propType == PropertyType.double { defaultRow(self.item!.getString(self.prop)) }
                    else if propType == PropertyType.object { listLabelRow }
                    else { defaultRow() }
                }
                else {
                    if propType == PropertyType.string { stringRow() }
                    else if propType == PropertyType.bool { boolRow() }
                    else if propType == PropertyType.date { dateRow }
                    else if propType == PropertyType.int { intRow() }
                    else if propType == PropertyType.double { doubleRow() }
                    else if propType == PropertyType.object { listLabelRow }
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
    
//    func boolRow(_ item: DataItem, _ prop:String) -> some View {
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
        Text("Hello")
        
//        WrappingHStack(self.item![prop] as! RealmSwift.List<Label>){ label in
//           VStack {
//               Text(label.name)
//                   .font(.system(size: 14, weight: .semibold))
//                   .foregroundColor(Color.white) // TODO color calculation
//                   .padding(5)
//                   .padding(.horizontal, 8)
//                   .frame(minWidth: 0, minHeight: 20, alignment: .center)
//           }
//           .background(Color(hex:label.color ?? "##fff"))
//           .cornerRadius(5)
//       }
//       .frame(minHeight: 72) // Huge hack
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
