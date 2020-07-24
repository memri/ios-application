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

struct MemriSmartTextView: UIViewRepresentable {
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

        textView.textContainer.maximumNumberOfLines = maxLines ?? 0
        textView.textContainer.lineBreakMode = .byTruncatingTail

        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        textView.layoutManager.delegate = context.coordinator

        return textView
    }

    func updateUIView(_ textView: MemriSmartTextView_UIKit, context: Context) {
        textView.text = string
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UITextViewDelegate, NSLayoutManagerDelegate {
        weak var textView: MemriSmartTextView_UIKit?

        func layoutManager(
            _ layoutManager: NSLayoutManager,
            didCompleteLayoutFor textContainer: NSTextContainer?,
            atEnd layoutFinishedFlag: Bool
        ) {
            textView?.invalidateIntrinsicContentSize()
        }
    }
}

class MemriSmartTextView_UIKit: UITextView {
    init() {
        super.init(frame: .zero, textContainer: nil)
        isEditable = false

        setContentCompressionResistancePriority(.required, for: .vertical)
        textContainerInset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var intrinsicContentSize: CGSize {
        if frame.width != .zero {
            let height = sizeThatFits(CGSize(width: frame.width, height: 1)).height
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
        else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
    }
}
