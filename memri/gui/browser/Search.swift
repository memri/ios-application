//
// Search.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import SwiftUI

struct Search: View {
    @EnvironmentObject var context: MemriContext
    @State var isEditing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "#efefef"))
            HStack {
                MemriTextField(value: Binding<String>(
                    get: { self.context.currentView?.filterText ?? "" },
                    set: { self.context.currentView?.filterText = $0 }
                ),
                               placeholder: context.currentView?.searchHint ?? "",
                               showPrevNextButtons: false)
                    .onEditingBegan {
                        self.isEditing = true
                    }
                    .onEditingEnded {
                        self.isEditing = false
                    }
                    .layoutPriority(-1)
                Text(context.currentView?.searchMatchText ?? "")

                ForEach(context.currentView?.filterButtons ?? [], id: \.self) { filterButton in
                    ActionButton(action: filterButton)
                        .font(Font.system(size: 20, weight: .medium))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 6)
        }
        .background(Color.white)
        .modifier(KeyboardModifier(enabled: isEditing))
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct KeyboardModifier: ViewModifier {
    var enabled: Bool = true
    @ObservedObject var keyboard = KeyboardResponder.shared
    @Environment(\.screenSize) var screenSize
    @State var contentBounds: CGRect?

    func body(content: Content) -> some View {
        content
            .offset(x: 0, y: enabled ? (contentBounds.flatMap { contentBounds in
                screenSize.map { screenSize in
                    min(0, (screenSize.height - contentBounds.maxY) - keyboard.currentHeight)
                }
				} ?? 0) : 0)
            .background(
                GeometryReader { geom in
                    Color.clear.preference(
                        key: BoundsPreferenceKey.self,
                        value: geom.frame(in: .global)
                    )
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
        Search().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
