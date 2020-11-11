//
// MemriFittedTextEditor_UIKit.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI
import UIKit

public class MemriFittedTextEditorWrapper_UIKit: UIView {
    // This UIView allows us to add overlays to the UITextView if needed
    var textEditor: MemriFittedTextEditor_UIKit

    init(_ textEditor: MemriFittedTextEditor_UIKit) {
        self.textEditor = textEditor
        super.init(frame: .zero)
        addSubview(textEditor)
        textEditor.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textEditor.leadingAnchor.constraint(equalTo: leadingAnchor),
            textEditor.trailingAnchor.constraint(equalTo: trailingAnchor),
            textEditor.topAnchor.constraint(equalTo: topAnchor),
            textEditor.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        textEditor.intrinsicContentSize
    }

    override public func contentHuggingPriority(
        for axis: NSLayoutConstraint
            .Axis
    ) -> UILayoutPriority {
        textEditor.contentHuggingPriority(for: axis)
    }

    override public func contentCompressionResistancePriority(
        for axis: NSLayoutConstraint
            .Axis
    ) -> UILayoutPriority {
        textEditor.contentCompressionResistancePriority(for: axis)
    }
}

public class MemriFittedTextEditor_UIKit: UITextView, UITextViewDelegate {
    var preferredHeightBinding: Binding<CGFloat>?
    var fontSize: CGFloat
    var onTextChanged: ((String) -> Void)?

    var isEditingBinding: Binding<Bool>? {
        didSet {
            if let bindingIsEditing = isEditingBinding?.wrappedValue,
               bindingIsEditing != isEditing
            {
                if bindingIsEditing {
                    becomeFirstResponder()
                }
                else {
                    resignFirstResponder()
                }
            }
        }
    }

    func updateTextIfNotEditing(_ newText: String?) {
        if text != newText {
            text = newText
        }
    }

    private var isEditing: Bool = false

    public init(
        textContent: String?,
        fontSize: CGFloat = 18,
        backgroundColor: CVUColor?
    ) {
        self.fontSize = fontSize

        super.init(frame: .zero, textContainer: nil)

        text = textContent

        // Allow editing attributes
        allowsEditingTextAttributes = false

        // Scroll to dismiss keyboard
        keyboardDismissMode = .none

        // Set background color
        backgroundColor.map { self.backgroundColor = $0.uiColor }

        // Set up toolbar
        updateToolbar()

        font = UIFont.systemFont(ofSize: fontSize)

        delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var toolbarInset: CGFloat {
//        #if targetEnvironment(macCatalyst)
//            return 50
//        #else
        0
//        #endif
    }

    var preferredContentInset: UIEdgeInsets {
        UIEdgeInsets(top: 5 + toolbarInset,
                     left: 5,
                     bottom: 5,
                     right: 5)
    }

    override public func layoutSubviews() {
        textContainerInset = preferredContentInset
        super.layoutSubviews()

        if let heightBinding = preferredHeightBinding {
            let desiredHeight = getTextContentSize().height
            if heightBinding.wrappedValue != desiredHeight {
                DispatchQueue.main.async {
                    heightBinding.wrappedValue = desiredHeight
                }
            }
        }
    }

    #if targetEnvironment(macCatalyst)
        @objc(_focusRingType)
        var focusRingType: UInt {
            1 // NSFocusRingTypeNone
        }
    #endif

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        #if targetEnvironment(macCatalyst)
            updateToolbar()
        #endif
    }

    var toolbarHost: UIHostingControllerNoSafeArea<MemriFittedTextEditorToolbar>?
    private var toolbarWrapperView: ToolbarWrapperView?

    func updateToolbar() {
        let view = MemriFittedTextEditorToolbar(owner: self)
        if let hc = toolbarHost {
            hc.rootView = view
        }
        else {
            let toolbarHost = UIHostingControllerNoSafeArea(rootView: view)
            let toolbarWrapperView = ToolbarWrapperView(toolbarView: toolbarHost.view)
            toolbarWrapperView.sizeToFit()
            inputAccessoryView = toolbarWrapperView
            self.toolbarHost = toolbarHost
            self.toolbarWrapperView = toolbarWrapperView
        }
    }

    func fireTextChange() {
        onTextChanged?(text)
    }

    public func textViewDidChange(_: UITextView) {
        fireTextChange()
    }

    public func textViewDidBeginEditing(_: UITextView) {
        isEditing = true
        if let isEditingBinding = isEditingBinding, isEditingBinding.wrappedValue != true {
            DispatchQueue.main.async {
                isEditingBinding.wrappedValue = true
            }
        }
    }

    public func textViewDidEndEditing(_: UITextView) {
        isEditing = false
        if let isEditingBinding = isEditingBinding, isEditingBinding.wrappedValue != false {
            DispatchQueue.main.async {
                isEditingBinding.wrappedValue = false
            }
        }
    }

    public func getTextContentSize() -> CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: CGFloat.infinity))
        return .init(width: size.width, height: max(size.height, 30))
    }
}
