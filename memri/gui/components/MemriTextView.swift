//
// MemriTextView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

// struct MemriTextView: UIViewRepresentable {
//	var string: String
//	var detectLinks: Bool = true
//	var font: FontDefinition
//	var color: ColorDefinition?
//	var maxLines: Int?
//
//	func makeUIView(context: Context) -> MemriTextView_UIKit {
//		let textView = MemriTextView_UIKit()
//		textView.font = font.uiFont
//		textView.textColor = color?.uiColor ?? .label
//		textView.text = string
//		textView.numberOfLines = maxLines ?? 0
//
//		return textView
//	}
//
//	func updateUIView(_ textView: MemriTextView_UIKit, context: Context) {
//		textView.text = string
//	}
// }
//
//
// class MemriTextView_UIKit: UILabel {
//	init() {
//		super.init(frame: .zero)
//
//		setContentCompressionResistancePriority(.required, for: .vertical)
//		setContentHuggingPriority(.defaultHigh, for: .horizontal)
//		setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
// }

struct MemriSmartTextView: View {
	var string: String
	var detectLinks: Bool = true
	var font: FontDefinition
	var color: ColorDefinition?
	var maxLines: Int?
	
	// This uses a rather hacky implementation to get around SwiftUI sizing limitations
	// We use a simple text element to do the sizing, but display our custom element
	var body: some View {
		Text(verbatim: string)
				.lineLimit(maxLines != 0 ? maxLines : nil)
				.font(font.font)
				.fixedSize(horizontal: false, vertical: true)
				.hidden()
				.overlay(MemriSmartTextView_Inner(string: string, detectLinks: detectLinks, font: font, color: color, maxLines: maxLines))
	}
}

struct MemriSmartTextView_Inner: UIViewRepresentable {
    var string: String
    var detectLinks: Bool = true
    var font: FontDefinition
    var color: ColorDefinition?
    var maxLines: Int?

    func makeUIView(context: Context) -> MemriSmartTextView_UIKit {
        let textView = MemriSmartTextView_UIKit()
        textView.dataDetectorTypes = detectLinks ? .all : []
        textView.font = font.uiFont
        textView.textColor = color?.uiColor ?? .label
        textView.text = string

		textView.contentInset = .zero
		textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = maxLines ?? 0

        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        textView.layoutManager.delegate = context.coordinator

        return textView
    }

    func updateUIView(_ textView: MemriSmartTextView_UIKit, context: Context) {
		if textView.text != string {
			textView.text = string
		}
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UITextViewDelegate, NSLayoutManagerDelegate {
        weak var textView: MemriSmartTextView_UIKit?
    }
}

class MemriSmartTextView_UIKit: UITextView {
    init() {
        super.init(frame: .zero, textContainer: nil)
        isEditable = false
		backgroundColor = .clear
		textContainerInset = .zero
		textContainer.lineBreakMode = .byWordWrapping
	
		 // These next few lines are critical to getting the right autosizing behaviour
		isScrollEnabled = false
		setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		setContentCompressionResistancePriority(.defaultLow, for: .horizontal) // Default low required in SwiftUI to avoid forcing larger frame
		setContentHuggingPriority(.defaultHigh, for: .horizontal)
		setContentHuggingPriority(.defaultHigh, for: .vertical)
	}
	
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	override var intrinsicContentSize: CGSize {
		// super.intrinsicContentSize - this works, except for the case where a line is wider than the available space
		CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
	}
}
