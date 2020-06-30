// File: KeyboardResponder.swift
// Project: PushContentUp
// Created at 24.01.20 by BLCKBIRDS
// Visit www.BLCKBIRDS.com for more.
import Foundation
import SwiftUI

class KeyboardResponder: ObservableObject {
	static var shared = KeyboardResponder()

	@Published var currentHeight: CGFloat = 0

	var _center: NotificationCenter

	private init(center: NotificationCenter = .default) {
		_center = center
		_center.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		_center.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	// Update the currentHeight variable when the keyboards gets toggled
	@objc func keyBoardWillShow(notification: Notification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			withAnimation(.easeOut(duration: 0.30)) {
				currentHeight = keyboardSize.height
			}
		}
	}

	@objc func keyBoardWillHide(notification _: Notification) {
		withAnimation(.easeOut(duration: 0.30)) {
			currentHeight = 0
		}
	}
}
