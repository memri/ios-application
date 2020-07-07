//
//  TopNavigation.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

public struct TopNavigation: View {
	@EnvironmentObject var context: MemriContext

	@State private var showingBackActions = false
	@State private var showingTitleActions = false

	@State private var isPressing = false // HACK because long-press isnt working why?

	private let inSubView: Bool
	private let showCloseButton: Bool

	init() {
		inSubView = false
		showCloseButton = false
	}

	init(inSubView: Bool, showCloseButton: Bool) {
		self.inSubView = inSubView
		self.showCloseButton = showCloseButton
	}

	private func forward() {
		context.executeAction(ActionForward(context))
	}

	private func toFront() {
		context.executeAction(ActionForwardToFront(context))
	}

	private func backAsSession() {
		context.executeAction(ActionBackAsSession(context))
	}

	private func openAllViewsOfSession() {
		do {
			try ActionOpenViewByName.exec(context, ["name": "views-in-current-session"])
		} catch {
			debugHistory.error("Unable to open views for session: \(error)")
		}
	}

	private func createTitleActionSheet() -> ActionSheet {
		var buttons: [ActionSheet.Button] = []
		let isNamed = context.currentSession?.currentView?.name != nil

		// TODO: or copyFromView
		buttons.append(isNamed
			? .default(Text("Update view")) { self.toFront() }
			: .default(Text("Save view")) { self.toFront() }
		)

		buttons.append(.default(Text("Add to Navigation")) { self.toFront() })
		buttons.append(.default(Text("Duplicate view")) { self.toFront() })

		if isNamed {
			buttons.append(.default(Text("Reset to saved view")) { self.backAsSession() })
		}

		buttons.append(.default(Text("Copy a link to this view")) { self.toFront() })
		buttons.append(.cancel())

		return ActionSheet(title: Text("Do something with the current view"), buttons: buttons)
	}

	private func createBackActionSheet() -> ActionSheet {
		ActionSheet(title: Text("Navigate to a view in this session"),
					buttons: [
						.default(Text("Forward")) { self.forward() },
						.default(Text("To the front")) { self.toFront() },
						.default(Text("Back as a new session")) { self.backAsSession() },
						.default(Text("Show all views")) { self.openAllViewsOfSession() },
						.cancel(),
					])
	}

