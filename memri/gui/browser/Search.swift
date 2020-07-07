//
//  Search.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import SwiftUI

struct Search: View {
	@EnvironmentObject var context: MemriContext

	var body: some View {
		VStack(spacing: 0) {
			Divider().background(Color(hex: "#efefef"))
			HStack {
				MemriTextField(value: Binding<String>(
					get: { self.context.cascadingView?.filterText ?? "" },
					set: { self.context.cascadingView?.filterText = $0 }
				),
							   placeholder: context.cascadingView?.searchHint ?? "",
							   showPrevNextButtons: false)
					.layoutPriority(-1)
				Text(context.cascadingView?.searchMatchText ?? "")

				ForEach(context.cascadingView?.filterButtons ?? [], id: \.self) { filterButton in
					ActionButton(action: filterButton)
						.font(Font.system(size: 20, weight: .medium))
				}
			}
			.padding(.horizontal, 15)
			.padding(.vertical, 6)
		}
		.background(Color.white)
		.modifier(KeyboardModifier())
		.background(Color.white.edgesIgnoringSafeArea(.all))
	}
}

struct KeyboardModifier: ViewModifier {
	@ObservedObject var keyboard = KeyboardResponder.shared
	@Environment(\.screenSize) var screenSize
	@State var contentBounds: CGRect?

	func body(content: Content) -> some View {
		content
			.offset(x: 0, y: contentBounds.flatMap { contentBounds in
				screenSize.map { screenSize in
					min(0, (screenSize.height - contentBounds.maxY) - keyboard.currentHeight)
				}
            } ?? 0)
			.background(
				GeometryReader { geom in
					Color.clear.preference(key: BoundsPreferenceKey.self, value: geom.frame(in: .global))
				}
			)
			.onPreferenceChange(BoundsPreferenceKey.self, perform: { value in
				DispatchQueue.main.async {
					self.contentBounds = value
				}
            })
	}
}

private struct BoundsPreferenceKey: PreferenceKey {
	typealias Value = CGRect?

	static var defaultValue: Value = nil

	static func reduce(
		value: inout Value,
		nextValue: () -> Value
	) {
		value = nextValue() ?? value
	}
}

struct Search_Previews: PreviewProvider {
	static var previews: some View {
		Search().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
