//
//  UIPreloader.swift
//  memri
//
//  Created by T Brennan on 7/11/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import WebKit

class MemriWKWebView: WKWebView {
    var customInputAccessory: UIView?
    
    override var inputAccessoryView: UIView? { customInputAccessory }
}

class MemriFileSchemeHandler: NSObject, WKURLSchemeHandler {
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

class UIPreloader {
    private static var preloadedWebView: MemriWKWebView?
    
    static func makeWebView() -> MemriWKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(MemriFileSchemeHandler(), forURLScheme: "memriFile")
        let wv = MemriWKWebView(frame: .zero, configuration: config)
        wv.loadHTMLString("", baseURL: nil)
        return wv
    }
    
    static func prepare() {
        if preloadedWebView == nil {
            preloadedWebView = makeWebView()
        }
    }
    
    static func getWebView() -> MemriWKWebView {
        let wv = preloadedWebView ?? makeWebView()
        preloadedWebView = nil
        defer { prepare() }
        return wv
    }
}
