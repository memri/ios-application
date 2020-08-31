//
//  LabelAnnotationRenderer.swift
//  memri
//
//  Created by Toby Brennan on 26/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct LabelOption {
    var labelID: String
    var text: String
    var icon: Image
    
    var id: String { text }
}
class LabelAnnotationRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "labelAnnotation", icon: "tag.circle.fill", makeController: LabelAnnotationRendererController.init, makeConfig: LabelAnnotationRendererController.makeConfig)
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? LabelAnnotationRendererConfig) ?? LabelAnnotationRendererConfig()
    }
    
    let context: MemriContext
    let config: LabelAnnotationRendererConfig
    
    func makeView() -> AnyView {
        LabelAnnotationRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        LabelAnnotationRendererConfig(head, tail, host)
    }
    
    @Published
    var currentIndex: Int = .zero
    
    @Published
    var selectedLabels = Set<String>()
    
    var options: [LabelOption] = [
        LabelOption(labelID: "personal", text: "Personal", icon: Image(systemName: "person.circle")),
        LabelOption(labelID: "important", text: "Important", icon: Image(systemName: "bell")),
        LabelOption(labelID: "bill", text: "Bill", icon: Image(systemName: "creditcard")),
        LabelOption(labelID: "receipt", text: "Receipt", icon: Image(systemName: "cart")),
        LabelOption(labelID: "spam", text: "Spam", icon: Image(systemName: "hand.thumbsdown"))
    ]
    
    func moveToPreviousItem() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    func moveToNextItem() {
        guard currentIndex < context.items.endIndex - 1 else { return }
        selectedLabels.removeAll()
        currentIndex += 1
    }
    
    func applyCurrentItem() {
        print("Labels confirmed: \(selectedLabels)")
        moveToNextItem()
    }
    
    var currentItem: Item? {
        context.items[safe: currentIndex]
    }
    
    var currentRenderedItem: some View {
        config.render(item: currentItem)
            .environmentObject(context)
    }
    
    
    var progressText: String? {
        guard !context.items.isEmpty else { return nil }
        return "Item \(currentIndex + 1) of \(context.items.count)"
    }
}


class LabelAnnotationRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var showSortInConfig: Bool = false
    var showContextualBarInEditMode: Bool = false
    
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }
}


struct LabelAnnotationRendererView: View {
    @ObservedObject var controller : LabelAnnotationRendererController
    
    
    @ViewBuilder
    var currentContent: some View {
        if controller.currentItem != nil {
            controller.currentRenderedItem
        } else {
            Text("No items to label")
                .bold()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
    
    var selectedLabelBinding: Binding<Set<String>> {
        Binding(
            get: { self.controller.selectedLabels },
            set: {
                self.controller.selectedLabels = $0
        })
    }
    
    var body: some View {
        LabelSelectionView(options: controller.options,
                           selected: selectedLabelBinding,
                           enabled: controller.currentItem != nil,
                           onBackPressed: controller.moveToPreviousItem,
                           onCheckmarkPressed: controller.applyCurrentItem,
                           onSkipPressed: controller.moveToNextItem,
                           topText: controller.progressText,
                           content: currentContent,
                           useScrollView: false)
    }
}

struct LabelSelectionView<Content: View>: View {
    var options: [LabelOption]
    
    @Binding var selected: Set<String>
    var enabled: Bool
    
    var onBackPressed: () -> Void
    var onCheckmarkPressed: () -> Void
    var onSkipPressed: () -> Void
    
    var topText: String?
    
    var content: Content
    var useScrollView: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            topText.map { topText in
                Text(topText)
                    .font(Font.body.monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground))
            }
            if topText != nil {
                Divider()
            }
            if useScrollView {
                GeometryReader { geometry in
                    ScrollView(.vertical) {
                        self.content
                            .frame(width: geometry.size.width)
                    }
                }
            } else {
                self.content
            }
            SwiftUI.List {
                ForEach(options, id: \.id) { option in
                    Button(action: {
                        if self.selected.remove(option.id) == nil {
                            self.selected.insert(option.id)
                        }
                    }) {
                        HStack {
                            option.icon
                            Text(option.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .if(self.selected.contains(option.id)) {
                            $0
                                .foregroundColor(.white)
                                .background(Color.blue.cornerRadius(4).padding(-5))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .opacity(enabled ? 1 : 0.4)
            .frame(height: 220)
            .clipShape(RoundedCornerRectangle(radius: 20, corners: [.topLeft, .topRight]))
            .background(
                RoundedCornerRectangle(radius: 20, corners: [.topLeft, .topRight])
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10))
            Divider()
            HStack(spacing: 0) {
                Button(action: onBackPressed) {
                    Image(systemName: "arrow.uturn.left").font(.system(size: 20))
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                }
                Button(action: onCheckmarkPressed) {
                    Image(systemName: "checkmark").font(.system(size: 25))
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .contentShape(Rectangle())
                }
                Button(action: onSkipPressed) {
                    Text("Skip").font(.system(size: 20))
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                }
            }
            .opacity(enabled ? 1 : 0.4)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
        }
        .disabled(!enabled)
    }
}
