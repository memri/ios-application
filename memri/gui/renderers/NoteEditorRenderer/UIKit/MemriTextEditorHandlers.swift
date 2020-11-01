//
//  MemriTextEditorFileHandler.swift
//  memri
//
//  Created by Toby Brennan on 15/10/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import WebKit
import Combine

protocol MemriTextEditorFileHandler {
    func getFileData(forEditorURL url: URL) -> Data?
}

protocol MemriTextEditorImageSelectionHandler {
    func presentImageSelectionUI(useCamera: Bool) -> AnyPublisher<URL?, Never>
}
