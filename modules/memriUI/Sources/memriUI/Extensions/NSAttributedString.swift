//
// NSAttributedString.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import UIKit

extension NSAttributedString {
    func withFontSize(_ size: CGFloat) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.enumerateAttribute(
            NSAttributedString.Key.font,
            in: NSMakeRange(0, mutableSelf.length),
            options: []
        ) { value, range, _ in
            if let oldFont = value as? UIFont {
                let newFont = oldFont.withSize(size)
                mutableSelf.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
            }
        }
        return mutableSelf
    }
}
