
//
//  GUIElement.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift
import memriUI

public struct UIElementView: SwiftUI.View {
    @EnvironmentObject var context: MemriContext
    
    let from:UIElement
    let item:Item
    let viewArguments:ViewArguments
    
    public init(_ gui:UIElement, _ dataItem:Item, _ viewArguments:ViewArguments? = nil) {
        self.from = gui
        self.item = dataItem
        self.viewArguments = viewArguments ?? ViewArguments()
        
        self.viewArguments.set(".", dataItem)
    }
    
    public func has(_ propName:String) -> Bool {
        viewArguments.get(propName) != nil || from.has(propName)
    }
    
    public func get<T>(_ propName:String, type: T.Type = T.self) -> T? {
        from.get(propName, item, viewArguments)
    }
    
    public func get<T>(_ propName:String, defaultValue: T, type: T.Type = T.self) -> T {
        from.get(propName, item, viewArguments) ?? defaultValue
    }
    
    public func getImage(_ propName:String) -> UIImage {
        if let file:File? = get(propName) {
            return file?.asUIImage ?? UIImage()
        }
        
        return UIImage()
    }
    
    public func getbundleImage() -> Image{
        if let name: String = get("bundleImage"){
            return Image(name)
        }
        return Image(systemName: "exclamationmark.bubble")
    }
    
    public func getList(_ propName:String) -> [Item] {
        let x:[Item]? = get("list")
        return x ?? []
    }

    private func resize(_ view:SwiftUI.Image) -> AnyView {
        let resizable:String = from.get("resizable", self.item) ?? ""
        let y = view.resizable()
        
        switch resizable {
        case "fill": return AnyView(y.aspectRatio(contentMode: .fill))
        case "fit": return AnyView(y.aspectRatio(contentMode: .fit))
        case "stretch": fallthrough
        default:
            return AnyView(y)
        }
    }
    
