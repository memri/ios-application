//
//  EmailThreadRenderer.swift
//  memri
//
//  Created by Toby Brennan on 30/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

//
//let registerEmailRenderers = {
//    Renderers.register(
//        name: "email",
//        title: "Email Thread",
//        order: 0,
//        icon: "envelope.fill",
//        view: AnyView(EmailThreadRenderer()),
//        renderConfigType: CascadingEmailThreadRendererConfig.self,
//        canDisplayResults: { items -> Bool in
//            items.first?.genericType == "Message" ||
//                items.first?.genericType == "Note" ||
//                items.first?.genericType == "EmailMessage"
//    }
//    )
//}

class CascadingEmailThreadRendererConfig: CascadingRendererConfig {
    var type: String? = "email"
    
    var content: Expression? {
        cascadeProperty("content")
    }
}

struct EmailThreadRenderer: View {
    @EnvironmentObject var context: MemriContext
    
    var renderConfig: CascadingEmailThreadRendererConfig {
        (context.currentView?.renderConfig as? CascadingEmailThreadRendererConfig) ?? CascadingEmailThreadRendererConfig()
    }
    
    func getEmailHeader(forItem item: Item) -> AnyView {
        renderConfig.render(item: item)
            .environmentObject(context)
            .eraseToAnyView()
    }
    
    func getEmailItems() -> [EmailThreadItem] {
        context.items.map { item in
            EmailThreadItem(uuid: item.uid.value.map(String.init) ?? UUID().uuidString,
                            contentHTML: resolveExpression(renderConfig.content, toType: String.self, forItem: item) ?? "",
                headerView: getEmailHeader(forItem: item))
        }
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    var body: some View {
        EmailThreadRendererController(emails: getEmailItems())
            .background(renderConfig.backgroundColor?.color ?? Color(.systemGroupedBackground))
    }
}

struct EmailThreadRendererController: UIViewControllerRepresentable {
    var emails: [EmailThreadItem]
    
    func makeUIViewController(context: Context) -> EmailThreadedViewController {
        EmailThreadedViewController()
    }
    
    func updateUIViewController(_ emailThreadController: EmailThreadedViewController, context: Context) {
        emailThreadController.emails = emails
    }
}

struct EmailThreadRenderer_Previews: PreviewProvider {
    static var previews: some View {
        EmailThreadRenderer()
    }
}
