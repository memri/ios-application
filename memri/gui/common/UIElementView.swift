//
// UIElementView.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

public struct UIElementView: SwiftUI.View {
    @EnvironmentObject var context: MemriContext

    let from: UIElement
    let item: Item
    let viewArguments: ViewArguments

    public init(_ gui: UIElement, _ dataItem: Item, _ viewArguments: ViewArguments? = nil) {
        from = gui
        item = dataItem.isInvalidated ? Item() : dataItem

        self.viewArguments = ViewArguments(viewArguments, item)
    }

    public func has(_ propName: String) -> Bool {
        viewArguments.get(propName) != nil || from.has(propName)
    }

    public func get<T>(_ propName: String, type _: T.Type = T.self) -> T? {
        if propName == "align" {
            if let align:T? = from.get(propName, item, viewArguments) {
                return align
            }
            else if let align:String? = from.get(propName, item, viewArguments) {
                return CVUParser.specialTypedProperties["align"]?(align, "") as? T
            }
        }
        
        return from.get(propName, item, viewArguments)
    }

    public func get<T>(_ propName: String, defaultValue: T, type _: T.Type = T.self) -> T {
        from.get(propName, item, viewArguments) ?? defaultValue
    }

    public func getFileURI(_ propName: String) -> String? {
        if let file: File = get(propName) {
            return file.sha256 ?? file.filename
        }
        else if let photo: Photo? = get(propName), let file = photo?.file {
            return file.sha256 ?? file.filename
        }
        return nil
    }

    public func getbundleImage() -> Image {
        if let name: String = get("bundleImage") {
            return Image(name)
        }
        return Image(systemName: "exclamationmark.bubble")
    }

    public func getList(_ key: String) -> [Item] {
        get(key, type: [Item].self) ?? []
    }

