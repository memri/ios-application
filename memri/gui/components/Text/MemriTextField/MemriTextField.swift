//
// MemriTextField.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct MemriTextField<Value: Equatable>: UIViewRepresentable {
    @Binding
    var value: Value

    var valueToString: (Value) -> String?
    var stringToValue: (String?) -> Value
    var textColor: UIColor?
    var tintColor: UIColor?
    var placeholder: String?
    var allowEmpty: Bool = true
    var allowedCharacters: CharacterSet?
    var clearButtonMode: UITextField.ViewMode = .never
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var showPrevNextButtons: Bool = true
    var selectAllOnEdit: Bool = false
    var font: UIFont?

    var isEditing: Binding<Bool>?
    /// Allows making this textfield
    var isSharedEditingBinding: Bool
    private var onEditingBeganCallback: (() -> Void)?
    private var onEditingEndedCallback: (() -> Void)?

    @Environment(\.multilineTextAlignment) var textAlignment

    var valueString: String? {
        get {
            valueToString(value)?
                .nilIfBlank
        }
        set {
            let new = stringToValue(newValue)
            DispatchQueue.main.async
            { [_value] in
                _value.assignIfChanged(new)
            }
        }
    }

    public func makeUIView(context: Context) -> MemriTextField_UIKit {
        let tf = MemriTextField_UIKit()
        assignIfChanged(tf, \.borderStyle, newValue: .none)
        assignIfChanged(tf, \.backgroundColor, newValue: .clear)
        tf.delegate = context.coordinator
        context.coordinator.view = tf
        return tf
    }

    public func updateUIView(_ textField: MemriTextField_UIKit, context: Context) {
        context.coordinator.parent = self
        assignIfChanged(textField, \.textColor, newValue: textColor ?? .label)
        assignIfChanged(textField, \.tintColor, newValue: tintColor)
        assignIfChanged(textField, \.attributedPlaceholder, newValue: placeholder.map {
            NSAttributedString(
                string: $0,
                attributes: [.foregroundColor: (self.textColor ?? .label).withAlphaComponent(0.5)]
            )
        })
        if allowEmpty || !(textField.isEditing && textField.text?.isOnlyWhitespace ?? true) {
            assignIfChanged(textField, \.text, newValue: valueString)
        }

        if font != nil {
            assignIfChanged(textField, \.font, newValue: font)
        }
        assignIfChanged(textField, \.clearButtonMode, newValue: clearButtonMode)
        assignIfChanged(textField, \.keyboardType, newValue: keyboardType)
        assignIfChanged(textField, \.returnKeyType, newValue: returnKeyType)
        assignIfChanged(textField, \.textAlignment, newValue: textAlignment.nsTextAlignment)
        assignIfChanged(textField, \.showPrevNextButtons, newValue: showPrevNextButtons)
        textField.isSharedEditingBinding = isSharedEditingBinding
        textField.isEditingBinding = isEditing
    }

    public func makeCoordinator() -> Delegate {
        Delegate(parent: self)
    }

    // Modifier
    func onEditingBegan(_ callback: @escaping () -> Void) -> Self {
        var this = self
        this.onEditingBeganCallback = callback
        return this
    }

    func onEditingEnded(_ callback: @escaping () -> Void) -> Self {
        var this = self
        this.onEditingEndedCallback = callback
        return this
    }

    public class Delegate: NSObject, UITextFieldDelegate {
        init(parent: MemriTextField<Value>) {
            self.parent = parent
        }

        var parent: MemriTextField

        weak var view: MemriTextField_UIKit? {
            didSet {
                if view != oldValue {
                    oldValue?.removeTarget(
                        self,
                        action: #selector(textFieldDidChange(_:)),
                        for: .editingChanged
                    )
                    view?.addTarget(
                        self,
                        action: #selector(textFieldDidChange(_:)),
                        for: .editingChanged
                    )
                }
            }
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingBeganCallback?()
            if parent.isEditing?.wrappedValue == false {
                parent.isEditing?.wrappedValue = true
            }
            if parent.selectAllOnEdit {
                textField.selectAll(nil)
            }
        }

        public func textFieldDidEndEditing(_ textField: UITextField) {
            parent.valueString = textField.text?.nilIfBlank
            assignIfChanged(textField, \.text, newValue: parent.valueString)
            textField.resignFirstResponder()
            parent.onEditingEndedCallback?()
            if parent.isEditing?.wrappedValue == true {
                parent.isEditing?.wrappedValue = false
            }
        }

        @objc
        func textFieldDidChange(_ textField: MemriTextField_UIKit) {
            parent.valueString = textField.text?.nilIfBlank
        }

        public func textField(
            _: UITextField,
            shouldChangeCharactersIn _: NSRange,
            replacementString string: String
        ) -> Bool {
            guard !string.isEmpty else {
                return true
            }

            if let allowedCharacters = parent.allowedCharacters {
                if let rangeOfCharactersAllowed = string.rangeOfCharacter(
                    from: allowedCharacters,
                    options: .caseInsensitive
                ) {
                    // make sure it's all of them
                    let validCharacterCount = string.distance(
                        from: rangeOfCharactersAllowed.lowerBound,
                        to: rangeOfCharactersAllowed.upperBound
                    )
                    return validCharacterCount == string.count
                }
                else {
                    return false
                }
            }
            return true
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.moveToNextResponder()
            return true
        }
    }
}

