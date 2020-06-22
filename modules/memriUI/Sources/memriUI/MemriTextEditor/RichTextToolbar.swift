//
//  RichTextToolbar.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 10/6/20.
//  Copyright © 2020 ApptekStudios. All rights reserved.
//

import Foundation
import SwiftUI

struct RichTextToolbarView: View {
  weak var textView: MemriTextEditor_UIKit?
  
  var state_bold: Bool = false
  var state_italic: Bool = false
  var state_underline: Bool = false
  var state_strikethrough: Bool = false
  
  var onPress_bold: () -> Void = {}
  var onPress_italic: () -> Void = {}
  var onPress_underline: () -> Void = {}
  var onPress_strikethrough: () -> Void = {}
  var onPress_indent: () -> Void = {}
  var onPress_outdent: () -> Void = {}
    var onPress_orderedList: () -> Void = {}
  var onPress_unorderedList: () -> Void = {}
  
  var body: some View {
    let insetDivider = Divider().padding(.vertical, 8)
    //ScrollView(.horizontal) {
    return VStack(spacing: 0) {
      Divider()
      GeometryReader { geom in
        //ScrollView(.horizontal) {
          HStack(spacing: 4) {
            Group {
              self.button(icon: Image(systemName: "bold"), action: self.onPress_bold, highlighted: self.state_bold)
              insetDivider
              self.button(icon: Image(systemName: "italic"), action: self.onPress_italic, highlighted: self.state_italic)
              insetDivider
              self.button(icon: Image(systemName: "underline"), action: self.onPress_underline, highlighted: self.state_underline)
              insetDivider
              self.button(icon: Image(systemName: "strikethrough"), action: self.onPress_strikethrough, highlighted: self.state_strikethrough)
            }
            Divider()
            Spacer()
            Divider()
            Group {
              self.button(icon: Image(systemName: "list.bullet"), action: self.onPress_unorderedList, highlighted: false)
              insetDivider
                self.button(icon: Image(systemName: "list.number"), action: self.onPress_orderedList, highlighted: false)
              insetDivider
              self.button(icon: Image(systemName: "decrease.indent"), action: self.onPress_outdent)
              insetDivider
              self.button(icon: Image(systemName: "increase.indent"), action: self.onPress_indent)
            }
            Divider()
            Divider()
            self.button(icon:
                Image(systemName: "keyboard.chevron.compact.down")
                    .foregroundColor(.black),
                        action: {
                self.textView?.resignFirstResponder()
            })
          }
          .padding(.horizontal, 4)
        //}
      }
      .frame(maxWidth: 1000) //Avoid strange scrollView crash
      .frame(height: 40)
      .background(Color(.secondarySystemBackground))
    }
    .edgesIgnoringSafeArea(.bottom)
  }
  
    func button<Label: View>(icon: Label, action: @escaping () -> Void, highlighted: Bool = false) -> some View {
    Button(action: action) {
      icon
        .frame(minWidth: 30, minHeight: 36)
        .background(RoundedRectangle(cornerRadius: 4).fill(highlighted ? Color(.tertiarySystemBackground) : .clear))
        .contentShape(Rectangle())
    }
  }
}

struct RichTextToolbar_Previews: PreviewProvider {
  static var previews: some View {
    RichTextToolbarView(state_italic: true)
  }
}
