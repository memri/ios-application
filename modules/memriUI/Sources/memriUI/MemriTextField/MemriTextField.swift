//
//  MemriTextField.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 14/6/20.
//

import Foundation
import SwiftUI

public struct MemriTextField<Value: Equatable>: UIViewRepresentable
{
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
    
    private var onEditingBeganCallback: (() -> Void)?
    
    @Environment(\.multilineTextAlignment) var textAlignment
    
    var valueString: String?
    {
        get
        {
            valueToString(value)?
                .nilIfBlank
        }
        set
        {
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
        assignIfChanged(textField, \.textColor, newValue: self.textColor ?? .label)
        assignIfChanged(textField, \.tintColor, newValue: self.tintColor)
        assignIfChanged(textField, \.attributedPlaceholder, newValue: self.placeholder.map {
            NSAttributedString(string: $0, attributes: [.foregroundColor : (self.textColor ?? .label).withAlphaComponent(0.5)])
        })
        if allowEmpty || !(textField.isEditing && textField.text?.isOnlyWhitespace ?? true)
        {
            assignIfChanged(textField, \.text, newValue: self.valueString)
        }
        
        if self.font != nil
        {
            assignIfChanged(textField, \.font, newValue: self.font)
        }
        assignIfChanged(textField, \.clearButtonMode, newValue: self.clearButtonMode)
        assignIfChanged(textField, \.keyboardType, newValue: self.keyboardType)
        assignIfChanged(textField, \.returnKeyType, newValue: self.returnKeyType)
        assignIfChanged(textField, \.textAlignment, newValue: self.textAlignment.nsTextAlignment)
        assignIfChanged(textField, \.showPrevNextButtons, newValue: self.showPrevNextButtons)
    }
    
    public func makeCoordinator() -> Delegate {
        Delegate(parent: self)
    }
    
    // Modifier
    func onEditingBegan(_ callback: @escaping () -> Void) -> Self
    {
        var this = self
        this.onEditingBeganCallback = callback
        return this
    }
    
    public class Delegate: NSObject, UITextFieldDelegate
    {
        init(parent: MemriTextField<Value>)
        {
            self.parent = parent
        }
        
        var parent: MemriTextField
        
        weak var view: MemriTextField_UIKit?
            {
            didSet
            {
                if view != oldValue
                {
                    oldValue?.removeTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                    view?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                }
            }
        }
        
        public func textFieldDidBeginEditing(_ textField: UITextField)
        {
            parent.onEditingBeganCallback?()
            if parent.selectAllOnEdit
            {
                textField.selectAll(nil)
            }
        }
        
        public func textFieldDidEndEditing(_ textField: UITextField)
        {
            parent.valueString = textField.text?.nilIfBlank
            assignIfChanged(textField, \.text, newValue: parent.valueString)
            textField.resignFirstResponder()
        }
        
        @objc
        func textFieldDidChange(_ textField: MemriTextField_UIKit)
        {
            parent.valueString = textField.text?.nilIfBlank
        }
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
        {
            guard !string.isEmpty else
            {
                return true
            }
            
            if let allowedCharacters = parent.allowedCharacters
            {
                if let rangeOfCharactersAllowed = string.rangeOfCharacter(from: allowedCharacters, options: .caseInsensitive)
                {
                    // make sure it's all of them
                    let validCharacterCount = string.distance(from: rangeOfCharactersAllowed.lowerBound, to: rangeOfCharactersAllowed.upperBound)
                    return validCharacterCount == string.count
                }
                else
                {
                    return false
                }
            }
            return true
        }
        
        public func textFieldShouldReturn(_ textField: UITextField) -> Bool
        {
            textField.moveToNextResponder()
            return true
        }
    }
}

public extension MemriTextField where Value == String?
{
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
        selectAllOnEdit: Bool = false
    )
    {
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
    }
}
public extension MemriTextField where Value == String
{
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
        selectAllOnEdit: Bool = false
    )
    {
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
    }
}

public extension MemriTextField where Value == Int
{
    init(
        value: Binding<Int>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        selectAllOnEdit: Bool = false
    )
    {
        _value = value
        valueToString = { "\($0)" }
        stringToValue = { $0.flatMap { Int($0) } ?? 0 }
        self.placeholder = placeholder
        self.textColor = textColor
        allowedCharacters = .decimalDigits
        keyboardType = .numberPad
        returnKeyType = .done
        self.selectAllOnEdit = selectAllOnEdit
    }
}

public extension MemriTextField where Value == Double
{
    init(
        value: Binding<Double>,
        placeholder: String? = nil,
        textColor: UIColor? = nil,
        selectAllOnEdit: Bool = false
    )
    {
        _value = value
        valueToString = { "\($0)" }
        stringToValue = { $0.flatMap { Double($0) } ?? 0 }
        self.placeholder = placeholder
        self.textColor = textColor
        allowedCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
        keyboardType = .numberPad
        returnKeyType = .done
        self.selectAllOnEdit = selectAllOnEdit
    }
}

public extension MemriTextField
{
    func textFieldFont(_ font: UIFont) -> Self
    {
        var this = self
        this.font = font
        return this
    }
}

extension TextAlignment
{
    var nsTextAlignment: NSTextAlignment
    {
        switch self
        {
        case .center: return .center
        case .leading: return .left
        case .trailing: return .right
        }
    }
}

func assignIfChanged<T: Equatable>(_ theVar: inout T, newValue: T)
{
    guard newValue != theVar else { return }
    theVar = newValue
}

func assignIfChanged<Object: AnyObject, T: Equatable>(_ object: Object, _ keyPath: ReferenceWritableKeyPath<Object, T>, newValue: T)
{
    guard newValue != object[keyPath: keyPath] else { return }
    object[keyPath: keyPath] = newValue
}

extension Binding where Value: Equatable
{
    func assignIfChanged(_ newValue: Value)
    {
        if newValue != wrappedValue
        {
            wrappedValue = newValue
        }
    }
}

extension String {
    var nilIfBlank: String? {
        isOnlyWhitespace ? nil : self
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
    
    init() {
        super.init(frame: .zero)
        setContentHuggingPriority(.required, for: .vertical)
        updateToolbar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var toolbarHost: UIHostingController<KeyboardToolbarView>?
    
    func updateToolbar() {
        let view = KeyboardToolbarView(owner: self, showArrows: showPrevNextButtons)
        if let hc = toolbarHost {
            hc.rootView = view
        } else {
            toolbarHost = UIHostingController(rootView: view)
            toolbarHost?.view.sizeToFit()
            inputAccessoryView = toolbarHost?.view
        }
    }
}