public extension MemriTextField where Value == String? {
    init(
        value: Binding<String?>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        allowedCharacters: CharacterSet? = nil,
        clearButtonMode: UITextField.ViewMode = .never,
        keyboardType: UIKeyboardType = .default,
        returnKeyType: UIReturnKeyType = .default,
        showPrevNextButtons: Bool = true,
        selectAllOnEdit: Bool = false,
        isEditing: Binding<Bool>? = nil,
        isSharedEditingBinding: Bool = false
    ) {
        _value = value
        valueToString = { $0 }
        stringToValue = { $0 }
        self.placeholder = placeholder
        self.textColor = textColor
        self.tintColor = tintColor
        self.allowedCharacters = allowedCharacters
        self.clearButtonMode = clearButtonMode
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.showPrevNextButtons = showPrevNextButtons
        self.selectAllOnEdit = selectAllOnEdit
        self.isEditing = isEditing
        self.isSharedEditingBinding = isSharedEditingBinding
    }
}

public extension MemriTextField where Value == String {
    init(
        value: Binding<String>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        allowedCharacters: CharacterSet? = nil,
        clearButtonMode: UITextField.ViewMode = .never,
        keyboardType: UIKeyboardType = .default,
        returnKeyType: UIReturnKeyType = .default,
        showPrevNextButtons: Bool = true,
        selectAllOnEdit: Bool = false,
        isEditing: Binding<Bool>? = nil,
        isSharedEditingBinding: Bool = false
    ) {
        _value = value
        valueToString = { $0 }
        stringToValue = { $0 ?? "" }
        self.placeholder = placeholder
        self.textColor = textColor
        self.tintColor = tintColor
        self.allowedCharacters = allowedCharacters
        self.clearButtonMode = clearButtonMode
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.showPrevNextButtons = showPrevNextButtons
        self.selectAllOnEdit = selectAllOnEdit
        self.isEditing = isEditing
        self.isSharedEditingBinding = isSharedEditingBinding
    }
}

