//
// CustomRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import SwiftUI

class CustomRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(
        name: "custom",
        icon: "lightbulb",
        makeController: CustomRendererController.init,
        makeConfig: CustomRendererController.makeConfig
    )

    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? CustomRendererConfig) ?? CustomRendererConfig()
    }

    let context: MemriContext
    let config: CustomRendererConfig

    func makeView() -> AnyView {
        CustomRendererView(controller: self).eraseToAnyView()
    }

    func update() {
        objectWillChange.send()
    }

    static func makeConfig(
        head: CVUParsedDefinition?,
        tail: [CVUParsedDefinition]?,
        host: Cascadable?
    ) -> CascadingRendererConfig {
        CustomRendererConfig(head, tail, host)
    }

    func customView() -> some View {
        config.render(item: context.item)
            .environmentObject(context)
    }
}

class CustomRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var showSortInConfig: Bool = false
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }

    let showContextualBarInEditMode: Bool = false
}

struct CustomRendererView: View {
    @ObservedObject var controller: CustomRendererController

    var body: some View {
        VStack {
            controller.customView()
        }
    }
}

struct CustomRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CustomRendererView(controller: CustomRendererController(context: try! RootContext(name: "")
                .mockBoot(), config: nil))
    }
}
