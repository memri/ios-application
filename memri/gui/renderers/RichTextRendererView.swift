//
// RichTextRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI
import UIKit

let registerRichTextEditorRenderer = {
    Renderers.register(
        name: "richTextEditor",
        title: "Default",
        order: 0,
        icon: "pencil",
        view: AnyView(RichTextRendererView()),
        renderConfigType: CascadingRichTextEditorConfig.self,
        canDisplayResults: { items -> Bool in
            items.count > 0 && items.count == 1 && items[0] is Note
        }
    )
}

struct _RichTextEditor: View {
    @EnvironmentObject var context: MemriContext

    var htmlContentBinding: Binding<String?>?
    var plainContentBinding: Binding<String?>
    var titleBinding: Binding<String?>?
    var titleHint: String?

    var fontSize: CGFloat = 18
    var headingFontSize: CGFloat = 26

    var editModeBinding: Binding<Bool> {
        Binding<Bool>(get: { self.context.currentSession?.editMode ?? false },
                      set: { self.context.currentSession?.editMode = $0 })
    }

    let filterText: Binding<String>

    var body: some View {
        VStack(spacing: 0) {
            MemriTextEditor(
                initialContentHTML: htmlContentBinding?.wrappedValue ?? plainContentBinding
                    .wrappedValue,
                titleBinding: titleBinding,
                titlePlaceholder: titleHint,
                fontSize: fontSize,
                headingFontSize: headingFontSize,
                isEditing: editModeBinding,
                preferredHeight: nil,
                onTextChanged: { newAttributedString in
                    self.htmlContentBinding?.wrappedValue = newAttributedString.toHTML()
                    self.plainContentBinding.wrappedValue = newAttributedString.string
                }
            )
        }
    }
}

class CascadingRichTextEditorConfig: CascadingRenderConfig {
    var type: String? = "richTextEditor"

    var titleHint: String? {
        get { cascadeProperty("titleHint") ?? "Untitled" }
        set(value) { setState("titleHint", value) }
    }

    var fontSize: CGFloat {
        get { cascadePropertyAsCGFloat("fontSize") ?? 18 }
        set(value) { setState("fontSize", value) }
    }

    var titleFontSize: CGFloat {
        get { cascadePropertyAsCGFloat("titleFontSize") ?? 26 }
        set(value) { setState("titleFontSize", value) }
    }
}

#warning(
    "This renderer is currently specialised for Notes - it might make sense to utilise the custom renderer instead. The RichTextEditor CVU component has all this functionality."
)
struct RichTextRendererView: View {
    @EnvironmentObject var context: MemriContext

    var renderConfig = CascadingRichTextEditorConfig()

    var noteItem: Note? {
        context.item as? Note
    }

    // CONTENT
    var contentBinding: Binding<String?> {
        Binding<String?>(
            get: { self.noteItem?.get("content") },
            set: { self.noteItem?.set("content", $0) }
        )
    }

    var plainContentBinding: Binding<String?> {
        Binding<String?>(
            get: { self.noteItem?.get("textContent") },
            set: { self.noteItem?.set("textContent", $0) }
        )
    }

    // TITLE
    var titleBinding: Binding<String?> {
        Binding<String?>(
            get: { self.noteItem?.get("title") },
            set: { self.noteItem?.set("title", $0) }
        )
    }

    var body: some View {
        let dataItem = self.context.currentView?.resultSet.singletonItem

        return VStack(spacing: 0) {
            dataItem.map { _ in
                _RichTextEditor(htmlContentBinding: contentBinding,
                                plainContentBinding: plainContentBinding,
                                titleBinding: titleBinding,
                                titleHint: renderConfig.titleHint,
                                fontSize: renderConfig.fontSize,
                                headingFontSize: renderConfig.titleFontSize,
                                filterText: Binding<String>(
                                    get: { self.context.currentView?.filterText ?? "" },
                                    set: { self.context.currentView?.filterText = $0 }
                                ))
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(try! RootContext(name: "", key: "").mockBoot())
    }
}