public extension MemriTextField where Value == Int {
    init(
        value: Binding<Int>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        clearButtonMode: UITextField.ViewMode = .never,
        selectAllOnEdit: Bool = false,
        isEditing: Binding<Bool>? = nil,
        isSharedEditingBinding: Bool = false
    ) {
        _value = value
        valueToString = { "\($0)" }
        stringToValue = { $0.flatMap { Int($0) } ?? 0 }
        self.placeholder = placeholder
        self.textColor = textColor
        self.clearButtonMode = clearButtonMode
        allowedCharacters = .decimalDigits
        keyboardType = .numberPad
        returnKeyType = .done
        self.selectAllOnEdit = selectAllOnEdit
        self.isEditing = isEditing
        self.isSharedEditingBinding = isSharedEditingBinding
    }
}

public extension MemriTextField where Value == Double {
    init(
        value: Binding<Double>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        clearButtonMode: UITextField.ViewMode = .never,
        selectAllOnEdit: Bool = false,
        isEditing: Binding<Bool>? = nil,
        isSharedEditingBinding: Bool = false
    ) {
        _value = value
        valueToString = { "\($0)" }
        stringToValue = { $0.flatMap { Double($0) } ?? 0 }
        self.placeholder = placeholder
        self.textColor = textColor
        self.clearButtonMode = clearButtonMode
        allowedCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
        keyboardType = .numberPad
        returnKeyType = .done
        self.selectAllOnEdit = selectAllOnEdit
        self.isEditing = isEditing
        self.isSharedEditingBinding = isSharedEditingBinding
    }
}

extension MemriTextField {
    public func textFieldFont(_ font: UIFont) -> Self {
        var this = self
        this.font = font
        return this
    }
}

extension TextAlignment {
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .center: return .center
        case .leading: return .left
        case .trailing: return .right
        }
    }
}

func assignIfChanged<Object: AnyObject, T: Equatable>(
    _ object: Object,
    _ keyPath: ReferenceWritableKeyPath<Object, T>,
    newValue: T
)
{
    guard newValue != object[keyPath: keyPath] else { return }
    object[keyPath: keyPath] = newValue
}

extension Binding where Value: Equatable {
    func assignIfChanged(_ newValue: Value) {
        if newValue != wrappedValue {
            wrappedValue = newValue
        }
    }
}

public class MemriTextField_UIKit: UITextField {
    var showPrevNextButtons: Bool = true {
        didSet {
            if showPrevNextButtons != oldValue {
                updateToolbar()
            }
        }
    }
    
    /// If this is set to true, the textfield won't respond to isEditing being set to true (but will resign responder if isEditing is set to false - useful for shared binding with other fields)
    var isSharedEditingBinding: Bool = false
    
    var isEditingBinding: Binding<Bool>? {
        didSet {
            if let bindingIsEditing = isEditingBinding?.wrappedValue,
                bindingIsEditing != isEditing,
                !isSharedEditingBinding || (isSharedEditingBinding && !bindingIsEditing) // If shared, only use for resigning first responder
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

    init() {
        super.init(frame: .zero)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        updateToolbar()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var toolbarHost: UIHostingControllerNoSafeArea<KeyboardToolbarView>?

    func updateToolbar() {
        let view = KeyboardToolbarView(owner: self, showArrows: showPrevNextButtons)
        if let hc = toolbarHost {
            hc.rootView = view
        }
        else {
            toolbarHost = UIHostingControllerNoSafeArea(rootView: view)
            toolbarHost?.view.sizeToFit()
            inputAccessoryView = toolbarHost?.view
        }
    }

    var showBottomBorder: Bool = false {
        didSet {
            if showBottomBorder {
                if bottomBorderLayer == nil {
                    let borderLayer = CALayer()
                    layer.addSublayer(borderLayer)
                    bottomBorderLayer = borderLayer
                }
                bottomBorderLayer?.backgroundColor = UIColor.separator.cgColor
                bottomBorderLayer?.opacity = 0.5
            }
            else {
                bottomBorderLayer?.removeFromSuperlayer()
                bottomBorderLayer = nil
            }
        }
    }

    var bottomBorderLayer: CALayer?

    override public func layoutSubviews() {
        super.layoutSubviews()
        bottomBorderLayer?.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
    }
}
