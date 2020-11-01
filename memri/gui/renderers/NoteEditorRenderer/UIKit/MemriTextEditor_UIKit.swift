//
// MemriTextEditor_UIKit.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI
import UIKit
import WebKit

public class MemriTextEditor_UIKitWrapper: UIView {
    // This UIView allows us to add overlays to the UITextView if needed
    var textEditor: MemriTextEditor_UIKit
    var toolbar: UIView? {
        didSet {
            if toolbar !== oldValue {
                toolbar.map(addSubview)
                setupConstraints()
            }
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
            textEditor.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            textEditor.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            textEditor.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ]

        if let toolbar = toolbar {
            toolbar.removeConstraints(toolbar.constraints)
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                toolbar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                toolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: 50),
                textEditor.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            ])
        }
        else {
            constraints.append(contentsOf: [
                textEditor.topAnchor.constraint(equalTo: topAnchor),
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MemriTextEditor_UIKit: WKWebView {
    private var toolbarHost: UIHostingControllerNoSafeArea<MemriTextEditor_Toolbar>?
    private var toolbarWrapperView: ToolbarWrapperView?

    var imageSelectionHandler: MemriTextEditorImageSelectionHandler?

    private var cancellableBag: Set<AnyCancellable> = []

    private var currentFormatting: [String: Any] = [:] {
        didSet {
            if currentFormatting["selected_image"] != nil {
                toolbarState = .image
                tintColor = .clear
            }
            else {
                if toolbarState == .image { toolbarState = .main }
                tintColor = .systemBlue
            }
            updateToolbar()
        }
    }

    var initialModel: MemriTextEditorModel
    var onModelUpdate: ((MemriTextEditorModel) -> Void)?

    var searchTerm: String? {
        didSet {
            if searchTerm != oldValue {
                updateSearchState().sink {}.store(in: &cancellableBag)
            }
        }
    }

    var isEditingBinding: Binding<Bool>? {
        didSet {
            if let bindingIsEditing = isEditingBinding?.wrappedValue,
               bindingIsEditing != isEditing
            {
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

    enum ToolbarState {
        case main
        case color
        case heading
        case image

        var showBackButton: Bool {
            switch self {
            case .main:
                return false
            case .image:
                return false
            default:
                return true
            }
        }

        mutating func onBack() {
            self = .main
        }

        mutating func toggleHeading() {
            switch self {
            case .heading: self = .main
            default: self = .heading
            }
        }

        mutating func toggleColor() {
            switch self {
            case .color: self = .main
            default: self = .color
            }
        }
    }

    var toolbarState: ToolbarState = .main {
        didSet { updateToolbar() }
    }

    let userController = WKUserContentController()
    let fileHandler = FileHandler()

    init(initialModel: MemriTextEditorModel) {
        let config = WKWebViewConfiguration()
        config.userContentController = userController
        config.setURLSchemeHandler(fileHandler, forURLScheme: "memriFile")

        self.initialModel = initialModel

        super.init(frame: .zero, configuration: config)

        isOpaque = false // Prevent white flash in dark mode

        navigationDelegate = self
        scrollView.delegate = self
        scrollView
            .isScrollEnabled =
            false // The scrolling of the notes view is handled by a scrollView in the html/css

        userController.add(self, name: "formatChange")
        userController.add(self, name: "textChange")

        updateToolbar()

        if
            let url = Bundle.main.url(
                forResource: "index",
                withExtension: "html",
                subdirectory: "textEditorDist"
            ),
            let data = try? Data(contentsOf: url),
            let baseString = String(data: data, encoding: .utf8)
        {
            loadHTMLString(baseString, baseURL: url)
        }
    }

    // Called once the webpage has been loaded - now we can set the contents of our editor
    func onEditorLoaded() {
        setContent(content: initialModel.html).sink { [weak self] in
            guard let self = self else { return }
            (self.superview as? MemriTextEditor_UIKitWrapper)?.showActivityIndicator = false
            self.updateToolbar()
            self.updateSearchState().sink {}.store(in: &self.cancellableBag)
            self.grabFocus(takeFirstResponder: false)
        }.store(in: &cancellableBag)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let toolbarIconFont = Font.system(size: 17).bold()

    @ArrayBuilder<MemriTextEditor_Toolbar.Item>
    func getToolbarItems() -> [MemriTextEditor_Toolbar.Item] {
        let currentColorVar = currentFormatting["text_color"] as? String
        let matchingColor = MemriTextEditorColor.allCases
            .first(where: { $0.cssVar == currentColorVar })?.swiftColor

        switch toolbarState {
        case .main:
            let isHeading = (currentFormatting["heading"] as? Int).map { $0 != 0 } ?? false
            MemriTextEditor_Toolbar.Item.button(
                label: "Bold",
                icon: Image(systemName: "bold").eraseToAnyView(),
                isActive: currentFormatting["bold"] as? Bool ?? false,
                onPress: { [weak self] in self?.executeEditorCommand("bold") }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "Italic",
                icon: Image(systemName: "italic").eraseToAnyView(),
                isActive: currentFormatting["italic"] as? Bool ?? false,
                onPress: { [weak self] in self?.executeEditorCommand("italic") }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "Underline",
                icon: Image(systemName: "underline").eraseToAnyView(),
                isActive: currentFormatting["underline"] as? Bool ?? false,
                onPress: { [weak self] in self?.executeEditorCommand("underline") }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "Strike",
                icon: Image(systemName: "strikethrough").eraseToAnyView(),
                isActive: currentFormatting["strike"] as? Bool ?? false,
                onPress: { [weak self] in self?.executeEditorCommand("strike") }
            )
            MemriTextEditor_Toolbar.Item.button(label: "Color", icon: VStack {
                Image(systemName: "paintpalette")
                if let color = matchingColor {
                    Capsule().fill(color).frame(height: 4)
                }
            }.frame(width: 30, height: 30).eraseToAnyView(),
            isActive: false,
            onPress: { [weak self] in
                self?.toolbarState.toggleColor()
            })
            MemriTextEditor_Toolbar.Item.button(
                label: "Highlighter",
                icon: Image(systemName: "highlighter").eraseToAnyView(),
                isActive: currentFormatting["highlight_color"] != nil,
                onPress: { [weak self] in self?.executeEditorCommand(
                    "highlight_color",
                    info: ["backColor": "var(--text-highlight)"]
                ) }
            )
            MemriTextEditor_Toolbar.Item.divider
            MemriTextEditor_Toolbar.Item.button(
                label: "Heading",
                icon: Text("H").font(toolbarIconFont).eraseToAnyView(),
                isActive: isHeading,
                onPress: { [weak self] in self?.toolbarState.toggleHeading() }
            )
            // Quote not correctly toggling off currently - disabled until this is fixed
//            MemriTextEditor_Toolbar.Item.button(label: "Quote", icon: Image(systemName: "decrease.quotelevel").eraseToAnyView(),
//                                                isActive: currentFormatting["blockquote"] as? Bool ?? false,
//                                                onPress: { [weak self] in self?.toggleFormat("blockquote") })

            MemriTextEditor_Toolbar.Item.button(
                label: "Take photo",
                icon: Image(systemName: "camera").eraseToAnyView(),
                isActive: false,
                onPress: { [weak self] in self?.attemptToSelectPhoto(useCamera: true) }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "Image",
                icon: Image(systemName: "photo").eraseToAnyView(),
                isActive: false,
                onPress: { [weak self] in self?.attemptToSelectPhoto(useCamera: false) }
            )
            if !isHeading {
                MemriTextEditor_Toolbar.Item.button(
                    label: "Todo List",
                    icon: Image(systemName: "checkmark.square").eraseToAnyView(),
                    isActive: currentFormatting["todo_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("todo_list") }
                )
                MemriTextEditor_Toolbar.Item.button(
                    label: "Unordered List",
                    icon: Image(systemName: "list.bullet").eraseToAnyView(),
                    isActive: currentFormatting["bullet_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("bullet_list") }
                )
                MemriTextEditor_Toolbar.Item.button(
                    label: "Ordered List",
                    icon: Image(systemName: "list.number").eraseToAnyView(),
                    isActive: currentFormatting["ordered_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("ordered_list") }
                )
                MemriTextEditor_Toolbar.Item.button(
                    label: "Outdent List",
                    icon: Image(systemName: "decrease.indent").eraseToAnyView(),
                    hideInactive: true,
                    isActive: currentFormatting["lift_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("lift_list") }
                )
                MemriTextEditor_Toolbar.Item.button(
                    label: "Indent List",
                    icon: Image(systemName: "increase.indent").eraseToAnyView(),
                    hideInactive: true,
                    isActive: currentFormatting["sink_list"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("sink_list") }
                )
                MemriTextEditor_Toolbar.Item.button(
                    label: "Code block",
                    icon: Image(systemName: "textbox").eraseToAnyView(),
                    isActive: currentFormatting["code_block"] as? Bool ?? false,
                    onPress: { [weak self] in self?.executeEditorCommand("code_block") }
                )
            }

        case .color:
            MemriTextEditorColor.allCases.map { color in
                let isActiveColor = currentColorVar == color.cssVar
                return MemriTextEditor_Toolbar.Item.button(
                    label: "Set color",
                    icon: Circle().fill(color.swiftColor ?? .black)
                        .overlay(Circle().strokeBorder(isActiveColor ? Color.primary : .clear))
                        .frame(width: 30, height: 30).eraseToAnyView(),
                    isActive: false,
                    onPress: { [weak self] in self?.executeEditorCommand(
                        "text_color",
                        info: ["color": color.cssVar, "override": true]
                    ) }
                )
            }
        case .heading:
            MemriTextEditor_Toolbar.Item.button(
                label: "Body",
                icon: Text("Body").font(toolbarIconFont).padding(.horizontal, 4).eraseToAnyView(),
                isActive: (currentFormatting["heading"] as? Int).map { $0 == 0 } ?? true,
                onPress: { [weak self] in
                    self?.executeEditorCommand("heading", info: ["level": 0])
                }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "H1",
                icon: Text("H1").font(toolbarIconFont).padding(.horizontal, 4).eraseToAnyView(),
                isActive: (currentFormatting["heading"] as? Int).map { $0 == 1 } ?? false,
                onPress: { [weak self] in
                    self?.executeEditorCommand("heading", info: ["level": 1])
                }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "H2",
                icon: Text("H2").font(toolbarIconFont).padding(.horizontal, 4).eraseToAnyView(),
                isActive: (currentFormatting["heading"] as? Int).map { $0 == 2 } ?? false,
                onPress: { [weak self] in
                    self?.executeEditorCommand("heading", info: ["level": 2])
                }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "H3",
                icon: Text("H3").font(toolbarIconFont).padding(.horizontal, 4).eraseToAnyView(),
                isActive: (currentFormatting["heading"] as? Int).map { $0 == 3 } ?? false,
                onPress: { [weak self] in
                    self?.executeEditorCommand("heading", info: ["level": 3])
                }
            )
            MemriTextEditor_Toolbar.Item.button(
                label: "H4",
                icon: Text("H4").font(toolbarIconFont).padding(.horizontal, 4).eraseToAnyView(),
                isActive: (currentFormatting["heading"] as? Int).map { $0 == 4 } ?? false,
                onPress: { [weak self] in
                    self?.executeEditorCommand("heading", info: ["level": 4])
                }
            )
        case .image:
            MemriTextEditor_Toolbar.Item
                .label(Text("Image selected").font(toolbarIconFont).padding(.horizontal, 4)
                    .eraseToAnyView())
            MemriTextEditor_Toolbar.Item.button(
                label: "Delete",
                icon: Image(systemName: "trash").foregroundColor(.red).eraseToAnyView(),
                isActive: false,
                onPress: { [weak self] in self?.executeEditorCommand("deleteSelection") }
            )
        }
    }

    func updateToolbar() {
        let view = MemriTextEditor_Toolbar(
            textView: self,
            items: getToolbarItems(),
            showBackButton: toolbarState.showBackButton,
            onBackButton: { [weak self] in self?.toolbarState.onBack() }
        )
        _setToolbar(view)
        toolbarWrapperView?.sizeToFit()
        reloadInputViews()
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

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        (superview as? MemriTextEditor_UIKitWrapper)?.showActivityIndicator = isLoading
        #if targetEnvironment(macCatalyst)
            if let superview = superview as? MemriTextEditor_UIKitWrapper {
                superview.toolbar = toolbarHost?.view
            }
        #endif
    }

    func _setToolbar(_ view: MemriTextEditor_Toolbar) {
        if let hc = toolbarHost {
            hc.rootView = view
            toolbarWrapperView?.sizeToFit()
        }
        else {
            let toolbarHost = UIHostingControllerNoSafeArea(rootView: view)
            self.toolbarHost = toolbarHost
            #if targetEnvironment(macCatalyst)
                if let superview = superview as? MemriTextEditor_UIKitWrapper {
                    superview.toolbar = toolbarHost.view
                }
            #else
                let wrapper = ToolbarWrapperView(toolbarView: toolbarHost.view)
                wrapper.sizeToFit()
                toolbarWrapperView = wrapper
            #endif
        }
    }

    func executeEditorCommand(_ format: String, info: [String: Any] = [:]) {
        futureForEditorCommand(format: format, info: info)
            .receive(on: DispatchQueue.main)
            .sink {}
            .store(in: &cancellableBag)
    }

    func grabFocus(takeFirstResponder: Bool = true) {
        evaluateJavaScript("window.editor.focus();")
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
                evaluateJavaScript("window.scrollToSelection();")
            }
        }
    }
}

extension MemriTextEditor_UIKit {
    func attemptToSelectPhoto(useCamera: Bool) {
        imageSelectionHandler?.presentImageSelectionUI(useCamera: useCamera)
            .sink { [weak self] url in
                if let url = url {
                    self?.handlePhotoInsertion(url: url)
                }
            }.store(in: &cancellableBag)
    }

    func handlePhotoInsertion(url: URL) {
        executeEditorCommand("image", info: ["src": url.absoluteString])
    }
}

extension MemriTextEditor_UIKit {
    class FileHandler: NSObject, WKURLSchemeHandler {
        var fileHandler: MemriTextEditorFileHandler?

        func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
            do {
                guard let url = urlSchemeTask.request.url,
                      let data = getFileData(forEditorURL: url)
                else {
                    throw "Failed to get data"
                }

                urlSchemeTask.didReceive(URLResponse(
                    url: url,
                    mimeType: "text/html",
                    expectedContentLength: data.count,
                    textEncodingName: nil
                ))
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
            catch {
                print(
                    "Unexpected error when get data from URL: \(urlSchemeTask.request.url?.absoluteString ?? "No url")"
                )
                urlSchemeTask.didFailWithError(error)
            }
        }

        func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
            //
        }

        func getFileData(forEditorURL url: URL) -> Data? {
            fileHandler?.getFileData(forEditorURL: url)
        }
    }
}

extension MemriTextEditor_UIKit: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if let content = message.body as? [String: Any] {
            if let formatting = content["format"] as? [String: Any] {
                currentFormatting = formatting
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
        onEditorLoaded()
    }
}

extension MemriTextEditor_UIKit: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        nil
    }
}

import Combine
extension MemriTextEditor_UIKit {
    func setContent(content: String?) -> Future<Void, Never> {
        let content = content?.escapeForJavascript()
        let setContent = content
            .map {
                "window.editor.options.content = \"\($0)\"; window.editor.view.updateState(window.editor.createState());"
            }
        return Future { promise in
            if let script = setContent {
                self.evaluateJavaScript(script) { _, _ in
                    promise(.success(()))
                }
            }
            else {
                promise(.success(()))
            }
        }
    }

    func futureForEditorCommand(format: String, info: [String: Any] = [:]) -> Future<Void, Never> {
        let infoString =
            (try? String(data: JSONSerialization.data(withJSONObject: info), encoding: .utf8)) ?? ""
        let script = "window.editor.commands.\(format)(\(infoString));"
        return Future { promise in
            self.evaluateJavaScript(script) { _, _ in
                promise(.success(()))
            }
        }
    }

    func updateSearchState() -> Future<Void, Never> {
        let script = searchTerm.map { searchString in
            "window.editor.commands.find(\"\(searchString.escapeForJavascript())\");"
        } ?? "window.editor.commands.clearSearch()"
        return Future { promise in
            self.evaluateJavaScript(script) { _, _ in
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
        clipsToBounds = false
        toolbarView.clipsToBounds = false
        addSubview(toolbarView)
        translatesAutoresizingMaskIntoConstraints = false
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: toolbarView.intrinsicContentSize.width,
            height: toolbarView.intrinsicContentSize.height + safeAreaInsets.bottom
        )
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }
}
