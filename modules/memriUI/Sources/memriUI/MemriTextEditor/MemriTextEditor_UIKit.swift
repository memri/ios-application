//
//  RichTextView.swift
//  MemriPlayground
//
//  Created by Toby Brennan

import Foundation
import SwiftUI
import UIKit

public class MemriTextEditorWrapper_UIKit: UIView {
	// This UIView allows us to add overlays to the UITextView if needed
	var textEditor: MemriTextEditor_UIKit

	init(_ textEditor: MemriTextEditor_UIKit) {
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

	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public var intrinsicContentSize: CGSize {
		textEditor.intrinsicContentSize
	}

	override public func contentHuggingPriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
		textEditor.contentHuggingPriority(for: axis)
	}

	override public func contentCompressionResistancePriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
		textEditor.contentCompressionResistancePriority(for: axis)
	}
}

public class MemriTextEditor_UIKit: UITextView {
	var preferredHeightBinding: Binding<CGFloat>?
	var defaultFontSize: CGFloat = 17
	var onTextChanged: ((NSAttributedString) -> Void)?
	var isEditingBinding: Binding<Bool>? {
		didSet {
			if let bindingIsEditing = isEditingBinding?.wrappedValue, bindingIsEditing != isEditing {
				if bindingIsEditing {
					becomeFirstResponder()
				} else {
					resignFirstResponder()
				}
			}
		}
	}

	private var isEditing: Bool = false

	public init(initialContentHTML: String?) {
		super.init(frame: .zero, textContainer: nil)
		if let htmlData = initialContentHTML?.data(using: .utf8) {
			DispatchQueue.main.async {
				if let attributedStringFromHTML = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
					self.attributedText = attributedStringFromHTML.withFontSize(self.defaultFontSize)
				}
			}
		}
		configure()
	}

	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configure() {
		// Allow editing attributes
		allowsEditingTextAttributes = true

		// Scroll to dismiss keyboard
		keyboardDismissMode = .interactive
		alwaysBounceVertical = true

		// Set up toolbar
		updateToolbar()

		// Set up default sizing
		let defaultFont = UIFont.systemFont(ofSize: defaultFontSize)
		font = defaultFont
		typingAttributes = [
			.font: defaultFont,
		]

		delegate = self
		layoutManager.delegate = self
	}

	let indentWidth: CGFloat = 20

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

	var toolbarHost: UIHostingController<RichTextToolbarView>?

	func updateToolbar() {
		let view = RichTextToolbarView(
			textView: self,
			state_bold: state_isBold,
			state_italic: state_isItalic,
			state_underline: state_isUnderlined,
			state_strikethrough: state_isStrikethrough,
			onPress_bold: action_toggleBold,
			onPress_italic: action_toggleItalic,
			onPress_underline: action_toggleUnderlined,
			onPress_strikethrough: action_toggleStrikethrough,
			onPress_indent: action_indent,
			onPress_outdent: action_outdent,
			onPress_orderedList: action_orderedList,
			onPress_unorderedList: action_unorderedList
		)
		if let hc = toolbarHost {
			hc.rootView = view
		} else {
			let toolbarHost = UIHostingController(rootView: view)
			#if targetEnvironment(macCatalyst)
				if let superview = superview {
					superview.addSubview(toolbarHost.view)
					let macToolbarHeight: CGFloat = 50
					toolbarHost.view.translatesAutoresizingMaskIntoConstraints = false
					NSLayoutConstraint.activate([
						toolbarHost.view.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0),
						toolbarHost.view.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0),
						toolbarHost.view.heightAnchor.constraint(equalToConstant: macToolbarHeight),
						toolbarHost.view.topAnchor.constraint(equalTo: superview.topAnchor),
					])
					contentInset.top = macToolbarHeight
					self.toolbarHost = toolbarHost
				}
			#else
				toolbarHost.view.sizeToFit()
				inputAccessoryView = toolbarHost.view
				self.toolbarHost = toolbarHost
			#endif
		}
	}

	func fireTextChange() {
		onTextChanged?(attributedText)
	}

	func didChangeFormatting() {
		updateToolbar()
		fireTextChange()
	}

	func selectionDidChange() {
		updateToolbar()
	}

	public func textViewDidChange(_: UITextView) {
		fireTextChange()
		updateToolbar()
	}

	override public var selectedTextRange: UITextRange? {
		didSet {
			selectionDidChange()
		}
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

	override public func toggleBoldface(_ sender: Any?) {
		super.toggleBoldface(sender)
		fireTextChange() // TextView didChange not called otherwise
	}

	override public func toggleItalics(_ sender: Any?) {
		super.toggleItalics(sender)
		fireTextChange() // TextView didChange not called otherwise
	}

	override public func toggleUnderline(_ sender: Any?) {
		super.toggleUnderline(sender)
		fireTextChange() // TextView didChange not called otherwise
	}
}

