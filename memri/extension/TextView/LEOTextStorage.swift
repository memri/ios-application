//
//  LEOTextStorage.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit


class LEOTextStorage: NSTextStorage {
    var textView: LEOTextView!

    var currentString: NSMutableAttributedString = NSMutableAttributedString()

    var isChangeCharacters: Bool = false

    // Each dictionary in array. Key: location of NSRange, value: FontType
    var returnKeyDeleteEffectRanges: [[Int: LEOInputFontMode]] = []

    // MARK: - Must override
    override var string: String {
        return currentString.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return currentString.attributes(at: location, effectiveRange: range)
    }
    
    func getNewItemText(_ objectLine: String) -> NSString?{
        switch LEOTextUtil.paragraphType(objectLine) {
        case .numberedList:
            var number = Int(objectLine.components(separatedBy: ".")[0])
            if number == nil {
                return nil
            }
            // number changed.
            number! += 1
            return  "\(number!). " as NSString
        case .bulletedList, .dashedList:
            let listPrefixItem = objectLine.components(separatedBy: " ")[0]
            return "\(listPrefixItem) " as NSString
        case .body:
            return nil
        default:
            return nil
        }
        return nil
    }
    func getPrefixLength(_ objectLine: String) -> Int{
        // is it an empty
        switch LEOTextUtil.paragraphType(objectLine) {
        case .numberedList:
            var number = Int(objectLine.components(separatedBy: ".")[0])
            if number == nil {return 0}
            return "\(number!). ".length()
        case .bulletedList, .dashedList:
            let listPrefixItem = objectLine.components(separatedBy: " ")[0]
            return "\(listPrefixItem) ".length()
        default:
            return 0
        }
    }
    
    /// Main function that is called when an input is generated from the UI
    /// - Parameters:
    ///   - range: place to replace the characters
    ///   - str: string to insert
    override func replaceCharacters(in range: NSRange, with str: String) {
        
        
        // New item of list by increase
        var newItemText: NSString = ""

        // Current list item punctuation length
        var currentItemPrefixLength = 0
        var deleteCurrentListPrefixItemByReturn = false
        var deleteCurrentListPrefixItemByBackspace = false

        // Unordered and Ordered list auto-complete support
        if LEOTextUtil.isReturn(str) {
            if textView.inputFontMode == .title {
                textView.inputFontMode = .normal
            }

            let (objectLine, objectIndex) = LEOTextUtil.objectLineAndIndexForString(self.string, location: range.location)
            newItemText = getNewItemText(objectLine) ?? ""
            currentItemPrefixLength = getPrefixLength(objectLine)
        

            let lineTokens = objectLine.components(separatedBy: " ")
            
            // is empty list object
            if LEOTextUtil.isListObject(objectLine) && lineTokens.count >= 2 && lineTokens[1] == "" {
                    let lastIndex = objectIndex + objectLine.length()
                    let isEndOfText = lastIndex >= string.length()
                                    
                    // after this list the text ends, or the list ends
                    if isEndOfText || LEOTextUtil.isReturn(NSString(string: string).substring(with: NSMakeRange(lastIndex, 1))) {
                                                
                        // Delete mark
                        deleteCurrentListPrefixItemByReturn = true
                    }
            }
        } else if LEOTextUtil.isBackspace(str) && range.length == 1 {
            var firstLine = LEOTextUtil.objectLineWithString(self.textView.text, location: range.location)
            firstLine.append(" ")

            let separates = firstLine.components(separatedBy: " ").count
            let firstLineRange = NSMakeRange(0, firstLine.length())

            if separates == 2 &&
                (LEOTextUtil.unonderedListRE.matches(in: firstLine, options: .reportProgress, range: firstLineRange).count > 0 ||
                 LEOTextUtil.orderedListRE.matches(in: firstLine, options: .reportProgress, range: firstLineRange).count > 0) {
                // Delete mark
                deleteCurrentListPrefixItemByBackspace = true
                // a space char will deleting by edited operate, so we auto delete length needs subtraction one
                currentItemPrefixLength = firstLineRange.length - 1
                newItemText = ""
            }
        }

        isChangeCharacters = true

        beginEditing()

        let finalStr: NSString = "\(str)" as NSString

        currentString.replaceCharacters(in: range, with: String(finalStr))

        edited(.editedCharacters, range: range, changeInLength: (finalStr.length - range.length))

        endEditing()

        if textView.undoManager!.isRedoing {
            return
        }

        if deleteCurrentListPrefixItemByReturn || deleteCurrentListPrefixItemByBackspace {
            let deleteLocation = range.location - currentItemPrefixLength
            let deleteRange = NSRange(location: deleteLocation, length: currentItemPrefixLength)
            let deleteString = NSString(string: string).substring(with: deleteRange)

            undoSupportReplaceRange(deleteRange, withAttributedString: NSAttributedString(), oldAttributedString: NSAttributedString(string: deleteString),
                                    selectedRangeLocationMove: -currentItemPrefixLength)
            
            undoSupportResetIndenationRange(deleteRange, headIndent: deleteString.size(withAttributes: [NSAttributedString.Key.font: textView.normalFont]).width)

        } else {
            // List item increase
            let listItemTextLength = newItemText.length

            if listItemTextLength > 0 {
                // Follow text cursor to new list item location.
                undoSupportAppendRange(NSMakeRange(range.location + str.length(), 0),
                                       withString: String(newItemText), selectedRangeLocationMove: listItemTextLength)
            }
        }
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        guard currentString.string.length() > range.location else {
            return
        }

        beginEditing()

        currentString.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)

