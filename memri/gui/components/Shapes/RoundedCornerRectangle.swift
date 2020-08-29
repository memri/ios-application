//
//  RoundedCornerRectangle.swift
//  memri
//
//  Created by Toby Brennan on 26/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct RoundedCornerRectangle: InsettableShape
{
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    var inset: CGFloat = .zero
    
    func path(in rect: CGRect) -> Path
    {
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
    
    func inset(by amount: CGFloat) -> Self
    {
        RoundedCornerRectangle(radius: radius, corners: corners, inset: inset + amount)
    }
}