extension MemriTextEditor_UIKit: NSLayoutManagerDelegate {
	public func layoutManager(
		_: NSLayoutManager,
		didCompleteLayoutFor textContainer: NSTextContainer?,
		atEnd _: Bool
	) {
		if
			let desiredHeight = textContainer?.size.height,
			let heightBinding = preferredHeightBinding,
			heightBinding.wrappedValue != desiredHeight {
			DispatchQueue.main.async {
				heightBinding.wrappedValue = desiredHeight
			}
		}
	}
}

extension MemriTextEditor_UIKit: UITextViewDelegate {
	public func textView(_: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text.isEmpty, range.length <= 1 {
			// User pressed backspace
			return handleBackspace(changedRange: range, replacementText: text)
		}

		if text.last?.isNewline ?? false {
			// New line, hook here if we need (eg. change from header to body)
			return handleNewLine(changedRange: range, replacementText: text)
		}

		if text == "\t", range.length == 0 {
			// TAB
			return handleTab(changedRange: range, replacementText: text)
		}

		if text.last == " " {
			// Space - check if dash for list
			return handleSpace(changedRange: range, replacementText: text)
		}

		return true
	}

	func handleTab(changedRange range: NSRange, replacementText _: String) -> Bool {
		let currentLineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: range.location, length: 0))
		let currentLineString = (textStorage.string as NSString).substring(with: currentLineRange) as NSString

		let lineContentWithoutList = NSMutableString(string: currentLineString)
		ListType.removeListText(in: lineContentWithoutList)

		if (lineContentWithoutList as String).isOnlyWhitespace {
			helper_shiftIndent(by: 1)
			return false
		}
		return true
	}

	func handleSpace(changedRange range: NSRange, replacementText _: String) -> Bool {
		let currentLineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: range.location, length: 0))
		let currentLineString = (textStorage.string as NSString).substring(with: currentLineRange) as NSString

		if currentLineString.trimmingCharacters(in: .whitespacesAndNewlines) == "-" {
			textStorage.beginEditing()
			let newString = ListType.unorderedList.stringForLine(index: 0) as NSString
			textStorage.replaceCharacters(in: currentLineRange, with: newString as String)
			textStorage.endEditing()
			selectedRange = NSRange(location: currentLineRange.location + newString.length, length: 0)
			return false
		}
		return true
	}

	func handleBackspace(changedRange range: NSRange, replacementText _: String) -> Bool {
		let currentLineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: range.location, length: 0))
		let currentLineString = (textStorage.string as NSString).substring(with: currentLineRange) as NSString

		let lineContentWithoutList = NSMutableString(string: currentLineString)
		ListType.removeListText(in: lineContentWithoutList)

		if (lineContentWithoutList as String).isOnlyWhitespace {
			// Empty line in list, remove it
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: currentLineRange, with: "")
			textStorage.endEditing()
			selectedRange = NSRange(location: max(0, currentLineRange.location - 1), length: 0)
			return false
		}
		return true
	}

	func handleNewLine(changedRange range: NSRange, replacementText newText: String) -> Bool {
		let oldLineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: range.location, length: 0))
		let oldLineString = (textStorage.string as NSString).substring(with: oldLineRange) as NSString
		let oldLineListType = ListType.getListType(oldLineString)

		let oldLineContentWithoutList = NSMutableString(string: oldLineString)
		ListType.removeListText(in: oldLineContentWithoutList)

		let oldLineIsEmpty = (oldLineContentWithoutList as String).isOnlyWhitespace

		if oldLineIsEmpty {
			switch oldLineListType {
			case .some:
				if oldLineListType == .unorderedList, helper_currentIndent() != 0 {
					// Empty line, reduce indent
					helper_shiftIndent(by: -1)
					return false
				} else {
					// Empty line, remove the list
					textStorage.beginEditing()
					textStorage.replaceCharacters(in: oldLineRange, with: "\n")
					textStorage.endEditing()
					selectedRange = NSRange(location: oldLineRange.location, length: 0)
					return false
				}
			case .none:
				return true
			}
		}

		var textToInsert: String?
		switch oldLineListType {
		case .unorderedList:
			textToInsert = ListType.unorderedList.stringForLine(index: 0)
		case .orderedList:
			let oldIndex = (oldLineString as String).split(separator: Character(".")).first.flatMap { Int($0) } ?? 0
			textToInsert = ListType.orderedList.stringForLine(index: oldIndex + 1)
		default: break
		}

		if let textToInsert = textToInsert {
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: range, with: newText + textToInsert)
			textStorage.endEditing()
			selectedRange = NSRange(location: range.upperBound + 1 + (textToInsert as NSString).length, length: 0)
			return false
		} else {
			return true
		}
	}
}

