//
//  ScreenSize.swift
//  memri
//
//  Created by Toby Brennan on 21/6/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

extension EnvironmentValues {
	struct ScreenSize: EnvironmentKey {
		static var defaultValue: CGSize? = nil
	}

	var screenSize: CGSize? {
		get { self[ScreenSize.self] }
		set { self[ScreenSize.self] = newValue }
	}
}

struct ScreenSizer<Content>: View where Content: View {
	let content: () -> Content

	init(_ content: @escaping () -> Content) {
		self.content = content
	}

	var body: some View {
		GeometryReader { geometry in
			self.content()
				.padding(geometry.safeAreaInsets)
				.environment(\.screenSize, geometry.size)
		}
		.edgesIgnoringSafeArea(.all)
	}
}