	public var body: some View {
		let backButton = context.currentSession?.hasHistory ?? false ? ActionBack(context) : nil
		let context = self.context

		return VStack(alignment: .leading, spacing: 0) {
			HStack(alignment: .top, spacing: 10) {
				if !inSubView && !memri_shouldUseLargeScreenLayout {
					ActionButton(action: ActionShowNavigation(context))
						.font(Font.system(size: 20, weight: .semibold))
				} else if showCloseButton {
					// TODO: Refactor: Properly support text labels
					//                        Action(action: Action(actionName: .closePopup))
					//                            .font(Font.system(size: 20, weight: .semibold))
					Button(action: {
						context.executeAction(ActionClosePopup(context))
                    }) {
						Text("Close")
							.font(.system(size: 16, weight: .regular))
							.padding(.horizontal, 5)
							.padding(.vertical, 2)
							.foregroundColor(Color(hex: "#106b9f"))
					}
					.font(Font.system(size: 19, weight: .semibold))
				}

				if backButton != nil {
					Button(action: {
						if !self.showingBackActions, let backButton = backButton {
							context.executeAction(backButton)
						}
                    }) {
						Image(systemName: backButton?.getString("icon") ?? "")
							.fixedSize()
							.padding(.horizontal, 5)
							.padding(.vertical, 5)
							.foregroundColor(backButton?.color ?? Color.white)
					}
					.font(Font.system(size: 19, weight: .semibold))
					.onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10, pressing: {
						someBool in
						if self.isPressing || someBool {
							self.isPressing = someBool

							if someBool {
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
									if self.isPressing {
										self.showingBackActions = true
									}
								}
							}
						}
                    }, perform: {})
					.actionSheet(isPresented: $showingBackActions) {
						createBackActionSheet()
					}
				} else {
					Button(action: { self.showingBackActions = true }) {
						Image(systemName: "smallcircle.fill.circle")
							.fixedSize()
							.font(.system(size: 10, weight: .bold, design: .default))
							.padding(.horizontal, 5)
							.padding(.vertical, 8)
							.foregroundColor(Color(hex: "#434343"))
					}
					.font(Font.system(size: 19, weight: .semibold))
					.actionSheet(isPresented: $showingBackActions) {
						createBackActionSheet()
					}
				}

				// Store the available space for the title
				Color.clear
					.frame(maxWidth: .infinity)
					.layoutPriority(5)
					.anchorPreference(
						key: BoundsPreferenceKey.self,
						value: .bounds
					) { $0 }

				// TODO: this should not be a setting but a user defined view that works on all
				if context.item != nil || context.items.count > 0 &&
					context.settings.getBool("user/general/gui/showEditButton") != false &&
					context.cascadingView?.editActionButton != nil {
					ActionButton(action: context.cascadingView?.editActionButton)
						.font(Font.system(size: 19, weight: .semibold))
				}

				if context.currentSession?.isEditMode ?? false {
					Button(action: { withAnimation { self.context.executeAction(ActionDelete(self.context)) } }) {
						Image(systemName: "trash")
							.fixedSize()
							.font(.system(size: 10, weight: .bold, design: .default))
							.padding(.horizontal, 5)
							.padding(.vertical, 8)
							.foregroundColor(Color.red)
					}
				}

				ActionButton(action: context.cascadingView?.actionButton)
					.font(Font.system(size: 22, weight: .semibold))

				if !inSubView {
					ActionButton(action: ActionShowSessionSwitcher(context))
						.font(Font.system(size: 20, weight: .medium))
						.rotationEffect(.degrees(90))
				}
			}
			.padding(.top, 15)
			.padding(.bottom, 10)
			.padding(.leading, 15)
			.padding(.trailing, 15)
			.frame(height: 50, alignment: .top)

			Divider()
		}
		.padding(.bottom, 0)
		.centeredOverlayWithinBoundsPreferenceKey {
			Button(action: {
				self.showingTitleActions = true
            }) {
				Text(context.cascadingView?.title ?? "")
					.font(.headline)
					.foregroundColor(Color(hex: "#333"))
					.truncationMode(.tail)
			}
			.actionSheet(isPresented: self.$showingTitleActions) {
				self.createTitleActionSheet()
			}
		}
	}
}

private struct BoundsPreferenceKey: PreferenceKey {
	typealias Value = Anchor<CGRect>?

	static var defaultValue: Value = nil

	static func reduce(
		value: inout Value,
		nextValue: () -> Value
	) {
		value = nextValue() ?? value
	}
}

private extension View {
	func centeredOverlayWithinBoundsPreferenceKey<Content: View>(content: @escaping () -> Content) -> some View {
		func calculateCenterAndMaxSize(geometry: GeometryProxy, anchor: Anchor<CGRect>?) -> (CGPoint, CGSize)? {
			guard let bounds = anchor.map({ geometry[$0] }) else { return nil }
			let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
			let maxWidth = min(abs(bounds.maxX - center.x), abs(bounds.minX - center.x)) * 2
			return (center, CGSize(width: maxWidth, height: bounds.height))
		}

		return overlayPreferenceValue(BoundsPreferenceKey.self) { preference in
			GeometryReader { geometry in
				calculateCenterAndMaxSize(geometry: geometry, anchor: preference).map { center, maxSize in
					content()
						.frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
						.position(center)
				}
			}
		}
	}
}

struct Topnavigation_Previews: PreviewProvider {
	static var previews: some View {
		TopNavigation().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