extension MemriTextEditor_UIKit {
	var helper_hasSelection: Bool {
		selectedRange.length != 0
	}

	var state_isBold: Bool {
		helper_currentContext_hasFontTrait(.traitBold)
	}

	func action_toggleBold() {
		helper_currentContext_toggleFontTrait(.traitBold)
		didChangeFormatting()
	}

	var state_isItalic: Bool {
		helper_currentContext_hasFontTrait(.traitItalic)
	}

	func action_toggleItalic() {
		helper_currentContext_toggleFontTrait(.traitItalic)
		didChangeFormatting()
	}

	func action_indent() {
		helper_shiftIndent(by: 1)
		didChangeFormatting()
	}

	func action_outdent() {
		helper_shiftIndent(by: -1)
		didChangeFormatting()
	}

	func action_unorderedList() {
		helper_makeSelectionList(type: .unorderedList)
		didChangeFormatting()
	}

	func action_orderedList() {
		helper_makeSelectionList(type: .orderedList)
		didChangeFormatting()
	}

	var state_isUnderlined: Bool {
		if let style: NSNumber = helper_currentContext_getTrait(.underlineStyle) {
			return style != 0
		} else {
			return false
		}
	}

	func action_toggleUnderlined() {
		helper_currentContext_setTrait(.underlineStyle, value: state_isUnderlined ? nil : NSUnderlineStyle.single.rawValue)
		didChangeFormatting()
	}

	var state_isStrikethrough: Bool {
		if let style: NSNumber = helper_currentContext_getTrait(.strikethroughStyle) {
			return style != 0
		} else {
			return false
		}
	}

	func action_toggleStrikethrough() {
		helper_currentContext_setTrait(.strikethroughStyle, value: state_isStrikethrough ? nil : NSUnderlineStyle.single.rawValue)
		didChangeFormatting()
	}
}

extension MemriTextEditor_UIKit {
	func helper_currentContext_getTrait<T>(_ trait: NSAttributedString.Key) -> T? {
		if helper_hasSelection {
			return helper_selectedText_getTrait(trait)
		} else {
			return helper_typingAttributes_getTrait(trait)
		}
	}

	func helper_currentContext_setTrait<T>(_ trait: NSAttributedString.Key, value: T?) {
		if helper_hasSelection {
			helper_selectedText_setTrait(trait, value: value)
		} else {
			helper_typingAttributes_setTrait(trait, value: value)
		}
	}

	func helper_currentContext_hasFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
		if helper_hasSelection {
			return helper_selectedText_hasFontTrait(trait)
		} else {
			return helper_typingAttributes_hasFontTrait(trait)
		}
	}

	func helper_currentContext_toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
		if helper_hasSelection {
			helper_selectedText_toggleFontTrait(trait)
		} else {
			helper_typingAttributes_toggleFontTrait(trait)
		}
	}

	func helper_selectedText_getTrait<T>(_ trait: NSAttributedString.Key) -> T? {
		textStorage.attribute(trait, at: selectedRange.location, effectiveRange: nil) as? T
	}

	func helper_selectedText_setTrait<T>(_ trait: NSAttributedString.Key, value: T?) {
		textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
			textStorage.beginEditing()
			if let value = value {
				textStorage.addAttribute(trait, value: value, range: range)
			} else {
				textStorage.removeAttribute(trait, range: range)
			}
			textStorage.endEditing()
		}
	}

	func helper_selectedText_hasFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
		(textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont)?.helper_hasTrait(trait) ?? false
	}

	func helper_selectedText_toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
		guard helper_hasSelection else { return }
		textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
			guard let currentFont = textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont else { return }
			textStorage.beginEditing()
			let newFont = currentFont.helper_toggleTrait(trait: trait)
			textStorage.addAttribute(.font, value: newFont, range: range)
			textStorage.endEditing()
		}
	}

	func helper_typingAttributes_getTrait<T>(_ trait: NSAttributedString.Key) -> T? {
		typingAttributes[trait] as? T
	}

	func helper_typingAttributes_setTrait<T>(_ trait: NSAttributedString.Key, value: T?) {
		typingAttributes[trait] = value
	}

	func helper_typingAttributes_hasFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
		(typingAttributes[NSAttributedString.Key.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(trait) ?? false
	}

	func helper_typingAttributes_toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
		typingAttributes[NSAttributedString.Key.font] = (typingAttributes[NSAttributedString.Key.font] as? UIFont)?.helper_toggleTrait(trait: trait)
	}
}

