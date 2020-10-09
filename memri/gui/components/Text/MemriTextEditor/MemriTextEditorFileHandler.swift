//
//  MemriTextEditorFileHandler.swift
//  memri
//
//  Created by Toby Brennan on 15/10/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import WebKit

protocol MemriTextEditorFileHandler {
    func getFileData(forEditorURL url: URL) -> Data?
}

struct MemriNotesFileHandler: MemriTextEditorFileHandler {
    var noteID: Int
    
    func getFileData(forEditorURL url: URL) -> Data? {
        let realm = try? DatabaseController.getRealmSync()
        
        guard let fileUID = url.host,
              let note = realm?.object(ofType: Note.self, forPrimaryKey: noteID),
              let file = note.file?.first(where: { $0.filename == fileUID }),
              let data = file.asData
        else { return nil }
        return data
    }
}

extension MemriTextEditor_UIKit {
    class FileHandler: NSObject, WKURLSchemeHandler {
        var fileHandler: MemriTextEditorFileHandler?
        func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
            do {
                guard let url = urlSchemeTask.request.url,
                      let data = getFileData(forEditorURL: url) else {
                    throw "Failed to get data"
                }
                
                urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: nil))
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            } catch {
                print("Unexpected error when get data from URL: \(urlSchemeTask.request.url?.absoluteString ?? "No url")")
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
