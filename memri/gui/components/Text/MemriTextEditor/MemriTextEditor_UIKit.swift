//
//  TextEditorUIView.swift
//  RichTextEditor
//
//  Created by Toby Brennan on 22/6/20.
//  Copyright © 2020 ApptekStudios. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import WebKit

public class TextEditorWrapperUIView: UIView {
    //This UIView allows us to add overlays to the UITextView if needed
    var textEditor: MemriTextEditor_UIKit
    var toolbar: UIView? {
        didSet {
            toolbar.map(addSubview)
        }
    }
    var activityIndicator = UIActivityIndicatorView(style: .large)
    
    var showActivityIndicator: Bool = true {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.activityIndicator.isHidden = !self.showActivityIndicator
            }
        }
    }
    
    init(_ textEditor: MemriTextEditor_UIKit) {
        self.textEditor = textEditor
        super.init(frame: .zero)
        addSubview(textEditor)
        addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
        ])
        
        setupConstraints()
    }

    
    func setupConstraints() {
        textEditor.removeConstraints(textEditor.constraints)
        textEditor.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [
            (textEditor).leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            (textEditor).trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            (textEditor).bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ]
        
        if let toolbar = toolbar {
            toolbar.removeConstraints(toolbar.constraints)
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                (toolbar).topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                (toolbar).leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                (toolbar).trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                (toolbar).heightAnchor.constraint(equalToConstant: 50),
                (textEditor).topAnchor.constraint(equalTo: toolbar.bottomAnchor)
            ])
        } else {
            constraints.append(contentsOf:[
                (textEditor).topAnchor.constraint(equalTo: topAnchor)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MemriTextEditor_UIKit: WKWebView {
    
    private var toolbarHost: UIHostingControllerNoSafeArea<MemriTextEditor_Toolbar>?
    private var toolbarWrapperView: ToolbarWrapperView?
    
    private var cancellableBag: Set<AnyCancellable> = []
    
    private var currentFormatting: [String: Any] = [:]
    
    private var userController: WKUserContentController
    
    var initialModel: MemriTextEditorModel
    var onModelUpdate: ((MemriTextEditorModel) -> Void)?
    
    var searchTerm: String? {
        didSet {
            if searchTerm != oldValue {
                self.updateSearchState().sink {}.store(in: &cancellableBag)
            }
        }
    }
    var isEditingBinding: Binding<Bool>? {
        didSet {
            if let bindingIsEditing = isEditingBinding?.wrappedValue,
               bindingIsEditing != isEditing {
                if bindingIsEditing {
                    becomeFirstResponder()
                }
                else {
                    resignFirstResponder()
                }
            }
        }
    }
    
    private var isEditing: Bool = false
    
    init(initialModel: MemriTextEditorModel) {
        let config = WKWebViewConfiguration()
        let userController = WKUserContentController()
        config.userContentController = userController
        self.userController = userController
        
        self.initialModel = initialModel
        
        super.init(frame: .zero, configuration: config)
        
        isOpaque = false //Prevent white flash in dark mode
        
        self.navigationDelegate = self
        self.scrollView.delegate = self
        self.scrollView.isScrollEnabled = false
        
        config.userContentController = userController
        userController.add(self, name: "formatChange")
        userController.add(self, name: "textChange")
        
        updateToolbar()
        
        if
            let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "textEditorDist"),
            let data = try? Data(contentsOf: url),
            let baseString = String(data: data, encoding: .utf8)
        {
            loadHTMLString(baseString, baseURL: url)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateToolbar() {
        let items: [MemriTextEditor_Toolbar.Item] = [
            .button(label: "Bold", icon: "bold",
                    isActive: currentFormatting["bold"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("bold") }),
            .button(label: "Italic", icon: "italic",
                    isActive: currentFormatting["italic"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("italic") }),
            .button(label: "Underline", icon: "underline",
                    isActive: currentFormatting["underline"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("underline") }),
            .button(label: "Strike", icon: "strikethrough",
                    isActive: currentFormatting["strike"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("strike") }),
            .divider,
//            .button(label: "Heading", icon: "textformat.alt",
//                    isActive: (currentFormatting["heading"] as? Int).map { $0 != 0 } ?? false,
//                    onPress: { [weak self] in self?.toggleFormat("heading", info: ["level": 1]) }),
//            .button(label: "Quote", icon: "decrease.quotelevel",
//                    isActive: currentFormatting["blockquote"] as? Bool ?? false,
//                    onPress: { [weak self] in self?.toggleFormat("blockquote") }),
            .button(label: "Todo List", icon: "checkmark.square",
                    isActive: currentFormatting["todo_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("todo_list") }),
            .button(label: "Unordered List", icon: "list.bullet",
                    isActive: currentFormatting["bullet_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("bullet_list") }),
            .button(label: "Ordered List", icon: "list.number",
                    isActive: currentFormatting["ordered_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("ordered_list") }),
            .button(label: "Outdent List", icon: "decrease.indent",
                    hideInactive: true,
                    isActive: currentFormatting["lift_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("lift_list") }),
            .divider,
            .button(label: "Indent List", icon: "increase.indent",
                    hideInactive: true,
                    isActive: currentFormatting["sink_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("sink_list") }),
            .button(label: "Code block", icon: "textbox",
                    isActive: currentFormatting["code_block"] as? Bool ?? false,
                    onPress: { [weak self] in self?.toggleFormat("code_block") }),
        ]
        let view = MemriTextEditor_Toolbar(
            textView: self,
            items: items
        )
        self._setToolbar(view)
    }
    
    func didBeginEditing() {
        isEditing = true
        if let isEditingBinding = isEditingBinding, isEditingBinding.wrappedValue != true {
            DispatchQueue.main.async {
                isEditingBinding.wrappedValue = true
            }
        }
    }
    
    public func didEndEditing() {
        isEditing = false
        if let isEditingBinding = isEditingBinding, isEditingBinding.wrappedValue != false {
            DispatchQueue.main.async {
                isEditingBinding.wrappedValue = false
            }
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        (superview as? TextEditorWrapperUIView)?.showActivityIndicator = isLoading
        #if targetEnvironment(macCatalyst)
        if let superview = superview as? TextEditorWrapperUIView {
            superview.toolbar = toolbarHost?.view
        }
        #endif
    }
    
    func _setToolbar(_ view: MemriTextEditor_Toolbar) {
        if let hc = toolbarHost {
            hc.rootView = view
            toolbarWrapperView?.sizeToFit()
        } else {
            let toolbarHost = UIHostingControllerNoSafeArea(rootView: view)
            self.toolbarHost = toolbarHost
            #if targetEnvironment(macCatalyst)
            if let superview = superview as? TextEditorWrapperUIView {
                superview.toolbar = toolbarHost.view
            }
            #else
            let wrapper = ToolbarWrapperView(toolbarView: toolbarHost.view)
            wrapper.sizeToFit()
            toolbarWrapperView = wrapper
            #endif
        }
    }
    
    func toggleFormat(_ format: String, info: [String: Any] = [:]) {
        let oldValue = (currentFormatting[format] as? Bool) ?? false
        currentFormatting[format] = !oldValue
        updateToolbar()
        setFormatting(format: format, info: info)
        .receive(on: DispatchQueue.main)
        .sink {}
        .store(in: &cancellableBag)
    }
    
    func grabFocus(takeFirstResponder: Bool = true) {
        self.evaluateJavaScript("window.editor.focus();")
        if takeFirstResponder {
            becomeFirstResponder()
        }
    }
    
    override var inputAccessoryView: UIView? {
        #if targetEnvironment(macCatalyst)
        return super.inputAccessoryView
        #else
        return toolbarWrapperView
        #endif
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            didBeginEditing()
            return true
        }
        return false
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            didEndEditing()
            return true
        }
        return false
    }
    
    override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                self.evaluateJavaScript("window.getSelection().getRangeAt(0).startContainer.parentNode.scrollIntoViewIfNeeded(false);")
            }
        }
    }
}


extension MemriTextEditor_UIKit: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let content = message.body as? [String: Any] {
            if let formatting = content["format"] as? [String: Any] {
                self.currentFormatting = formatting
                updateToolbar()
            }
            if let htmlString = content["html"] as? String {
                let model = MemriTextEditorModel(html: htmlString)
                onModelUpdate?(model)
            }
        }
    }
}

extension MemriTextEditor_UIKit: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setContent(content: initialModel.html).sink{ [weak self] in
            guard let self = self else { return }
            self.updateSearchState().sink{}.store(in: &self.cancellableBag)
        }.store(in: &cancellableBag)
        (superview as? TextEditorWrapperUIView)?.showActivityIndicator = false
        updateToolbar()
        grabFocus(takeFirstResponder: false)
    }
}

extension MemriTextEditor_UIKit: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

import Combine
extension MemriTextEditor_UIKit {
    func setContent(content: String?) -> Future<Void, Never> {
        let content = content?.escapeForJavascript()
        let setContent = content.map { "window.editor.setContent(content = \"\($0)\", emitUpdate = false);" }
        return Future { (promise) in
            if let script = setContent {
                self.evaluateJavaScript(script) { (some, error) in
                    promise(.success(()))
                }
            } else {
                promise(.success(()))
            }
        }
    }
    
    func setFormatting(format: String, info: [String: Any] = [:]) -> Future<Void, Never> {
        let infoString = (try? String(data: JSONSerialization.data(withJSONObject: info), encoding: .utf8)) ?? ""
        let script = "window.editor.commands.\(format)(\(infoString));"
        return Future { (promise) in
            self.evaluateJavaScript(script) { (some, error) in
                promise(.success(()))
            }
        }
    }
    
    func updateSearchState() -> Future<Void, Never> {
        let script = searchTerm.map { searchString in
            "window.editor.commands.find(\"\(searchString.escapeForJavascript())\");"
        } ?? "window.editor.commands.clearSearch()"
        return Future { (promise) in
            self.evaluateJavaScript(script) { (some, error) in
                promise(.success(()))
            }
        }
    }
}


class ToolbarWrapperView: UIView {
    var toolbarView: UIView
    
    init(toolbarView: UIView) {
        self.toolbarView = toolbarView
        super.init(frame: .zero)
        addSubview(toolbarView)
        translatesAutoresizingMaskIntoConstraints = false
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: toolbarView.intrinsicContentSize.width, height: toolbarView.intrinsicContentSize.height + safeAreaInsets.bottom)
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }
}
