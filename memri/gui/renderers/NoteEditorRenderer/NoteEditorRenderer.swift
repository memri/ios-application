//
// MessageRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI
import Combine

class NoteEditorRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "noteEditor", icon: "doc.richtext", makeController: NoteEditorRendererController.init, makeConfig: NoteEditorRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? NoteEditorRendererConfig) ?? NoteEditorRendererConfig()
    }
    
    let context: MemriContext
    let config: NoteEditorRendererConfig
    
    
    func makeView() -> AnyView {
        NoteEditorRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        NoteEditorRendererConfig(head, tail, host)
    }
    
    var note: Note? {
        context.item as? Note
    }
    
    var searchTerm: String? {
        context.currentView?.filterText
    }
    
    var editModeBinding: Binding<Bool> {  Binding<Bool>(
        get: { self.context.editMode },
        set: { self.context.editMode = $0 }
    )}
    
    @Published var showingImagePicker: Bool = false
    @Published var showingImagePicker_shouldUseCamera: Bool = false
    var onImagePickerCompletion: ((URL?) -> Void)?
    
    func getEditorModel() -> MemriTextEditorModel {
        MemriTextEditorModel(
            title: note?.title,
            body: note?.content ?? ""
        )
    }
    
    func handleModelUpdate(_ newModel: MemriTextEditorModel) {
        DatabaseController.sync(write: true) { _ in
            note?.title = newModel.title
            note?.content = newModel.body
        }
    }
    
    func attachImage(image: UIImage) {
        
    }
}

extension NoteEditorRendererController: MemriTextEditorImageSelectionHandler {
    func presentImageSelectionUI(useCamera: Bool) -> AnyPublisher<URL?, Never> {
        self.showingImagePicker_shouldUseCamera = useCamera
        self.showingImagePicker = true
        return Just(nil).eraseToAnyPublisher()
    }
}

extension NoteEditorRendererController: MemriTextEditorFileHandler {
    func getFileData(forEditorURL url: URL) -> Data? {
        guard let fileUID = url.host,
              let note = self.note,
              let file = note.file?.first(where: { $0.filename == fileUID }),
              let data = file.asData
        else { return nil }
        return data
    }
}

class NoteEditorRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var showSortInConfig: Bool { false }
    var showContextualBarInEditMode: Bool { false }
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }
}

struct NoteEditorRendererView: View {
    @ObservedObject var controller: NoteEditorRendererController
    
    var body: some View {
        MemriTextEditor(model: { [weak controller] in controller?.getEditorModel() ?? MemriTextEditorModel() },
                        onModelUpdate: { [weak controller] newModel in
                            controller?.handleModelUpdate(newModel)
                        },
                        imageSelectionHandler: controller,
                        fileHandler: controller,
                        searchTerm: controller.searchTerm,
                        isEditing: controller.editModeBinding)
            .sheet(isPresented: $controller.showingImagePicker) {
                ImagePickerView(
                    sourceType: controller.showingImagePicker_shouldUseCamera ? .camera : .photoLibrary,
                    onSelectedImage: { selectedImage in
                        if let selectedImage = selectedImage {
                            controller.attachImage(image: selectedImage)
                        }
                    })
            }

    }
}
