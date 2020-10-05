//
//  TextEditorToolbar.swift
//  RichTextEditor
//
//  Created by Toby Brennan on 22/6/20.
//  Copyright © 2020 ApptekStudios. All rights reserved.
//

import Foundation
import SwiftUI

struct MemriTextEditor_Toolbar: View {
    weak var textView: MemriTextEditor_UIKit?
    
    enum Item {
        case button(
            label: String,
            icon: String,
            hideInactive: Bool = false,
            isActive: Bool = false,
            onPress: () -> Void
        )
        case divider
        
        var view: AnyView {
            switch self {
            case let .button(label, icon, hideInactive, isActive, onPress):
                return AnyView(
                    Group {
                        if hideInactive && !isActive {
                            EmptyView()
                        } else {
                            Button(action: onPress) {
                                Image(systemName: icon)
                                    .frame(minWidth: 30, minHeight: 36)
                                    .background(RoundedRectangle(cornerRadius: 4).fill((isActive && !hideInactive) ? Color(.tertiarySystemBackground) : .clear))
                                    .contentShape(Rectangle())
                                    .accessibility(hint: Text(label))
                        }
                    }
                })
            case .divider:
                return AnyView(Divider().padding(.vertical, 8))
            }
        }
    }
    
    var items: [Item]
    
    var body: some View {
        //ScrollView(.horizontal) {
        return VStack(spacing: 0) {
            Divider()
            HStack {
                GeometryReader { geom in
                    HStack(spacing: 2) {
                        ForEach(self.items.indexed(), id: \.index) { item in
                            item.view
                        }
                    }
                    .frame(width: geom.size.width, height: geom.size.height, alignment: .leading)
                }
                Spacer()
                #if !targetEnvironment(macCatalyst)
                Divider()
                Button(action: { self.textView?.resignFirstResponder() }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(Color(.label))
                        .frame(minWidth: 30, minHeight: 36)
                        .contentShape(Rectangle())
                        .accessibility(hint: Text("Close Keyboard"))
                }
                #endif
            }
            .padding(.horizontal, self.padding)
            #if targetEnvironment(macCatalyst)
            Divider()
            #endif
        }
        .frame(minHeight: 40, idealHeight: 40, maxHeight: 60)
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    var padding: CGFloat {
         #if targetEnvironment(macCatalyst)
        return 15
        #else
        return 4
        #endif
    }
}

struct TextEditorToolbar_Previews: PreviewProvider {
    static var previews: some View {
        MemriTextEditor_Toolbar(items: [])
    }
}
