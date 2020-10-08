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
            icon: AnyView,
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
                                icon
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
    var subitems: [Item] = []
    var color: String?
    var setColor: ((String) -> Void)?
    
    private var colorBinding: Binding<CGColor> {
        Binding<CGColor>(
            get: { (color.map { UIColor(hex: $0) } ?? .black).cgColor },
            set: { setColor?(UIColor(cgColor: $0).hexString(includingAlpha: false)) }
        )
    }
    
    var body: some View {
            VStack(spacing: 0) {
                if !subitems.isEmpty {
                    Divider()
                    HStack {
                        ForEach(self.subitems.indexed(), id: \.index) { item in
                            item.view
                        }
                    }
                    .frame(minHeight: 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Divider()
                HStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 2) {
                            ForEach(self.items.indexed(), id: \.index) { item in
                                item.view
                            }
                            #if !targetEnvironment(macCatalyst)
                            if #available(iOS 14.0, *) {
                                ColorPicker(selection: colorBinding, supportsOpacity: false) {
                                    EmptyView()
                                }.labelsHidden()
                            }
                            #endif
                        }
                        .padding(.horizontal, self.padding)
                    }
                    
                    #if !targetEnvironment(macCatalyst)
                    Divider()
                    Button(action: { self.textView?.resignFirstResponder() }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(Color(.label))
                            .frame(minWidth: 30, minHeight: 36)
                            .padding(.horizontal, 10)
                            .contentShape(Rectangle())
                            .accessibility(hint: Text("Close Keyboard"))
                    }
                    #endif
                }
                .frame(minHeight: 40)
                #if targetEnvironment(macCatalyst)
                Divider()
                #endif
            }
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
