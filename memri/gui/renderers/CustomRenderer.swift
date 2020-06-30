//
//  CustomRenderer.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

let registerCustomRenderer = {
	Renderers.register(
		name: "custom",
		title: "",
		order: 0,
		icon: "",
		view: AnyView(CustomRendererView()),
		renderConfigType: CascadingCustomConfig.self,
		canDisplayResults: { _ -> Bool in false }
	)
}

class CascadingCustomConfig: CascadingRenderConfig {
	var type: String? = "custom"
}

struct CustomRendererView: View {
	@EnvironmentObject var context: MemriContext

	let name = "custom"

	var renderConfig: CascadingCustomConfig? {
		context.cascadingView.renderConfig as? CascadingCustomConfig
	}

	var body: some View {
		VStack {
			self.renderConfig?.render(item: self.context.item ?? Item())
		}
	}
}

struct CustomRendererView_Previews: PreviewProvider {
	static var previews: some View {
		CustomRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
	}
}
