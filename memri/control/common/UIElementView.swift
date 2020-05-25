
//
//  GUIElement.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift
import TextView

/*
    TODO: In order to support mixed content we will need to add an element that renders a dataitem
          based on the way it is rendered by default for that (multi-item) renderer. This should be
          overwritable with a renderDescription for that renderer that is for a specific view-type.
          i.e. for the view-type "inbox". The default render description can always be specified
          using *. Here's an example:
 
            "renderConfigs": {
                "list": {
                    "renderDescription": [
                        "VStack", ["Text", {"text": "Hello"}]
                    ]
                },
                "inbox": {
                    "renderDescription": [
                        "VStack", ["Image", {"systemName": "email"}]
                    ]
                }
            }
        
          Inbox in the above example is a virtual renderer that is added to a dict on the
          renderConfigs object. Virtual renderers are useful for composability in the hands of
          users. For instance the memri button rendering can be implemented using a virtual
          renderer that simply renders the button in a SubView (see below) and can be customized
          for each type, without the need of actually implementing a renderer.
 
          For this purpose we need to introduce a new element called "ItemCell", this will render
          the data item as if it was rendered inside the renderer of that type when it would be
          only showing elements of that type (i.e. "[{type:Person}]" in views_from_json). It would
          look like this:
 
            ItemCell(dataItem, rendererNames [, viewOverride])
 
          with viewOverride being the name of a view that should be the template instead of the
          default. rendererNames is an array of rendererName so that it can search for multiple,
          for instance if the data item doesnt have definitions for one renderer, but it does for
          another.
 
          The inbox renderer can overlay other elements in its rendering, like this:
 
            // this is the inbox render config
            renderConfigs: {
                list: {
                    renderDescription: [
                        "ZStack", [
                            "VStack", ["Text", {"text": "Type: {.type}"}],
                            "ItemCell", {
                                "dataItem": "{.}",
                                "rendererNames: ["inbox", "list", "thumbnail", "map"]
                            }
                        ],
                    ]
                }
            }
 
          In addition and to facilitate the abilities of the view hyper network is the introduction of
          the subview element that can display views inline. An immediate use case is to view a list
          of views (in fact they are sessions, but its easier to perceive them as views), and
          instead of seeing a screenshot of the last state they are the actual live instantiation of
          that view. This can be used for showing a list of charts that are easy to scroll through
          and thus easy to check daily without having to go to many views (N.B. this can somewhat be
          achieved with a session that has a history of each chart you want. you can then navigate
          with the back button and via the list of views in the session. However this is not as
          easy as scrolling). This is the signature of the element
 
            SubView(viewName or viewInstance, dataItem, variables)
 
          And the renderConfig of the session view for the charts could look like this:
          
            renderConfigs: {
                list: {
                    renderDescription: [
                        "VStack", [
                            "Text", {"text": "{.computedTitle}"},
                            "SubView", {
                                "view": "{.}", // or "viewName": "someView" for other use cases
                                "dataItem": "{.}", // this could be left out in this case
                                "variables": {
                                    "toolbar": false,
                                    "readonly": true
                                }
                            }
                        ]
                    ]
                }
            }
 
          In order for the hyper network to work openView needs to be extended to be able to open
          views from URIs (file, http, elsewhere), and to download any additional data from sources
          other than the pod, for usage in memri. We can even imagine a limited web renderer of views
          that people can embed on their website, where they also link to the view for download in
          memri. By allowing views to refer to each other a network of knowledge can appear. But the
          exact shape of that is still beyond the horizon of my imagination.
 */

public struct UIElementView: SwiftUI.View {
    @EnvironmentObject var main: Main
    
    let from:UIElement
    let item:DataItem
    let viewArguments:ViewArguments
    
    public init(_ gui:UIElement, _ dataItem:DataItem, _ viewArguments:ViewArguments? = nil) {
        self.from = gui
        self.item = dataItem
        self.viewArguments = viewArguments ?? ViewArguments()
    }
    
    public func has(_ propName:String) -> Bool {
        viewArguments.get(propName) != nil || from.has(propName)
    }
    
    public func get<T>(_ propName:String) -> T? {
        from.get(propName, item, viewArguments)
    }
    
    public func getImage(_ propName:String) -> UIImage {
        if let file:File? = get(propName) {
            return file?.asUIImage ?? UIImage()
        }
        
        return UIImage()
    }
    
    public func getList(_ propName:String) -> [DataItem] {
        let x:[DataItem]? = get("list")
        return x ?? []
    }

