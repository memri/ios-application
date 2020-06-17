//
//  RichTextView.swift
//  MemriPlayground
//
//  Created by Toby Brennan

import Foundation
import UIKit
import SwiftUI


public class MemriTextEditor_UIKit: UITextView {
    var preferredHeightBinding: Binding<CGFloat>?
    var onTextChanged: ((NSAttributedString) -> Void)?
    
  public init(initialContent: NSAttributedString = NSAttributedString()) {
    super.init(frame: .zero, textContainer: nil)
    self.attributedText = initialContent.copy() as? NSAttributedString
    configure()
  }
  
  required init?(coder: NSCoder) {
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
    
    delegate = self
    layoutManager.delegate = self
  }
  
  let indentWidth: CGFloat = 20
  
  
  
  
  func selectionDidChange() {
    updateToolbar()
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
      toolbarHost = UIHostingController(rootView: view)
      toolbarHost?.view.sizeToFit()
      inputAccessoryView = toolbarHost?.view
    }
  }
    
    public func textViewDidChange(_ textView: UITextView) {
        onTextChanged?(attributedText)
    }
  
  override public var selectedTextRange: UITextRange? {
    didSet{
      selectionDidChange()
    }
  }
}

extension MemriTextEditor_UIKit: NSLayoutManagerDelegate {
    public func layoutManager(
        _ layoutManager: NSLayoutManager,
        didCompleteLayoutFor textContainer: NSTextContainer?,
        atEnd layoutFinishedFlag: Bool) {
        
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
  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if text.isEmpty, range.length <= 1 {
        //User pressed backspace
        return handleBackspace(changedRange: range, replacementText: text)
    }
    
    if (text.last?.isNewline ?? false) {
      //New line, hook here if we need (eg. change from header to body)
      return handleNewLine(changedRange: range, replacementText: text)
    }
    
    if text == "\t", range.length == 0 {
        //TAB
        return handleTab(changedRange: range, replacementText: text)
    }
    
    return true
  }
    
    
    func handleTab(changedRange range: NSRange, replacementText newText: String) -> Bool {
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
    
    func handleBackspace(changedRange range: NSRange, replacementText newText: String) -> Bool {
        let currentLineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: range.location, length: 0))
        let currentLineString = (textStorage.string as NSString).substring(with: currentLineRange) as NSString
        
        let lineContentWithoutList = NSMutableString(string: currentLineString)
        ListType.removeListText(in: lineContentWithoutList)
        
        if (lineContentWithoutList as String).isOnlyWhitespace {
            // Empty line in list, remove it
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: currentLineRange, with: "")
            textStorage.endEditing()
            selectedRange = NSRange(location: currentLineRange.location - 1, length: 0)
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
            if helper_currentIndent() != 0 {
                // Empty line, reduce indent
                helper_shiftIndent(by: -1)
                return false
            } else {
                // Empty line, remove the dot
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: oldLineRange, with: "")
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
    updateToolbar()
  }
  
  var state_isItalic: Bool {
    helper_currentContext_hasFontTrait(.traitItalic)
  }
  
  func action_toggleItalic() {
    helper_currentContext_toggleFontTrait(.traitItalic)
    updateToolbar()
  }
  
  func action_indent() {
    helper_shiftIndent(by: 1)
  }
  
  func action_outdent() {
    helper_shiftIndent(by: -1)
  }
  
    func action_unorderedList() {
        helper_makeSelectionList(type: .unorderedList)
    }
  func action_orderedList() {
    helper_makeSelectionList(type: .orderedList)
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
    updateToolbar()
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
    updateToolbar()
  }
  
  func helper_getHTML(_ attributedText: NSAttributedString) -> String? {
    let exportOptions = [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtf]
    do {
      let rtfData = try attributedText.data(from: NSRange(location: 0, length: attributedText.length),
                                            documentAttributes: exportOptions)
      
      return String(decoding: rtfData, as: UTF8.self)
    }
    catch {
      print("Cannot export attributedText as HTML: \(attributedText)")
      return nil
    }
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
    textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { (_, range, stop) in
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
    textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { (_, range, stop) in
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
  func helper_selectionHasUnorderedList() -> Bool {
    let string = (textStorage.string as NSString).substring(with: selectedRange) as NSString
    return ListType.unorderedList.checkIfHasMatch(in: string)
  }
  

  
    func helper_makeSelectionList(type: ListType) {
    // Find the range of selected lines
    //var startOfFirstLine: Int = 0, endOfLastLine: Int = 0
    let paragraphRange = (textStorage.string as NSString).paragraphRange(for: selectedRange)
      
  //    .getLineStart(&startOfFirstLine, end: &endOfLastLine, contentsEnd: nil, for: selectedRange)
    
    // Create storage for modified lines
    var modifiedParagraphs: [NSAttributedString] = []
    
    //Iterate through the lines
        var lineIndex = 1
    var currentParaStart = paragraphRange.location
    while currentParaStart <= paragraphRange.upperBound {
      let currentLineRange = (textStorage.string as NSString).paragraphRange(for: NSRange(location: currentParaStart, length: 0))
      guard let string = textStorage.attributedSubstring(from: currentLineRange).mutableCopy() as? NSMutableAttributedString else { continue }

        var paragraphAttributes: NSParagraphStyle?
        if !string.string.isEmpty {
            paragraphAttributes = string.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle
        }
      
      //MODIFY HERE
      ListType.removeListText(in: string.mutableString)
        string.insert(NSAttributedString(string: type.stringForLine(index: lineIndex), attributes: paragraphAttributes.map { [.paragraphStyle: $0] } ?? .none), at: 0)
    
      
      // Append modified string
      modifiedParagraphs.append(string)
      currentParaStart = currentLineRange.upperBound + 1
        lineIndex += 1
    }
    
    // Join lines back together
    let modifiedSection = modifiedParagraphs.reduce(into: NSMutableAttributedString()) { (result, line) in
      result.append(line)
    }

    // Apply changes
    textStorage.beginEditing()
    textStorage.replaceCharacters(in: paragraphRange,
                                  with: modifiedSection)
        textStorage.endEditing()
        selectedRange = NSRange(location: paragraphRange.lowerBound + modifiedSection.length, length: 0)
  }
}


extension MemriTextEditor_UIKit {
  enum ListType {
    case unorderedList
    case orderedList
    
    var expression: NSRegularExpression? {
      switch self {
      case .unorderedList:
        return try? NSRegularExpression(pattern: "^[-*••∙●] ", options: .caseInsensitive)
      case .orderedList:
        return try? NSRegularExpression(pattern: "^\\d*\\. ", options: .caseInsensitive)
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


