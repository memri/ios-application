//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
	@EnvironmentObject var context: MemriContext

	var widthRatio: CGFloat = 0.75

	@GestureState(reset: { _, transaction in
		transaction.animation = .default
    }) var offset: CGFloat = .zero

	var isVisible: Bool {
		get { context.currentSession?.showContextPane ?? false }
		nonmutating set {
			realmWrite(self.context.realm) { _ in
				self.context.currentSession?.showContextPane = newValue
				self.context.scheduleUIUpdate(immediate: true)
			}
		}
	}

	func paneWidth(_ geom: GeometryProxy) -> CGFloat {
		min(geom.size.width * widthRatio, 300)
	}

	func cappedOffset(_ geom: GeometryProxy) -> CGFloat {
		min(max(0, offset), paneWidth(geom))
	}

	func fractionVisible(_ geom: GeometryProxy) -> Double {
		1 - Double(abs(cappedOffset(geom)) / paneWidth(geom))
	}

	var body: some View {
		GeometryReader { geom in
			self.body(withGeom: geom)
		}
	}

	func body(withGeom geom: GeometryProxy) -> some View {
		ZStack(alignment: .trailing) {
			if isVisible {
				ContextPaneBackground()
					.opacity(fractionVisible(geom) * 0.5)
					.edgesIgnoringSafeArea(.vertical)
					.transition(.opacity)
					.gesture(TapGesture()
						.onEnded { _ in
							withAnimation {
								self.isVisible = false
							}
                        })
					.zIndex(-1)
				ContextPaneForeground()
					.frame(width: paneWidth(geom))
					.offset(x: cappedOffset(geom))
					.edgesIgnoringSafeArea(.vertical)
					.transition(.move(edge: .trailing))
			}
		}
		.simultaneousGesture(contextPaneDragGesture)
	}

	var contextPaneDragGesture: some Gesture {
		DragGesture()
			.updating($offset, body: { value, offset, _ in
				offset = value.translation.width
            })
			.onEnded { value in
				if value.predictedEndTranslation.width > 100, abs(value.translation.width) > 10 {
					withAnimation {
						self.isVisible = false
					}
				}
			}
	}
}

struct ContentPane_Previews: PreviewProvider {
	static var previews: some View {
		ContextPane().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
