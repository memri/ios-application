//
//  styles.swift
//  memri
//
//  Created by Ruben Daniels on 4/17/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

// TODO: https://stackoverflow.com/questions/56479674/set-toggle-color-in-swiftui
public struct MemriToggleStyle: ToggleStyle {
	let width: CGFloat = 60

	public func makeBody(configuration: Self.Configuration) -> some View {
		HStack {
			configuration.label

			Spacer()

			ZStack(alignment: configuration.isOn ? .trailing : .leading) {
				RoundedRectangle(cornerRadius: 20)
					.frame(width: width, height: width / 2)
					.foregroundColor(configuration.isOn ? Color(hex: "#499827") : Color.gray)

				RoundedRectangle(cornerRadius: 20)
					.frame(width: (width / 2) - 4, height: width / 2 - 6)
					.padding(4)
					.foregroundColor(.white)
					.shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.2), radius: 2, x: -2, y: 2)
			}
		}
		.onTapGesture {
			withAnimation {
				configuration.$isOn.wrappedValue.toggle()
			}
		}
	}
}
