//
//  TextEdit.swift
//  memri
//
//  Created by Koen van der Veen on 18/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import UIKit
import memriUI
import Combine

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

class CascadingRichTextEditorConfig: CascadingRenderConfig {
    var type: String? = "richTextEditor"
}

struct _RichTextEditor: View {
    @EnvironmentObject var context: MemriContext
    @ObservedObject public var dataItem: DataItem
    
    var editModeBinding: Binding<Bool> {
        Binding<Bool>(get: { self.context.currentSession.isEditMode }, set: { self.context.currentSession.isEditMode = $0 })
    }
    
    let filterText: Binding<String>
    
    var body: some View {
        MemriTextEditor(initialContentHTML: dataItem.get("content") as String?,
                        isEditing: editModeBinding,
                        preferredHeight: nil,
                        onTextChanged: {newAttributedString in
                            print(newAttributedString.toHTML()?.replace("'", "\""))
                            self.dataItem.set("content", newAttributedString.toHTML())
                            self.dataItem.set("textContent", newAttributedString.string.withoutFirstLine())
                            self.dataItem.set("title", newAttributedString.string.firstLineString())
        })
    }
}

struct RichTextRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var renderConfig: CascadingRichTextEditorConfig
        = CascadingRichTextEditorConfig([], ViewArguments())

    var body: some View {
        let dataItem = self.context.cascadingView.resultSet.singletonItem
        
        return VStack(spacing: 0) {
            dataItem.map { dataItem in
                _RichTextEditor(dataItem: dataItem,
                                filterText: $context.cascadingView.filterText)
            }
        }
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
