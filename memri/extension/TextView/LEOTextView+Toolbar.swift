//
//  LEOTextView+Toolbar.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import UIKit

public var toolbar: UIToolbar?
public var toolbarHeight: CGFloat = 40
public var currentFrame: CGRect = CGRect.zero

public var toolbarButtonInactiveColor: UIColor = UIColor.black
public var toolbarButtonActiveColor: UIColor = UIColor.green
public var toolbarButtonHighlightColor: UIColor = UIColor.orange

var formatButton: UIBarButtonItem?
var formatMenuView: UIView?

extension LEOTextView {

     
    /// Remove toolbar notifications
    public func removeToolbarNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

     
    /// Enable the toolbar, binding the show and hide events.
    public func enableToolbar() -> UIToolbar {
        let frame = CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height),
                           size: CGSize(width: UIScreen.main.bounds.width, height: toolbarHeight))
        toolbar = UIToolbar(frame: frame)
        // style
        toolbar?.autoresizingMask = .flexibleWidth
        toolbar?.backgroundColor = UIColor.white
        toolbar?.barTintColor = UIColor.white // bar background colour
        toolbar?.items = enableBarButtonItems()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowOrHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)

        currentFrame = self.frame

        return toolbar!
    }

    // MARK: - Toolbar buttons

    func enableBarButtonItems() -> [UIBarButtonItem] {
        
        // richttext
        let boldButton = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain,
                                         target: self, action: #selector(self.boldButtonAction))
        let italicButton = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain,
                                           target: self,
                                           action: #selector(self.italicButtonAction))
        let underlineButton = UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain,
                                              target: self,
                                              action: #selector(self.underlineFontButtonAction))
        self.boldButton = boldButton
        self.italicButton = italicButton
        self.underlineButton = underlineButton
    
        // lists
        let bulletedListButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"),
                                                 style: .plain, target: self,
                                                 action: #selector(self.bulletedListButtonAction))
        let NumberedListButton = UIBarButtonItem(image: UIImage(systemName: "list.number"),
                                                 style: .plain, target: self,
                                                 action: #selector(self.numberedButtonAction))

        let buttonItems = [boldButton, italicButton, underlineButton, bulletedListButton,
                           NumberedListButton]

        // Button styles
        for buttonItem in buttonItems { buttonItem.tintColor = toolbarButtonInactiveColor }

        return buttonItems
    }
    
    func buttonAction(_ style: InputStyle) {
//        guard mode != .normal else {
//            return
//        }

        if LEOTextUtil.isSelecting(self) {
            changeSelectedTextWithInputFontMode()
        } else {
            // The normal case
            toggleInputStyle(style)
        }
    }
    
    func toggleInputStyle(_ style: InputStyle){
        if let index = inputStyles.firstIndex(of: style) {
            inputStyles.remove(at: index)
        }
        else {
            inputStyles.append(style)
        }
    }
    
    func toggleButtonColor(button: UIBarButtonItem, fontClicked: InputStyle){
        button.tintColor = inputStyles.contains(fontClicked) ? toolbarButtonInactiveColor : toolbarButtonActiveColor
    }
    
    @objc func boldButtonAction() {
        toggleButtonColor(button: self.boldButton!, fontClicked: InputStyle.bold)
        buttonAction(.bold)
    }
    
    @objc func italicButtonAction() {
        toggleButtonColor(button: self.italicButton!, fontClicked: InputStyle.italic)
        buttonAction(.italic)
    }
    
    @objc func underlineFontButtonAction() {
        toggleButtonColor(button: self.underlineButton!, fontClicked: InputStyle.underline)
        buttonAction(.underline)
    }

    @objc func bulletedListButtonAction() {
        self.changeCurrentParagraphToOrderedList(orderedList: false, listPrefix: "• ")
    }
    
    @objc func numberedButtonAction() {
        self.changeCurrentParagraphToOrderedList(orderedList: true, listPrefix: "1. ")
    }

    @objc func dashedButtonAction() {
        self.changeCurrentParagraphToOrderedList(orderedList: false, listPrefix: "- ")
    }


    @objc func keyboardWillShowOrHide(_ notification: Notification) {
        guard let info = (notification as NSNotification).userInfo else {
            return
        }

        guard self.superview != nil else {
            return
        }

        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let keyboardEnd = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        let toolbarHeight = toolbar!.frame.size.height

        if notification.name == UIResponder.keyboardWillShowNotification{
            // double check if toolbar is not already presented
            if !superview!.subviews.contains(toolbar!){
                formatMenuView?.removeFromSuperview()

                self.superview?.addSubview(toolbar!)

                var textViewFrame = self.frame
                textViewFrame.size.height = self.superview!.frame.height - keyboardEnd.height - toolbarHeight
                self.frame = textViewFrame
                
                UIView.animate(withDuration: duration, animations: {
                    var toolbarFrame = toolbar!.frame
                    // TODO: CHANGE HOW THIS IS COMPUTED, THE 25 IS CURRENTLY SUPER HACKY
                    toolbarFrame.origin.y = self.superview!.frame.height - (keyboardEnd.height + toolbarHeight - 15)
                    toolbar!.frame = toolbarFrame
                }, completion: nil)
            }
            
            
        } else {
            self.frame = currentFrame

            UIView.animate(withDuration: duration, animations: {
                var frame = toolbar!.frame
                frame.origin.y = self.superview!.frame.size.height
                toolbar!.frame = frame

            }, completion: { (success) in
                toolbar!.removeFromSuperview()
            })

            formatMenuView?.removeFromSuperview()
        }
    }
}
