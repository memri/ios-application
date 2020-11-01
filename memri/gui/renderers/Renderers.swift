//
// Renderers.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

public class Renderers {
    static var rendererTypes: [String: RendererType] = {
        Dictionary(uniqueKeysWithValues: [
            ListRendererController.rendererType,
            GridRendererController.rendererType,
            NoteEditorRendererController.rendererType,
            GeneralEditorRendererController.rendererType,
            CustomRendererController.rendererType,
            MapRendererController.rendererType,
            FileRendererController.rendererType,
            LabelAnnotationRendererController.rendererType,
            MessageRendererController.rendererType,
            CalendarRendererController.rendererType,
            TimelineRendererController.rendererType,
            ChartRendererController.rendererType,
            PhotoViewerRendererController.rendererType,
            EmailThreadRendererController.rendererType,
        ].map { ($0.name, $0) })
    }()

    private init() {}
}

public struct RendererType {
    var name: String
    var icon: String
    var makeController: (_ context: MemriContext, _ config: CascadingRendererConfig?)
        -> RendererController
    var makeConfig: (
        _ head: CVUParsedDefinition?,
        _ tail: [CVUParsedDefinition]?,
        _ host: Cascadable?
    ) -> CascadingRendererConfig
}
