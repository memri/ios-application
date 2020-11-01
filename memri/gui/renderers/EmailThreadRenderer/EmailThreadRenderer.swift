//
// EmailThreadRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

class EmailThreadRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(
        name: "emailThread",
        icon: "envelope.fill",
        makeController: EmailThreadRendererController.init,
        makeConfig: EmailThreadRendererController.makeConfig
    )

    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? EmailThreadRendererConfig) ?? EmailThreadRendererConfig()
    }

    let context: MemriContext
    let config: EmailThreadRendererConfig

    func makeView() -> AnyView {
        EmailThreadRendererView(controller: self).eraseToAnyView()
    }

    func update() {
        objectWillChange.send()
    }

    static func makeConfig(
        head: CVUParsedDefinition?,
        tail: [CVUParsedDefinition]?,
        host: Cascadable?
    ) -> CascadingRendererConfig {
        EmailThreadRendererConfig(head, tail, host)
    }

    func getEmailHeader(forItem item: Item) -> AnyView {
        config.render(item: item)
            .environmentObject(context)
            .eraseToAnyView()
    }

    func getEmailItems() -> [EmailThreadItem] {
        context.items.map { item in
            EmailThreadItem(uuid: item.uid.value.map(String.init) ?? UUID().uuidString,
                            contentHTML: resolveExpression(
                                config.content,
                                toType: String.self,
                                forItem: item
                            ) ?? "",
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
}

class EmailThreadRendererConfig: CascadingRendererConfig {
    var content: Expression? {
        cascadeProperty("content")
    }
}

struct EmailThreadRendererView: View {
    @ObservedObject var controller: EmailThreadRendererController

    var body: some View {
        EmailThreadRenderer_SubView(emails: controller.getEmailItems())
            .background(controller.config.backgroundColor?.color ?? Color(.systemGroupedBackground))
    }
}

struct EmailThreadRenderer_SubView: UIViewControllerRepresentable {
    var emails: [EmailThreadItem]

    func makeUIViewController(context: Context) -> EmailThreadedViewController {
        EmailThreadedViewController()
    }

    func updateUIViewController(
        _ emailThreadController: EmailThreadedViewController,
        context: Context
    ) {
        emailThreadController.emails = emails
    }
}
