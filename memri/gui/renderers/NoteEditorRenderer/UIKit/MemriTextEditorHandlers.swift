//
// MemriTextEditorHandlers.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import WebKit

protocol MemriTextEditorFileHandler {
    func getFileData(forEditorURL url: URL) -> Data?
}

protocol MemriTextEditorImageSelectionHandler {
    func presentImageSelectionUI(useCamera: Bool) -> AnyPublisher<URL?, Never>
}