    public var body: some View {
        Group {
            if (!has("show") || get("show") == true) {
                if from.type == .VStack {
                    VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .HStack {
                    HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .ZStack {
                    ZStack(alignment: get("alignment") ?? .top) { self.renderChildren }
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .EditorSection {
                    if self.has("title") {
                        Section(header: Text(LocalizedStringKey(
                            (self.get("title") ?? "").uppercased()
                        )).generalEditorHeader()){
                            Divider()
                            self.renderChildren
                            Divider()
                        }
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                    else {
                        VStack(spacing: 0){
                            self.renderChildren
                        }
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                }
                else if from.type == .EditorRow {
                    VStack (spacing: 0) {
                        VStack(alignment: .leading, spacing: 4){
                            if self.has("title") && self.get("nopadding") != true {
                                Text(LocalizedStringKey(self.get("title") ?? ""
                                    .camelCaseToWords()
                                    .lowercased()
                                    .capitalizingFirst())
                                )
                                .generalEditorLabel()
                            }

                            self.renderChildren
                                .generalEditorCaption()
                        }
                        .fullWidth()
                        .padding(.bottom, 10)
                        .padding(.leading, self.get("nopadding") != true ? 36 : 0)
                        .padding(.trailing, self.get("nopadding") != true ? 36 : 0)
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                        .background(self.get("readOnly") ?? viewArguments.get("readOnly") ?? false
                            ? Color(hex:"#f9f9f9")
                            : Color(hex:"#f7fcf5"))

                        if self.has("title") {
                            Divider().padding(.leading, 35)
                        }
                    }

                }
                else if from.type == .EditorLabel {
                    HStack (alignment: .center, spacing:15) {
                        Button (action: {
                            let args:[String:Any?] = [
                                "subject": self.context.item, // self.item,
                                "property": self.viewArguments.get("name")
                            ]
                            let action = ActionUnlink(self.context, arguments: args)
                            self.context.executeAction(action, with: self.item, using:self.viewArguments)
                        }) {
                            Image (systemName: "minus.circle.fill")
                                .foregroundColor(Color.red)
                                .font(.system(size: 22))
                        }

                        if self.has("title") {
                            Button (action:{}) {
                                HStack {
                                    Text (LocalizedStringKey(self.get("title") ?? ""))
                                        .foregroundColor(Color.blue)
                                        .font(.system(size: 15))
                                        .lineLimit(1)
                                    Spacer()
                                    Image (systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.gray)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 130, maxWidth: 130, maxHeight: .infinity, alignment: .leading)
                    .padding(10)
                    .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
                }
                else if from.type == .Button {
                    Button(action: {
                        if let press:Action = self.get("press") {
                            self.context.executeAction(press, with: self.item, using:self.viewArguments)
                        }
                    }) {
                        self.renderChildren
                    }
                    .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .FlowStack {
                    FlowStack(getList("list")) { listItem in
                        ForEach(0..<self.from.children.count){ index in
                            UIElementView(self.from.children[index], listItem, self.viewArguments)
//                                          ViewArguments(self.viewArguments.asDict().merging([".": listItem],
//                                                                                            uniquingKeysWith: { current, new in new })))
                                .environmentObject(self.context)
                        }
                    }
                    .animation(nil)
                    .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Text {
                    (from
                        .processText(get("text"))
                        ?? get("nilText")
                        ?? (get("allowNil", defaultValue: false, type: Bool.self) ? "" : nil)
                    ).map { text in
                        Text(text)
                            .if(from.getBool("bold")){ $0.bold() }
                            .if(from.getBool("italic")){ $0.italic() }
                            .if(from.getBool("underline")){ $0.underline() }
                            .if(from.getBool("strikethrough")){ $0.strikethrough() }
                            .fixedSize(horizontal: false, vertical: true)
                            .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                }
                else if from.type == .Textfield {
                    self.renderTextfield()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .RichTextfield {
                    self.renderRichTextfield()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .ItemCell {
                    // TODO Refactor fix this
    //                ItemCell(
    //                    item: self.item,
    //                    rendererNames: get("rendererNames") as [String],
    //                    variables: [] // get("variables") // TODO Refactor fix this
    //                )
    //                .environmentObject(self.context)
    //                .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .SubView {
                    if has("viewName") {
                        SubView(
                            context: self.context,
                            viewName: from.getString("viewName"),
                            dataItem: self.item,
                            args: ViewArguments(get("arguments") ?? [:] as [String:Any])
                        )
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                    else {
                        SubView(
                            context: self.context,
                            view: {
                                // TODO create view form the parsed definition
                                // Find out why datasource is not parsed
                                
                                if let parsed:[String:Any?] = get("view") {
                                    let parsedViewDef = CVUParsedViewDefinition(Item.generateUUID())
                                    parsedViewDef.parsed = parsed
                                    do {
                                        let sessionView = try SessionView.fromCVUDefinition(parsed: parsedViewDef)
                                        return sessionView
                                    }
                                    catch let error {
                                        debugHistory.error("\(error)")
                                    }
                                    return SessionView()
                                }
                                else {
                                    print("Failed to make subview (not defined), creating empty one instead")
                                    debugHistory.error("Failed to make subview (not defined), creating empty one instead")
                                    return SessionView()
                                }
                            }(),
                            dataItem: self.item,
                            args: ViewArguments(get("arguments") ?? [:] as [String:Any])
                        )
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                }
                else if from.type == .Map {
                    MapView(dataItems: [self.item], locationKey: get("locationKey") ?? "location", addressKey: get("addressKey") ?? "address")
                        .background(Color(.secondarySystemBackground))
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Picker {
                    self.renderPicker()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .SecureField {
                }
                else if from.type == .Action {
                    ActionButton(action: get("press") ?? Action(context, "noop"))
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .MemriButton {
                    MemriButton(item: self.item)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Image {
                    if has("systemName") {
                        Image(systemName: get("systemName") ?? "exclamationmark.bubble")
                            .if(from.has("resizable")) { self.resize($0) }
                            .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                    else if has("bundleImage"){
                        getbundleImage()
                            .renderingMode(.original)
                            .if(from.has("resizable")) { self.resize($0) }
                            .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                    else { // assuming image property
                        Image(uiImage: getImage("image"))
                            .renderingMode(.original)
                            .if(from.has("resizable")) { self.resize($0) }
                            .setProperties(from.properties, self.item, context, self.viewArguments)
                    }
                }
                else if from.type == .Circle {
                }
                else if from.type == .HorizontalLine {
                    HorizontalLine()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Rectangle {
                    Rectangle()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .RoundedRectangle {
                    RoundedRectangle(cornerRadius: get("cornerRadius") ?? 5)
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Spacer {
                    Spacer()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Divider {
                    Divider()
                        .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .Empty {
                    EmptyView()
                }
                else {
                    logWarning("Warning: Unknown UI element type '\(from.type)'")
                }
            }
        }
    }
    
//    @ViewBuilder // This crashes the build when Group is gone
    // TODO add this for multiline editing: https://github.com/kenmueller/TextView
//    func renderTextfield() -> some View {
//        let (type, propName) = from.getType("value", self.item)
//
//        return Group {
//            if type != PropertyType.string {
//                TextField(LocalizedStringKey(self.get("hint") ?? ""), value: Binding<Any>(
//                    get: { self.item[propName] as Any},
//                    set: { self.item.set(propName, $0) }
//                ), formatter: type == .date ? DateFormatter() : NumberFormatter()) // TODO Refactor: expand to properly support all types
//                .keyboardType(.decimalPad)
//                .generalEditorInput()
//            }
//            else {
//                TextField(LocalizedStringKey(self.get("hint") ?? ""), text: Binding<String>(
//                    get: { self.item.getString(propName) },
//                    set: { self.item.set(propName, $0) }
//                ))
//                .generalEditorInput()
//            }
//        }
//    }
    
    func logWarning(_ message:String) -> some View {
        print (message)
        return EmptyView()
    }
    
    func renderRichTextfield() -> some View {
        let (_, dataItem, propName) = from.getType("value", self.item, self.viewArguments)
        
        return Group {
            if propName == "" {
                Text("Invalid property value set on TextField")
            }
            else {
                _RichTextEditor(dataItem: dataItem, filterText: $context.cascadingView.filterText)
                    .generalEditorInput()
            }
        }
    }
    
    func renderTextfield() -> some View {
        let (type, dataItem, propName) = from.getType("value", self.item, self.viewArguments)
//        let rows:CGFloat = self.get("rows") ?? 2
        
        return Group {
            if propName == "" {
                Text("Invalid property value set on TextField")
            }
            else if type != PropertyType.string {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), value: Binding<Any>(
                    get: { dataItem[propName] as Any},
                    set: { dataItem.set(propName, $0) }
                ), formatter: type == .date ? DateFormatter() : NumberFormatter()) // TODO Refactor: expand to properly support all types
                .keyboardType(.decimalPad)
                .generalEditorInput()
            }
            //Temporarily disabled
            /*else if self.has("rows") {
                VStack {
                    TextView(
                        text: Binding<String>(
                            get: { dataItem.getString(propName) },
                            set: { dataItem.set(propName, $0) }
                        ),
                        isEditing: Binding<Bool>(
                            get: { return true },
                            set: { let _ = $0 }
                        ), // ??
                        placeholder: self.get("hint") ?? "",
                        textAlignment: self.get("textAlign") ?? TextView.TextAlignment.left,
                        font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        textColor: Color(hex:"#223322").uiColor(),
                        autocorrection: TextView.Autocorrection.no
                    )
                }
                .frame(height: rows * 25)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
                .clipped()
            }*/
            else {
                MemriTextField(
                    value: Binding<String>(
                    get: { dataItem.getString(propName) },
                    set: { dataItem.set(propName, $0) }
                ), placeholder: self.get("hint"))
                .generalEditorInput()
            }
        }
    }
    
    func renderPicker() -> some View {
        let dataItem:Item? = self.get("value")
        let (_, propItem, propName) = from.getType("value", self.item, self.viewArguments)
        let emptyValue = self.get("empty") ?? "Pick a value"
        
        var datasource:Datasource
        if let def = from.properties["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
            do { datasource = try Datasource.fromCVUDefinition(def, self.viewArguments) }
            catch let error {
                debugHistory.warn("\(error)")
                datasource = Datasource()
            }
        }
        else {
            datasource = Datasource()
        }
        
        return Picker(
            item: self.item,
            selected: dataItem ?? self.get("defaultValue"),
            title: self.get("title") ?? "Select a \(emptyValue)",
            emptyValue: emptyValue,
            propItem: propItem,
            propName: propName,
            datasource: datasource
        )
    }
    
    var renderChildren: some View {
        Group {
            ForEach(0..<from.children.count) { index in
                UIElementView(self.from.children[index], self.item, self.viewArguments)
            }
        }
    }
    
}
