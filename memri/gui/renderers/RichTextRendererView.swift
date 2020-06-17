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

let registerRichText = {
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
    
    let filterText: Binding<String>
    
    var initialContent: NSAttributedString {
        guard let rtf = (dataItem.get("content") as String?) else { return NSAttributedString() }
        return NSAttributedString.fromRTF(rtf) ?? NSAttributedString()
    }
    
    var body: some View {
        MemriTextEditor(initialContent: initialContent,
                        preferredHeight: nil,
                        onTextChanged: {newAttributedString in
                            self.dataItem.set("title", newAttributedString.firstLineString())
                            self.dataItem.set("content", newAttributedString.toRTF())
                            self.dataItem.set("textContent", newAttributedString.string)
        })
    }
}

struct RichTextRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var renderConfig: CascadingRichTextEditorConfig
        = CascadingRichTextEditorConfig([], ViewArguments())

    var body: some View {
        let dataItem = self.context.cascadingView.resultSet.singletonItem
        let binding = Binding(
            get: { dataItem?.getString("title") ?? "" },
            set: {
                dataItem?.set("title", $0)
            }
        )
        
        return VStack(spacing: 0) {
            if context.cascadingView.resultSet.singletonItem != nil {
                _RichTextEditor(dataItem: dataItem!,
                                filterText: $context.cascadingView.filterText)
            }
        }.padding(.horizontal, 6)
    }
}

struct RichTextRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
