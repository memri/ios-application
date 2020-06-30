//
//  UIColor.swift
//  memri
//
//  Created by Toby Brennan on 23/6/20.
//  Copyright © 2020 memri. All rights reserved.
//
import UIKit

extension UIColor {
	convenience init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (1, 1, 1, 0)
		}

		self.init(red: CGFloat(r) / 255,
				  green: CGFloat(g) / 255,
				  blue: CGFloat(b) / 255,
				  alpha: CGFloat(a) / 255)
	}
}

// TODO:
//    extension UIColor {
//
//        // Check if the color is light or dark, as defined by the injected lightness threshold.
//        // Some people report that 0.7 is best. I suggest to find out for yourself.
//        // A nil value is returned if the lightness couldn't be determined.
//        func isLight(threshold: Float = 0.5) -> Bool? {
//            let originalCGColor = self.cgColor
//
//            // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
//            // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
//            let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
//            guard let components = RGBCGColor?.components else {
//                return nil
//            }
//            guard components.count >= 3 else {
//                return nil
//            }
//
//            let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
//            return (brightness > threshold)
//        }
//    }

// https://medium.com/@masamichiueta/bridging-uicolor-system-color-to-swiftui-color-ef98f6e21206