    public var body: some View {
        Group {
            if !has("show") || get("show") == true {
                if from.type == .VStack {
                    VStack(alignment: get("alignment") ?? .leading, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
//                    .frame(maxWidth: .infinity, alignment: get("align") ?? .top)
                    .clipped()
                    .animation(nil)
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .HStack {
                    HStack(alignment: get("alignment") ?? .top, spacing: get("spacing") ?? 0) {
                        self.renderChildren
                    }
//                    .frame(maxWidth: .infinity, alignment: get("align") ?? .leading)
                    .clipped()
                    .animation(nil)
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .ZStack {
                    ZStack(alignment: get("alignment") ?? .top) { self.renderChildren }
//                        .frame(maxWidth: .infinity)
                        .clipped()
                        .animation(nil)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .EditorSection {
                    if self.has("title") {
                        Section(header: Text(LocalizedStringKey(
                            (self.get("title") ?? "").uppercased()
                        )).generalEditorHeader()) {
                            Divider()
                            self.renderChildren
                            Divider()
                        }
                        .clipped()
                        .animation(nil)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                    }
                    else {
                        VStack(spacing: 0) {
                            self.renderChildren
                        }
                        .clipped()
                        .animation(nil)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                    }
                }
                else if from.type == .EditorRow {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            #warning("readWrite mode is not implemented")

                            if self.has("title") && self.get("nopadding") != true {
                                Text(LocalizedStringKey(self.get("title") ?? ""
                                        .camelCaseToWords()
                                        .lowercased()
                                        .capitalizingFirst()))
                                    .generalEditorLabel()
                            }

                            self.renderChildren
                                .generalEditorCaption()
                        }
                        .fullWidth()
                        .padding(.bottom, self.get("nopadding") != true ? 10 : 0)
                        .padding(.leading, self.get("nopadding") != true ? 36 : 0)
                        .padding(.trailing, self.get("nopadding") != true ? 36 : 0)
                        .clipped()
                        .animation(nil)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                        .background(self.get("readOnly") ?? viewArguments.get("readOnly") ?? false
                            ? Color(hex: "#f9f9f9")
                            : Color(hex: "#f7fcf5"))

                        if self.has("title") {
                            Divider().padding(.leading, 35)
                        }
                    }
                }
                else if from.type == .EditorLabel {
                    HStack(alignment: .center, spacing: 15) {
                        Button(action: {
                            let args: [String: Any?] = [
                                "subject": self.context.item, // self.item,
                                "edgeType": self.viewArguments.get("name"),
                            ]
                            let action = ActionUnlink(self.context, values: args)
                            self.context.executeAction(
                                action,
                                with: self.item,
                                using: self.viewArguments
                            )
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.red)
                                .font(.system(size: 22))
                        }

                        if self.has("title") {
                            Button(action: {}) {
                                HStack {
                                    Text(LocalizedStringKey(self.get("title") ?? ""))
                                        .foregroundColor(Color.blue)
                                        .font(.system(size: 15))
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
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
                        if let press: Action = self.get("press") {
                            self.context.executeAction(
                                press,
                                with: self.item,
                                using: self.viewArguments
                            )
                        }
                    }) {
                        self.renderChildren
                    }
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .FlowStack {
                    FlowStack(getList("list")) { listItem in
                        ForEach(0 ..< self.from.children.count) { index in
                            UIElementView(self.from.children[index], listItem, self.viewArguments)
                                .environmentObject(self.context)
                        }
                    }
                    .animation(nil)
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .Text {
                    (from
                        .processText(get("text"))
                        ?? get("nilText")
                        ?? (get("allowNil", defaultValue: false, type: Bool.self) ? "" : nil))
                        .map { text in
                            Text(text)
                                .if(from.getBool("italic")) { $0.italic() }
                                .if(from.getBool("underline")) { $0.underline() }
                                .if(from.getBool("strikethrough")) { $0.strikethrough() }
                                .fixedSize(horizontal: false, vertical: true)
                                .setProperties(
                                    from.propertyResolver.properties,
                                    self.item,
                                    context,
                                    self.viewArguments
                                )
                        }
                }
                else if from.type == .Textfield {
                    self.renderTextfield()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .RichTextfield {
                    self.renderRichTextfield()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .ItemCell {
                    // TODO: Refactor fix this
                    //                ItemCell(
                    //                    item: self.item,
                    //                    rendererNames: get("rendererNames") as [String],
                    //                    variables: [] // get("variables") // TODO Refactor fix this
                    //                )
                    //                .environmentObject(self.context)
                    //                .setProperties(from.properties, self.item, context, self.viewArguments)
                }
                else if from.type == .EmailContent {
                    EmailView(emailHTML: self.get("content"))
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                    )
                }
                else if from.type == .SubView {
                    if has("viewName") {
                        SubView(
                            context: self.context,
                            viewName: from.getString("viewName"),
                            item: self.item,
                            viewArguments: ViewArguments(get("arguments",
                                                             type: [String: Any?].self))
                        )
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                    }
                    else {
                        SubView(
                            context: self.context,
                            view: {
                                #warning(
                                    "This is creating a new CVU at every redraw. Instead architect this to only create the CVU once and have that one reload"
                                )

                                if let parsed: [String: Any?] = get("view") {
                                    let def = CVUParsedViewDefinition(
                                        "[view]",
                                        type: "view",
                                        parsed: parsed
                                    )
                                    do {
                                        return try CVUStateDefinition.fromCVUParsedDefinition(def)
                                    }
                                    catch {
                                        debugHistory.error("\(error)")
                                    }
                                }
                                else {
                                    debugHistory
                                        .error(
                                            "Failed to make subview (not defined), creating empty one instead"
                                        )
                                }
                                return CVUStateDefinition()
                            }(),
                            item: self.item,
                            viewArguments: ViewArguments(get("arguments",
                                                             type: [String: Any?].self))
                        )
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                    }
                }
                else if from.type == .Map {
                    MapView(
                        useMapBox: context.settings
                            .get("/user/general/gui/useMapBox", type: Bool.self) ?? false,
                        config: .init(dataItems: [self.item],
                                      locationResolver: { _ in
                                          self
                                              .get("location", type: Location.self) ??
                                              (self
                                                  .get("location",
                                                       type: Results<Item>.self) as Any?)

                                      },
                                      addressResolver: {
                                          _ in
                                          (
                                              self.get("address", type: Address.self) as Any?
                                          ) ??
                                              (self
                                                  .get("address", type: Results<Item>.self) as Any?)

                                      },
                                      labelResolver: { _ in self.get("label") },
									  moveable: self.get("moveable", type: Bool.self) ?? true
									  )
                    )
                    .background(Color(.secondarySystemBackground))
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .Picker {
                    self.renderPicker()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .SecureField {
                }
                else if from.type == .Action {
                    ActionButton(action: get("press") ?? Action(context, "noop"), item: item)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .MemriButton {
                    MemriButton(
                        item: get("item"),
                        edge: get("edge")
                    )
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .TimelineItem {
                    TimelineItemView(icon: Image(systemName: get("icon") ?? "arrowtriangle.right"),
                                     title: from.processText(get("title")) ?? "-",
                                     subtitle: from.processText(get("text")),
                                     backgroundColor: ItemFamily(rawValue: item.genericType)?
                                         .backgroundColor ?? .gray)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .MessageBubble {
                    MessageBubbleView(timestamp: get("dateTime"),
                                      sender: get("sender"),
                                      content: from.processText(get("content")) ?? "",
                                      outgoing: get("isOutgoing") ?? false,
									  font: get("font", type: FontDefinition.self))
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .SmartText {
                    MemriSmartTextView(
                        string: get("text") ?? "",
                        detectLinks: get("detectLinks") ?? true,
                        font: from.propertyResolver.font,
                        color: get("color") ?? ColorDefinition.system(.label),
                        maxLines: get("maxLines"))
                    .fixedSize(horizontal: false, vertical: true)
                    .setProperties(
                        from.propertyResolver.properties,
                        self.item,
                        context,
                        self.viewArguments
                    )
                }
                else if from.type == .EmailHeader {
                    EmailHeaderView(senderName: get("title") ?? "Untitled",
                                    recipientList: get("subtitle"),
                                    dateString: get("rightSubtitle"),
                                    color: get("color"))
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                    )
                }
                else if from.type == .Image {
                    if has("systemName") {
                        Image(systemName: get("systemName") ?? "exclamationmark.bubble")
                            .if(from.propertyResolver.properties["resizable"] != nil) {
                                $0.resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            .setProperties(
                                from.propertyResolver.properties,
                                self.item,
                                context,
                                self.viewArguments
                            )
                    }
                    else if has("bundleImage") {
                        getbundleImage()
                            .renderingMode(.original)
                            .setProperties(
                                from.propertyResolver.properties,
                                self.item,
                                context,
                                self.viewArguments
                            )
                    }
                    else { // assuming image property
                        MemriImageView(imageURI: getFileURI("image"),
                                       fitContent: from.propertyResolver.fitContent,
                                       forceAspect: from.propertyResolver.forceAspect)
                            .setProperties(
                                from.propertyResolver.properties,
                                self.item,
                                context,
                                self.viewArguments
                            )
                    }
                }
                else if from.type == .Circle {
                }
                else if from.type == .HorizontalLine {
                    HorizontalLine()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .Rectangle {
                    Rectangle()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .RoundedRectangle {
                    RoundedRectangle(cornerRadius: get("cornerRadius") ?? 5)
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .Spacer {
                    Spacer()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
                }
                else if from.type == .Divider {
                    Divider()
                        .setProperties(
                            from.propertyResolver.properties,
                            self.item,
                            context,
                            self.viewArguments
                        )
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
    // TODO: add this for multiline editing: https://github.com/kenmueller/TextView
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

    func logWarning(_ message: String) -> some View {
        print(message)
        return EmptyView()
    }

    func renderRichTextfield() -> some View {
        let (_, contentDataItem, contentPropertyName) = from
            .getType("content", item, viewArguments)

        guard contentDataItem.hasProperty(contentPropertyName) else {
            return Text("Invalid property value set on RichTextEditor").eraseToAnyView()
        }

        // CONTENT
        let contentBinding = Binding<String>(
            get: { (contentDataItem[contentPropertyName] as? String) ?? "" },
            set: { contentDataItem.set(contentPropertyName, $0) }
        )
        let fontSize = get("fontSize", type: CGFloat.self)

        // TITLE
        let (_, titleDataItem, titlePropertyName) = from.getType("title", item, viewArguments)
        let titleBinding = titleDataItem.hasProperty(titlePropertyName) ? Binding<String?>(
            get: { (titleDataItem[titlePropertyName] as? String)?.nilIfBlank },
            set: { titleDataItem.set(titlePropertyName, $0) }
        ) : nil // Only pass a title binding if the property exists (otherwise pass nil)
        let titleHint = get("titleHint", type: String.self)
        let titleFontSize = get("titleFontSize", type: CGFloat.self)

        // Filter (unimplemented)
//        let filterTextBinding = Binding<String>(
//            get: { self.context.currentView?.filterText ?? "" },
//            set: { self.context.currentView?.filterText = $0 }
//        )

        let editModeBinding = Binding<Bool>(
            get: { self.context.currentSession?.editMode ?? false },
            set: { self.context.currentSession?.editMode = $0 })
        
        return MemriTextEditor(contentHTMLBinding: contentBinding,
                               titleBinding: titleBinding,
                               titlePlaceholder: titleHint,
                               fontSize: fontSize ?? 18,
                               headingFontSize: titleFontSize ?? 26,
                               backgroundColor: nil,
                               isEditing: editModeBinding)
            .eraseToAnyView()
    }

    func renderTextfield() -> some View {
        let (type, dataItem, propName) = from.getType("value", item, viewArguments)
        //        let rows:CGFloat = self.get("rows") ?? 2

        return Group {
            if propName == "" {
                Text("Invalid property value set on TextField")
            }
            else if type != PropertyType.string {
                TextField(LocalizedStringKey(self.get("hint") ?? ""), value: Binding<Any>(
                    get: { dataItem[propName] as Any },
                    set: { dataItem.set(propName, $0) }
                ),
                          formatter: type == .date ? DateFormatter() :
                    NumberFormatter()) // TODO: Refactor: expand to properly support all types
                    .keyboardType(.decimalPad)
                    .generalEditorInput()
            }
            // Temporarily disabled
            /* else if self.has("rows") {
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
             } */
            else {
                MemriTextField(
                    value: Binding<String>(
                        get: { dataItem.getString(propName) },
                        set: { dataItem.set(propName, $0) }
                    ), placeholder: self.get("hint")
                )
                .generalEditorInput()
            }
        }
    }

    func renderPicker() -> some View {
        let dataItem: Item? = get("value")
        let (_, propItem, propName) = from.getType("value", item, viewArguments)
        let emptyValue = get("empty") ?? "Pick a value"
        let query = get("query", type: String.self)
        let renderer = get("renderer", type: String.self)

        return Picker(
            item: item,
            selected: dataItem ?? get("defaultValue"),
            title: get("title") ?? "Select a \(emptyValue)",
            emptyValue: emptyValue,
            propItem: propItem,
            propName: propName,
            renderer: renderer,
            query: query ?? ""
        )
    }

    var renderChildren: some View {
        Group {
            ForEach(from.children, id: \.id) { uiElement in
                UIElementView(uiElement, self.item, self.viewArguments)
            }
        }
    }
}
