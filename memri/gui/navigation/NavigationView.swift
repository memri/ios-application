//
//  Navigation.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import ASCollectionView
import SwiftUI

struct NavigationWrapper<Content: View>: View {
	init(isVisible: Binding<Bool>, @ViewBuilder content: () -> Content) {
		_isVisible = isVisible
		self.content = content()
	}

	var content: Content
	var widthRatio: CGFloat = 0.8
	@Binding var isVisible: Bool
	@GestureState(reset: { _, transaction in
		transaction.animation = .default
    }) var offset: CGFloat = .zero

	func navWidth(_ geom: GeometryProxy) -> CGFloat {
		geom.size.width * widthRatio
	}

	func cappedOffset(_ geom: GeometryProxy) -> CGFloat {
		if isVisible {
			return max(min(0, offset), -navWidth(geom))
		} else {
			return min(max(0, offset), navWidth(geom))
		}
	}

	func fractionVisible(_ geom: GeometryProxy) -> Double {
		let fraction = Double(abs(cappedOffset(geom)) / navWidth(geom))
		return isVisible ? 1 - fraction : fraction
	}

	var body: some View {
		Group {
			if memri_shouldUseLargeScreenLayout {
				GeometryReader { geom in
					self.bodyForLargeScreen(withGeom: geom)
				}
			} else {
				GeometryReader { geom in
					self.body(withGeom: geom)
				}
			}
		}
	}

	func body(withGeom geom: GeometryProxy) -> some View {
		ZStack(alignment: .leading) {
			content
				.frame(width: geom.size.width, height: geom.size.height, alignment: .topLeading)
				.offset(x: isVisible ? navWidth(geom) + cappedOffset(geom) : cappedOffset(geom))
				.disabled(isVisible)
				.zIndex(-1)
			Color.clear
				.contentShape(Rectangle())
				.frame(minWidth: 10, maxWidth: 10, maxHeight: .infinity)
				.simultaneousGesture(navigationDragGesture)
			if isVisible || offset > 0 {
				Color.black
					.opacity(fractionVisible(geom) * 0.5)
					.edgesIgnoringSafeArea(.all)
					.onTapGesture {
						withAnimation {
							self.isVisible = false
						}
					}
					.simultaneousGesture(navigationDragGesture)
					.zIndex(10)
				Navigation()
					.frame(width: geom.size.width * widthRatio)
					.edgesIgnoringSafeArea(.all)
					.offset(x: isVisible ? cappedOffset(geom) : (-navWidth(geom) + cappedOffset(geom)), y: 0)
					.simultaneousGesture(navigationDragGesture)
					.transition(.move(edge: .leading))
					.zIndex(15)
			}
		}
	}

	func bodyForLargeScreen(withGeom _: GeometryProxy) -> some View {
		HStack(spacing: 0) {
			Navigation()
				.frame(width: 300)
				.edgesIgnoringSafeArea(.all)
			content
		}
	}

	var navigationDragGesture: some Gesture {
		DragGesture()
			.updating($offset, body: { value, offset, _ in
				offset = value.translation.width
            })
			.onEnded { value in
				if
					self.isVisible ? value.predictedEndTranslation.width < -140 : value.translation.width > 50,
					abs(value.predictedEndTranslation.width) > 20 {
					withAnimation {
						self.isVisible.toggle()
					}
				}
			}
	}
}

struct Navigation: View {
	@EnvironmentObject var context: MemriContext

	@ObservedObject var keyboardResponder = KeyboardResponder.shared

	@State var showSettings: Bool = false

	var body: some View {
		VStack {
			HStack(spacing: 20) {
				Button(action: {
					self.showSettings = true
                }) {
					Image(systemName: "gear")
						.font(Font.system(size: 22, weight: .semibold))
						.foregroundColor(Color(hex: "#d9d2e9"))
				}.sheet(isPresented: self.$showSettings) {
					SettingsPane().environmentObject(self.context)
				}

				MemriTextField(
					value: $context.navigation.filterText,
					placeholder: "Search",
					textColor: UIColor(hex: "#8a66bc"),
					tintColor: UIColor.white,
					clearButtonMode: .always,
					showPrevNextButtons: false
				)
				.layoutPriority(-1)
				.padding(5)
				.padding(.horizontal, 5)
				.accentColor(.white)
				.background(Color(hex: "#341e51"))
				.cornerRadius(5)

				Button(action: {}) {
					Image(systemName: "pencil")
						.font(Font.system(size: 22, weight: .semibold))
						.foregroundColor(Color(hex: "#d9d2e9"))
				}

				Button(action: {}) {
					Image(systemName: "plus")
						.font(Font.system(size: 22, weight: .semibold))
						.foregroundColor(Color(hex: "#d9d2e9"))
				}
			}
			.padding(.top, 40)
			.padding(.horizontal, 20)
			.frame(minHeight: 95)
			.background(Color(hex: "#492f6c"))

			ASTableView(section:
				ASSection(id: 0, data: context.navigation.getItems(), dataID: \.self) { navItem, _ -> AnyView in
					switch navItem.type {
					case "item":
						return AnyView(NavigationItemView(item: navItem, hide: {
							withAnimation {
								self.context.showNavigation = false
							}
                        }))
					case "heading":
						return AnyView(NavigationHeadingView(title: navItem.title))
					case "line":
						return AnyView(NavigationLineView())
					default:
						return AnyView(NavigationItemView(item: navItem, hide: {
							withAnimation {
								self.context.showNavigation = false
							}
                        }))
					}
				}
			)
			.separatorsEnabled(false)
			.contentInsets(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))

			//            ScrollView(.vertical) {
			//                VStack (spacing:0) {
			//                    ForEach(self.context.navigation.getItems(), id: \.self){
			//                        self.item($0)
			//                    }
			//                }
			//            }
			//            .padding(.top, 10)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(hex: "543184"))
	}
}

struct NavigationItemView: View {
	@EnvironmentObject var context: MemriContext

	var item: NavigationItem
	var hide: () -> Void

	var body: some View {
		Button(action: {
			if let sessionName = self.item.sessionName {
				// TODO:
				do { try ActionOpenSessionByName.exec(self.context, ["sessionName": sessionName]) }
				catch {}

				self.hide()
			}
        }) {
			Text(item.title?.firstUppercased ?? "")
				.font(.system(size: 18, weight: .regular))
				.padding(.vertical, 10)
				.padding(.horizontal, 35)
				.foregroundColor(Color(hex: "#d9d2e9"))
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
		}
		.buttonStyle(NavigationButtonStyle())
	}
}

struct NavigationButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.background(
				configuration.isPressed ? Color.white.opacity(0.15) : .clear
			)
	}
}

struct NavigationHeadingView: View {
	var title: String?

	var body: some View {
		HStack {
			Text((title ?? "").uppercased())
				.font(.system(size: 18, weight: .bold))
				.padding(.horizontal, 20)
				.padding(.vertical, 8)
				.foregroundColor(Color(hex: "#8c73af"))
			Spacer()
		}
	}
}

struct NavigationLineView: View {
	var body: some View {
		VStack {
			Divider().background(Color(.black))
		}.padding(.horizontal, 50)
	}
}

struct Navigation_Previews: PreviewProvider {
	static var previews: some View {
		Navigation().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
