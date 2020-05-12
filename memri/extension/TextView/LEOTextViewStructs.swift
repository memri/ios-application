//
//  LEOTextViewStructs.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation
import UIKit

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
