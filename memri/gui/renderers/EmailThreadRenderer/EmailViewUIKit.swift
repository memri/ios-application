//
// EmailViewUIKit.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import SwiftSoup
import UIKit
import WebKit

class EmailViewUIKit: UIView {
    // Config
    var emailHTML: String? {
        didSet {
            if emailHTML != oldValue {
                configure()
            }
        }
    }

    // TODO: Depending on user settings this should default to false and have a UI option to load remote
    var loadRemoteContent: Bool = true {
        didSet {
            loadContent()
        }
    }

    var enableHeightConstraint = false {
        didSet {
            heightConstraint?.isActive = enableHeightConstraint
        }
    }

    var onSizeUpdated: ((CGFloat) -> Void)?

    let defaultSize: CGFloat = 30

    var contentHeight: CGFloat {
        get { heightConstraint?.constant ?? defaultSize }
        set { heightConstraint?.constant = newValue }
    }

    // Internal
    private let webView: WKWebView
    private var isLoaded: Bool = false {
        didSet {
            if isLoaded {
                activityIndicator.stopAnimating()
                UIView.animate(withDuration: 0.2) {
                    self.webView.alpha = 1.0
                }
            }
            else {
                activityIndicator.startAnimating()
            }
        }
    }

    private var heightConstraint: NSLayoutConstraint?
    private let activityIndicator = UIActivityIndicatorView()

    init() {
        webView = UIPreloader.getWebView()
        super.init(frame: .zero)

        webView.alpha = 0

        clipsToBounds = true

        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.alwaysBounceVertical = false
//        webView.scrollView.isScrollEnabled = false
        addSubview(webView)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium

        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        heightConstraint = heightAnchor.constraint(equalToConstant: defaultSize)
        heightConstraint?.priority = .defaultLow
        heightConstraint?.isActive = enableHeightConstraint

        activityIndicator.startAnimating()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        webView.frame = bounds
        super.layoutSubviews()
    }

    var loadingCancellable: AnyCancellable?

    func configure() {
        guard emailHTML != nil else {
            loadingCancellable?.cancel()
            loadingCancellable = nil
            _loadPlaceholder()
            return
        }
        _loadPlaceholder()
        loadContent()
    }

    private func loadContent() {
        loadingCancellable = _compileContentRules().replaceError(with: nil).sink { ruleList in
            ruleList.map {
                self.webView.configuration.userContentController.removeAllContentRuleLists()
                self.webView.configuration.userContentController.add($0)
            }
            self._loadContent()
        }
    }

    private func _compileContentRules() -> Future<WKContentRuleList?, Error> {
        if loadRemoteContent {
            return WKContentRuleListStore.default()
                .compileContentRuleList(
                    forIdentifier: "ContentBlockingRules",
                    encodedContentRuleList: ""
                )
        }
        else {
            return WKContentRuleListStore.default()
                .compileContentRuleList(forIdentifier: "ContentBlockingRules",
                                        encodedContentRuleList: blockRules)
        }
    }

    private func _loadPlaceholder() {
        isLoaded = false
        let bundleURL = Bundle.main.bundleURL
        webView.loadHTMLString(emailHTML ?? "", baseURL: bundleURL)
    }

    private func _loadContent() {
        guard let jsURL = Bundle.main.url(
            forResource: "HTMLResources/purify.min",
            withExtension: "js"
        ),
            let jsContent = try? String(contentsOf: jsURL) else { return }
        let domPurifyScript = WKUserScript(
            source: jsContent,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        let sanitizeScript = WKUserScript(
            source: getContentLoaderString(),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.addUserScript(domPurifyScript)
        webView.configuration.userContentController.addUserScript(sanitizeScript)
    }

    func evaluateWebViewHeight(_: WKWebView) {
        let script = """
        document.documentElement.offsetHeight
        """

        // document.documentElement.scrollHeight - issue when webview larger than content

        webView.evaluateJavaScript(script) { result, _ in
            guard let height = result as? CGFloat else {
                return
            }
            let adjustedHeight = ceil(height) + 1

            guard adjustedHeight != self.contentHeight else {
                return
            }
            self.contentHeight = adjustedHeight
            self.onSizeUpdated?(adjustedHeight)
        }
    }

    func getContentLoaderString() -> String {
        """
        'use strict';
        var dirty = document.documentElement.outerHTML.toString();
        var clean = DOMPurify.sanitize(dirty, { WHOLE_DOCUMENT: true, RETURN_DOM: true});
        document.documentElement.replaceWith(clean);

        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode("body { font-family: -apple-system, Helvetica; sans-serif; }"));
        document.getElementsByTagName('head')[0].appendChild(style);

        var metaWidth = document.createElement('meta');
        metaWidth.name = "viewport";
        metaWidth.content = "width=device-width, initial-scale=1, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no";
        document.getElementsByTagName('head')[0].appendChild(metaWidth);
        """
    }
}

extension EmailViewUIKit: WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
    //    func scrollViewDidZoom(_ scrollView: UIScrollView) {
    //        if (!webView.isLoading && scrollView.contentSize.width < webView.frame.width) {
    //            let scale = (webView.frame.width * scrollView.zoomScale/scrollView.contentSize.width)
    //            webView.scrollView.setZoomScale(scale, animated: false)
    //        }
    //        evaluateWebViewHeight(webView)
    //    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        evaluateWebViewHeight(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        evaluateWebViewHeight(webView)
        isLoaded = true
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated,
           let link = navigationAction.request.url
        {
            if link.scheme == "mailto" {
                // We could handle email mailto links differently (eg. open compose dialog)
                //                let email = link.absoluteString
                decisionHandler(.cancel)
                UIApplication.shared.open(link)
                return
            }
            else {
                decisionHandler(.cancel)
                UIApplication.shared.open(link)
                return
            }
        }
        decisionHandler(.allow)
    }
}

extension WKContentRuleListStore {
    func compileContentRuleList(
        forIdentifier identifier: String,
        encodedContentRuleList: String
    ) -> Future<WKContentRuleList?, Error> {
        Future { promise in
            self.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: encodedContentRuleList
            ) { ruleList, error in
                if let ruleList = ruleList {
                    promise(.success(ruleList))
                }
                else if let error = error {
                    promise(.failure(error))
                }
                else {
                    promise(.success(nil))
                }
            }
        }
    }
}

let blockRules = """
[
{
"trigger": {
"url-filter": ".*",
"resource-type": [
"image"
]
},
"action": {
"type": "block"
}
},
{
"trigger": {
"url-filter": "file://.*"
},
"action": {
"type": "ignore-previous-rules"
}
}
]
"""

extension String {
    func escapeForJavascript() -> String {
        let string = try? String(
            data: JSONSerialization.data(withJSONObject: [self], options: []),
            encoding: .utf8
        )?.dropFirst(2).dropLast(2)
        return string.map(String.init) ?? ""
    }
}
