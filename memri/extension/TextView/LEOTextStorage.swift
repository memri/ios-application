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
    }
    func getPrefixLength(_ objectLine: String) -> Int{
        // is it an empty
        switch LEOTextUtil.paragraphType(objectLine) {
        case .numberedList:
            let number = Int(objectLine.components(separatedBy: ".")[0])
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
        /// NOTE: some calls of this function causes the function to be called recursively,
        /// for instance when pressing newlines while being in a bulleted list
        
        // New item of list by increase
        var newItemText: NSString = ""
        // Current list item punctuation length
        var currentItemPrefixLength = 0
        var deleteCurrentListPrefixItemByReturn = false
        var deleteCurrentListPrefixItemByBackspace = false
        var addNewListItem = false
        
        // TODO: this is super hacky, but for some reason the location of the range is broken when a backspace is passed
        let searchLoc = LEOTextUtil.isBackspace(str) && range.length == 1 ? range.location + 1 : range.location
        let (currentLine, indexInLine) = LEOTextUtil.objectLineAndIndexForString(self.string,
                                                                                location: searchLoc)

        
        print("\nREPLACE IN RANGE \(range) WITH STRING \"\(str.debugDescription)\"")
        print("CURRENT LINE \"\(currentLine)\"")
//
        print(LEOTextUtil.isBackspace(str))
        // Unordered and Ordered list auto-complete support
        if LEOTextUtil.isReturn(str) {
            if textView.inputFontMode == .title {
                textView.inputFontMode = .normal
            }

            newItemText = getNewItemText(currentLine) ?? ""
            currentItemPrefixLength = getPrefixLength(currentLine)
        
            let lineTokens = currentLine.components(separatedBy: " ")
            
            if LEOTextUtil.isListItem(currentLine){
                // is empty list
                if lineTokens.count >= 2 && lineTokens[1] == "" {
                    let lastIndex = indexInLine + currentLine.length()
                    let isEndOfText = lastIndex >= string.length()
                                    
                    // after this list the text ends, or the list ends
                    if isEndOfText || LEOTextUtil.isReturn(NSString(string: string).substring(with: NSMakeRange(lastIndex, 1))) {
                        deleteCurrentListPrefixItemByReturn = true
                    }
                }else{
                    // nonempty list, and pressing return
                    addNewListItem = true
                }
            }
        }
        else if LEOTextUtil.isBackspace(str) && range.length == 1 {
            
            var firstLine = LEOTextUtil.objectLineWithString(self.textView.text, location: range.location)
            // TODO: WHY IS THIS?
            firstLine.append(" ")
            let lineTokens = firstLine.components(separatedBy: " ").count

            if lineTokens == 2 && LEOTextUtil.isListItem(firstLine){
                deleteCurrentListPrefixItemByBackspace = true
                currentItemPrefixLength = getPrefixLength(currentLine)
            }
        }

        isChangeCharacters = true

        beginEditing()

        // NSString counts length differently
        let finalStr: NSString = "\(str)" as NSString

        currentString.replaceCharacters(in: range, with: String(finalStr))
        
        edited(.editedCharacters, range: range, changeInLength: (finalStr.length - range.length))
        
        endEditing()



        if textView.undoManager!.isRedoing {
            return
        }

        if deleteCurrentListPrefixItemByReturn {
            let lineStart = range.location - currentItemPrefixLength
            let (nextLine, _) = LEOTextUtil.objectLineAndIndexForString(self.string,
                                                                        location: range.location)
            var rangeLen = currentLine.length() + nextLine.length()
            rangeLen = lineStart + rangeLen <= string.length() ? rangeLen : string.length() - lineStart
            
//            let unindentString = NSString(string: string).substring(with: NSRange(location: lineStart, length: rangeLen))
            safeAddAttributes([NSAttributedString.Key.paragraphStyle : textView.mutableParargraphWithDefaultSetting()],
                              range: NSRange(location: lineStart,
                                             length: rangeLen))
            
            let deleteRange = NSRange(location: range.location - currentItemPrefixLength - 1, length: currentItemPrefixLength + 1)
            let deleteString = NSString(string: string).substring(with: deleteRange)
            
            if LEOTextUtil.isBackspace(deleteString) && deleteRange.length == 1{ print("ERROR: THIS IS SHOULD NEVER HAPPEN")}
            
            // note that this is calling the current function recursively
            undoSupportReplaceRange(deleteRange,
                                    withAttributedString: NSAttributedString(),
                                    oldAttributedString: NSAttributedString(string: deleteString),
                                    selectedRangeLocationMove: -currentItemPrefixLength)

            
        } else if deleteCurrentListPrefixItemByBackspace{
            // TODO: for some reason currentLine does only contain the list prefix here, but not the trailing space
            let lineStart = searchLoc - currentItemPrefixLength
            var rangeLen = currentLine.length()
            rangeLen = lineStart + rangeLen <= string.length() ? rangeLen : string.length() - lineStart
            
            safeAddAttributes([NSAttributedString.Key.paragraphStyle : textView.mutableParargraphWithDefaultSetting()],
                              range: NSRange(location: lineStart, length: rangeLen))
            
            let deleteRange = NSRange(location: searchLoc - currentItemPrefixLength, length: currentItemPrefixLength - 1)
            let deleteString = NSString(string: string).substring(with: deleteRange)
            
            undoSupportReplaceRange(deleteRange,
                                    withAttributedString: NSAttributedString(),
                                    oldAttributedString: NSAttributedString(string: deleteString),
                                    selectedRangeLocationMove: -currentItemPrefixLength)
                        
        } else if addNewListItem{
            undoSupportAppendRange(NSMakeRange(range.location + str.length(), 0),
                                   withString: String(newItemText), selectedRangeLocationMove: newItemText.length)
        }
        else if str.hasPrefix("http://") || str.hasPrefix("www.") || str.hasPrefix("\nhttps://") || str.hasPrefix("https://"){
            
            let linkRange = NSRange(location: range.location, length: str.length())
            // TODO: why is it necessary to do this async
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if let url = URL(string: removeTrailingWhiteSpace(str)){
                    self.safeAddAttributes([.link: url], range: linkRange)
                }
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
            performReplacementsForRange(editedRange, styles: textView.inputStyles)
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

    func performReplacementsForRange(_ range: NSRange, styles: [InputStyle]) {
        
        if range.length > 0 {
            // add font, this has to be done separately because bold and italic are wrapping in a single attribute
            let inputFont = textView.getInputFont()
            safeAddAttributes([NSAttributedString.Key.font : inputFont], range: range)
            for style in textView.inputStyles{
                if let attributes = style.getAttribute(){
                    safeAddAttributes(attributes, range: range)
                }
                
            }
        }
    }

    // MARK: - Undo & Redo support

    func undoSupportChangeWithRange(_ range: NSRange, addStyle: InputStyle, currentStyles: [InputStyle]) {
        textView.undoManager?.registerUndo(withTarget: self, handler: { (type) in
            self.undoSupportChangeWithRange(range, addStyle: addStyle, currentStyles: currentStyles)
        })

        if textView.undoManager!.isUndoing {
            performReplacementsForRange(range, styles: currentStyles)
        } else {
            performReplacementsForRange(range, styles: [addStyle])
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
