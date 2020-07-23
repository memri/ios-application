//
// KeyboardToolbar.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

struct KeyboardToolbarView: View {
    weak var owner: UIView?
    var showArrows: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showArrows {
                self.button(icon: Image(systemName: "chevron.left"), action: {
                    self.owner?.moveToNextResponder(forward: false)
            })
                Divider()
                self.button(icon: Image(systemName: "chevron.right"), action: {
                    self.owner?.moveToNextResponder()
            })
                Divider()
            }
            Spacer()
            Divider()
            self.button(icon:
                Image(systemName: "keyboard.chevron.compact.down")
                    .foregroundColor(Color(.label)),
                        action: {
                    self.owner?.resignFirstResponder()
        })
        }
        .padding(.horizontal, 4)
        .frame(minHeight: 40, idealHeight: 40, maxHeight: 60)
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    func button<Label: View>(
        icon: Label,
        action: @escaping () -> Void,
        highlighted: Bool = false
    ) -> some View {
        Button(action: action) {
            icon
                .frame(minWidth: 30, minHeight: 36)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(highlighted ? Color(.tertiarySystemBackground) : .clear))
                .contentShape(Rectangle())
        }
    }
}

struct KeyboardToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardToolbarView()
    }
}
