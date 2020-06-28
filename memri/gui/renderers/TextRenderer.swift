//
//  TextRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

struct RichTextRenderer: Renderer {
	var name: String = "singleItem"
	var icon: String = ""
	var category: String = ""
	var renderModes: [ActionDescription] = []
	var options1: [ActionDescription] = []
	var options2: [ActionDescription] = []
	var editMode: Bool = false
	var renderConfig: RenderConfig = RenderConfig()

	func setState(_: RenderState) -> Bool { false }
	func getState() -> RenderState { RenderState() }
	func setCurrentView(_: Session, _: (_ error: Error, _ success: Bool) -> Void) {}

	@EnvironmentObject var main: Main

	var body: some View {
		VStack {
			RichTextEditor(dataItem: main.computedView.resultSet.item!)
		}
	}
}

struct RichTextRenderer_Previews: PreviewProvider {
	static var previews: some View {
		RichTextRenderer().environmentObject(Main(name: "", key: "").mockBoot())
	}
}