        endEditing()
    }

    // MARK: - Other overrided

    override func processEditing() {
        if isChangeCharacters && editedRange.length > 0 {
            isChangeCharacters = false
            performReplacementsForRange(editedRange, mode: textView.inputFontMode)
        }

        super.processEditing()
    }

    // MARK: - Other methods

    func currentParagraphTypeWithLocation(_ location: Int) -> LEOInputParagraphType {
        if self.textView.text == "" {
            return self.textView.inputFontMode == .title ? .title : .body
        }

        let objectLineAndIndex = LEOTextUtil.objectLineAndIndexForString(string, location: location)
        let titleFirstCharLocation = objectLineAndIndex.1

        let currentFont = self.textView.attributedText.safeAttribute(NSAttributedString.Key.font.rawValue, atIndex: titleFirstCharLocation, effectiveRange: nil, defaultValue: textView.normalFont) as! UIFont
        if currentFont.pointSize == textView.titleFont.pointSize {
            return .title
        }

        let paragraphRange = LEOTextUtil.paragraphRangeOfString(self.string, location: location)

        let objectLine = NSString(string: self.string).substring(with: paragraphRange)

        return LEOTextUtil.paragraphType(objectLine)
    }
    
    func turnOffUnderline(_ range: NSRange){
//        safeRemoveAttributed
        safeAddAttributes([.underlineStyle: 0], range: range)
    }

    func performReplacementsForRange(_ range: NSRange, mode: LEOInputFontMode) {
        
        if range.length > 0 {
            // Add addition attributes.
//            var attrValue: UIFont!
//            print(range)

            switch mode {
            case .normal:
                safeAddAttributes([NSAttributedString.Key.font : textView.normalFont], range: range)
//                turnOffUnderline(range)
//                safeAddAttributes([.underlineStyle: 0], range: range)
                break
            case .bold:
                safeAddAttributes([NSAttributedString.Key.font : textView.boldFont], range: range)
//                turnOffUnderline(range)
                break
            case .italic:
                safeAddAttributes([NSAttributedString.Key.font : textView.italicFont], range: range)
//                turnOffUnderline(range)
                break
            case .underline:
                safeAddAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue], range: range)
            case .title:
                safeAddAttributes([NSAttributedString.Key.font : textView.titleFont], range: range)
                break
            }

        }
    }

    // MARK: - Undo & Redo support

    func undoSupportChangeWithRange(_ range: NSRange, toMode targetMode: Int, currentMode: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportChangeWithRange(range, toMode: targetMode, currentMode: currentMode)
        })

        if textView.undoManager!.isUndoing {
            performReplacementsForRange(range, mode: LEOInputFontMode(rawValue: currentMode)!)
        } else {
            performReplacementsForRange(range, mode: LEOInputFontMode(rawValue: targetMode)!)
        }
    }

    func undoSupportReplaceRange(_ replaceRange: NSRange, withAttributedString attributedStr: NSAttributedString, oldAttributedString: NSAttributedString, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportReplaceRange(replaceRange, withAttributedString: attributedStr, oldAttributedString: oldAttributedString, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            let targetSelectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, textView.selectedRange.length)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, attributedStr.string.length()), withAttributedString: oldAttributedString)
            textView.selectedRange = targetSelectedRange
        } else {
            let targetSelectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, textView.selectedRange.length)
            safeReplaceCharactersInRange(replaceRange, withAttributedString: attributedStr)
            textView.selectedRange = targetSelectedRange
        }
    }

    func undoSupportAppendRange(_ replaceRange: NSRange, withString str: String, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportAppendRange(replaceRange, withString: str, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, str.length()), withString: "")
        } else {
            safeReplaceCharactersInRange(replaceRange, withString: str)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        }
    }

    func undoSupportAppendRange(_ replaceRange: NSRange, withAttributedString attributedStr: NSAttributedString, selectedRangeLocationMove: Int) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportAppendRange(replaceRange, withAttributedString: attributedStr, selectedRangeLocationMove: selectedRangeLocationMove)
        })

        if textView.undoManager!.isUndoing {
            textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
            safeReplaceCharactersInRange(NSMakeRange(replaceRange.location, attributedStr.string.length()), withAttributedString: NSAttributedString())
        } else {
            safeReplaceCharactersInRange(replaceRange, withAttributedString: attributedStr)
            textView.selectedRange = NSMakeRange(textView.selectedRange.location + selectedRangeLocationMove, 0)
        }
    }

    func undoSupportMadeIndenationRange(_ range: NSRange, headIndent: CGFloat) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportMadeIndenationRange(range, headIndent: headIndent)
        })

        let paragraphStyle = textView.mutableParargraphWithDefaultSetting()

        if textView.undoManager!.isUndoing {
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        } else {
            paragraphStyle.headIndent = headIndent + textView.normalFont.lineHeight
            paragraphStyle.firstLineHeadIndent = textView.normalFont.lineHeight
        }

        safeAddAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: range)
    }

    func undoSupportResetIndenationRange(_ range: NSRange, headIndent: CGFloat) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportResetIndenationRange(range, headIndent: headIndent)
        })

        let paragraphStyle = textView.mutableParargraphWithDefaultSetting()

        if textView.undoManager!.isUndoing {
            paragraphStyle.headIndent = headIndent + textView.normalFont.lineHeight
            paragraphStyle.firstLineHeadIndent = textView.normalFont.lineHeight
        } else {
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        }

        safeAddAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: range)
    }
}