    private func resize(_ view:SwiftUI.Image) -> AnyView {
        let resizable:String = from.get("resizable", self.item)!
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
                if from.type == "vstack" {
                    VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from.properties, self.item, main)
                }
                else if from.type == "hstack" {
                    HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
                    .clipped()
                    .animation(nil)
                    .setProperties(from.properties, self.item, main)
                }
                else if from.type == "zstack" {
                    ZStack(alignment: get("alignment") ?? .top) { self.renderChildren }
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "editorsection" {
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
                        .setProperties(from.properties, self.item, main)
                    }
                    else {
                        VStack(spacing: 0){
                            self.renderChildren
                        }
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, main)
                    }
                }
                else if from.type == "editorrow" {
                    VStack (spacing: 0) {
                        VStack(alignment: .leading, spacing: 4){
                            if self.has("title") && self.get("nopadding") != true {
                                Text(LocalizedStringKey(self.get("title") ?? ""
                                    .camelCaseToWords()
                                    .lowercased()
                                    .capitalizingFirstLetter())
                                )
                                .generalEditorLabel()
                            }

                            self.renderChildren
                                .generalEditorCaption()
                        }
                        .fullWidth()
    //                    .padding(.bottom, 10)
                        .padding(.leading, self.get("nopadding") != true ? 36 : 0)
                        .padding(.trailing, self.get("nopadding") != true ? 36 : 0)
                        .clipped()
                        .animation(nil)
                        .setProperties(from.properties, self.item, main)
                        .background(self.get("$readonly") ?? false
                            ? Color(hex:"#f9f9f9")
                            : Color(hex:"#f7fcf5"))

                        if self.has("title") {
                            Divider().padding(.leading, 35)
                        }
                    }

                }
                else if from.type == "editorlabel" {
                    HStack (alignment: .center, spacing:15) {
                        Button (action:{}) {
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
                else if from.type == "button" {
                    Button(action: {
                        if let press:Action = self.get("press") {
                            self.main.executeAction(press, with: self.item)
                        }
                    }) {
                        self.renderChildren
                    }
                    .setProperties(from.properties, self.item, main)
                }
                else if from.type == "flowstack" {
                    FlowStack(getList("list")) { listItem in
                        ForEach(0..<self.from.children.count){ index in
                            UIElementView(self.from.children[index], listItem)
                        }
                    }
                    .animation(nil)
                    .setProperties(from.properties, self.item, main)
                }
                else if from.type == "text" {
                    Text(from.processText(get("text") ?? "[nil]"))
                        .if(from.getBool("bold")){ $0.bold() }
                        .if(from.getBool("italic")){ $0.italic() }
                        .if(from.getBool("underline")){ $0.underline() }
                        .if(from.getBool("strikethrough")){ $0.strikethrough() }
                        .fixedSize(horizontal: false, vertical: true)
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "textfield" {
                    self.renderTextfield()
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "itemcell" {
                    // TODO Refactor fix this
    //                ItemCell(
    //                    item: self.item,
    //                    rendererNames: get("rendererNames") as [String],
    //                    variables: [] // get("variables") // TODO Refactor fix this
    //                )
    //                .environmentObject(self.main)
    //                .setProperties(from.properties, self.item, main)
                }
                else if from.type == "subview" {
                    if has("viewName") {
                        SubView(
                            main: self.main,
                            viewName: from.getString("viewName"),
                            dataItem: self.item,
                            args: ViewArguments(get("arguments") ?? [:] as [String:Any])
                        )
                        .setProperties(from.properties, self.item, main)
                    }
                    else {
                        SubView(
                            main: self.main,
                            view: { let x:SessionView = get("view")!; return x }(),
                            dataItem: self.item,
                            args: ViewArguments(get("arguments") ?? [:] as [String:Any])
                        )
                        .setProperties(from.properties, self.item, main)
                    }
                }
                else if from.type == "map" {
                    MapView(location: get("location"), address: get("address"))
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "picker" {
                    self.renderPicker()
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "securefield" {
                }
                else if from.type == "action" {
                    ActionButton(action: get("press") ?? ActionNoop())
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "memributton" {
                    MemriButton(item: self.item)
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "image" {
                    if has("systemname") {
                        Image(systemName: get("systemname") ?? "exclamationmark.bubble")
                            .if(from.has("resizable")) { self.resize($0) }
                            .setProperties(from.properties, self.item, main)
                    }
                    else { // assuming image property
                        Image(uiImage: getImage("image"))
                            .renderingMode(.original)
                            .if(from.has("resizable")) { self.resize($0) }
                            .setProperties(from.properties, self.item, main)
                    }
                }
                else if from.type == "circle" {
                }
                else if from.type == "horizontalline" {
                    HorizontalLine()
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "rectangle" {
                    Rectangle()
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "roundedrectangle" {
                    RoundedRectangle(cornerRadius: get("cornerradius") ?? 5)
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "spacer" {
                    Spacer()
                        .setProperties(from.properties, self.item, main)
                }
                else if from.type == "divider" {
                    Divider()
                        .setProperties(from.properties, self.item, main)
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
    
    func renderTextfield() -> some View {
        let (type, dataItem, propName) = from.getType("value", self.item)
        let rows:CGFloat = self.get("rows") ?? 2
        
        return Group {
            if type != PropertyType.string {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), value: Binding<Any>(
                    get: { dataItem[propName] as Any},
                    set: { dataItem.set(propName, $0) }
                ), formatter: type == .date ? DateFormatter() : NumberFormatter()) // TODO Refactor: expand to properly support all types
                .keyboardType(.decimalPad)
                .generalEditorInput()
            }
            else if self.has("rows") {
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
                        textAlignment: self.get("textalign") ?? TextView.TextAlignment.left,
                        font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        textColor: Color(hex:"#223322").uiColor(),
                        autocorrection: TextView.Autocorrection.no
                    )
                }
                .frame(height: rows * 25)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                .border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
                .clipped()
            }
            else {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), text: Binding<String>(
                    get: { dataItem.getString(propName) },
                    set: { dataItem.set(propName, $0) }
                ))
                .generalEditorInput()
            }
        }
    }
    
    func renderPicker() -> some View {
        let dataItem:DataItem? = self.get("value")
        let (_, propDataItem, propName) = from.getType("value", self.item)
        let datasource:[String:Any] = self.get("queryoptions")! // TODO refactor error handling
        let emptyValue = self.get("empty") ?? "Pick a value"
        
        return Picker(
            item: self.item,
            selected: dataItem ?? self.get("defaultValue"),
            title: "Select a \(emptyValue)",
            emptyValue: emptyValue,
            propDataItem: propDataItem,
            propName: propName,
            datasource: Datasource(value: [
                "query": datasource["query"],
                "sortProperty": datasource["sortProperty"],
                "sortAscending": datasource["sortAscending"]
            ])
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