extension MemriTextEditor_UIKit {
	func helper_currentIndent() -> CGFloat {
		let stringStore = textStorage.string as NSString
		let paragraphRange = stringStore.paragraphRange(for: selectedRange)

		let currentAttributes = textStorage.attributes(at: paragraphRange.location, effectiveRange: nil)

		guard let paragraphStyle = currentAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle else { return 0 }
		return paragraphStyle.headIndent
	}

	func helper_shiftIndent(by indentChangeAmount: Int) {
		let stringStore = textStorage.string as NSString
		let paragraphRange = stringStore.paragraphRange(for: selectedRange)
		let isEmptyPara = stringStore.substring(with: paragraphRange).isEmpty

		let currentStyle: NSParagraphStyle?
		if isEmptyPara {
			currentStyle = typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
		} else {
			currentStyle = textStorage.attributes(at: paragraphRange.location, effectiveRange: nil)[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
		}

		let newStyle = (currentStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
		newStyle.headIndent = max(0, ((newStyle.headIndent / indentWidth).rounded(.down) + CGFloat(indentChangeAmount)) * CGFloat(indentWidth))
		newStyle.firstLineHeadIndent = newStyle.headIndent

		if isEmptyPara {
			typingAttributes[NSAttributedString.Key.paragraphStyle] = newStyle
		} else {
			textStorage.beginEditing()
			textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: newStyle, range: paragraphRange)
			textStorage.endEditing()
		}
	}
}

extension MemriTextEditor_UIKit {
	func helper_makeSelectionList(type: ListType) {
		// Find the range of selected lines
		// var startOfFirstLine: Int = 0, endOfLastLine: Int = 0
		let paragraphRange = (textStorage.string as NSString).paragraphRange(for: selectedRange)

		//    .getLineStart(&startOfFirstLine, end: &endOfLastLine, contentsEnd: nil, for: selectedRange)

		// Create storage for modified lines
		var modifiedParagraphs: [NSAttributedString] = []

		// Iterate through the lines
		var lineIndex = 1
		var currentParaStart = paragraphRange.location
		while currentParaStart <= paragraphRange.upperBound {
			let currentLineRange = (textStorage.string as NSString).paragraphRange(for: NSRange(location: currentParaStart, length: 0))
			guard let string = textStorage.attributedSubstring(from: currentLineRange).mutableCopy() as? NSMutableAttributedString else { continue }

			var attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: defaultFontSize)]

			if !string.string.isEmpty {
				attributes[.paragraphStyle] = string.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle
			}

			// MODIFY HERE
			ListType.removeListText(in: string.mutableString)
			string.insert(NSAttributedString(string: type.stringForLine(index: lineIndex), attributes: attributes), at: 0)

			// Append modified string
			modifiedParagraphs.append(string)
			currentParaStart = currentLineRange.upperBound + 1
			lineIndex += 1
		}

		// Join lines back together
		let modifiedSection = modifiedParagraphs.reduce(into: NSMutableAttributedString()) { result, line in
			result.append(line)
		}

		// Apply changes
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: paragraphRange,
									  with: modifiedSection)
		textStorage.endEditing()
		selectedRange = NSRange(location: paragraphRange.lowerBound + modifiedSection.length - 1, length: 0)
	}
}

extension MemriTextEditor_UIKit {
	enum ListType {
		case unorderedList
		case orderedList

		var expression: NSRegularExpression? {
			switch self {
			case .unorderedList:
				return try? NSRegularExpression(pattern: "^\\s*[-*••∙●][ \t]", options: .caseInsensitive)
			case .orderedList:
				return try? NSRegularExpression(pattern: "^\\s*\\d*\\.[ \t]", options: .caseInsensitive)
			}
		}

		func stringForLine(index: Int) -> String {
			switch self {
			case .unorderedList:
				return "• "
			case .orderedList:
				return "\(index). "
			}
		}

		func checkIfHasMatch(in string: NSString) -> Bool {
			let range = NSMakeRange(0, string.length)
			guard let expression = expression else {
				return false
			}
			return expression.firstMatch(in: String(string), options: [], range: range) != nil
		}

		func removeMatches(in mutableString: NSMutableString) {
			guard let expression = expression else {
				return
			}
			let range = NSMakeRange(0, mutableString.length)
			expression.replaceMatches(in: mutableString, options: [], range: range, withTemplate: "")
		}

		static func getListType(_ string: NSString) -> ListType? {
			[Self.unorderedList, .orderedList].first { $0.checkIfHasMatch(in: string) }
		}

		static func removeListText(in mutableString: NSMutableString) {
			[Self.unorderedList, .orderedList].forEach { $0.removeMatches(in: mutableString) }
		}
	}
}
