//
//  LEOTextViewStructs.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation
import UIKit

extension Dictionary {
    mutating func merge(_ dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}



public class InputStyles {
    var styles: [InputStyle] = []
    var normalFont: UIFont = UIFont.systemFont(ofSize: 17)
    
    
    convenience init(styles: [InputStyle]){
        self.init()
        self.styles = styles
    }

    
    func getAttributes() -> [NSAttributedString.Key : Any] {
        var attributes: [NSAttributedString.Key : Any] = [:]
        
        attributes[NSAttributedString.Key.font] = self.getInputFont()
        
        for style in self.styles{
            if let attribute = style.getAttribute(){
                attributes.merge(attribute)
            }
                    }
        if !styles.contains(.underline){
            // For some reason, just removing the underline style is not enough, it needs to be
            // explicitly set
            attributes[.underlineStyle] = 0
        }
        return attributes
    }
    
    func getInputFont() -> UIFont{
        if self.styles.contains(InputStyle.bold) && self.styles.contains(InputStyle.italic){
            return normalFont.boldItalics()
        }
        else if self.styles.contains(InputStyle.bold){
            return normalFont.bold()
        }
        else if self.styles.contains(InputStyle.italic){
            return normalFont.italics()
        }else{
            return normalFont
        }
    }
}

public enum InputStyle: String{
    case normal, bold, italic, underline
    
    func getAttribute() -> [NSAttributedString.Key : Any]?{
        switch self{
        case .normal:
            return nil
        case .bold:
            return nil
        case .italic:
            return nil
        case .underline:
            return [.underlineStyle: NSUnderlineStyle.single.rawValue]
        }
    }
}


public enum LEOInputFontMode: Int {
    case normal, bold, italic, title, underline
}

public enum LEOInputParagraphType: Int {
    case title, body, bulletedList, dashedList, numberedList
}

struct LEOParagraph {
    var paragraphType: LEOInputParagraphType
    var range: NSRange
    var paragraphText: String
}
