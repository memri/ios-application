//
// KeyboardModifiers.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct KeyboardModifier: ViewModifier {
    var enabled: Bool = true
    var overrideHeightWhenVisible: CGFloat?
    @ObservedObject var keyboard = KeyboardResponder.shared
    @EnvironmentObject var extraEnvironment: ExtraEnvironment
    @State var contentBounds: CGRect?

    func body(content: Content) -> some View {
        content
            .offset(enabled ? (contentBounds.flatMap { contentBounds in
                CGSize(width: 0,
                       height: min(
                           0,
                           (extraEnvironment.screenSize.height - contentBounds.maxY) - keyboard
                               .currentHeight
                       ))
            } ?? .zero) : .zero)
            .frame(height: keyboard.keyboardVisible ? overrideHeightWhenVisible : nil)
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

struct KeyboardPaddingModifier: ViewModifier {
    var enabled: Bool = true
    @ObservedObject var keyboard = KeyboardResponder.shared
    @EnvironmentObject var extraEnvironment: ExtraEnvironment
    @State var contentBounds: CGRect?

    func body(content: Content) -> some View {
        content
            .padding(.bottom, enabled ? (contentBounds.flatMap { contentBounds in
                max(
                    0,
                    keyboard
                        .currentHeight - (extraEnvironment.screenSize.height - contentBounds.maxY)
                )
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
