//
// CVU_Text.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct CVU_Text: View {
    var nodeResolver: UINodeResolver

    var content: String? {
        nodeResolver.string(for: "text")?.nilIfBlank
    }

    var body: some View {
        content.map {
            Text($0)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct CVU_SmartText: View {
    var nodeResolver: UINodeResolver

    var content: String? {
        nodeResolver.string(for: "text")?.nilIfBlank
    }

    var body: some View {
        content
            .map {
                MemriSmartTextView(
                    string: $0,
                    font: nodeResolver.font(),
                    color: nodeResolver.color()
                )
            }
    }
}

struct CVU_TextField: View {
    var nodeResolver: UINodeResolver
    var editModeBinding: Binding<Bool>

    // Secure mode hides the input (eg. for passwords)
    var secureMode: Bool {
        nodeResolver.bool(for: "secure", defaultValue: false)
    }

    var hint: String? {
        nodeResolver.string(for: "hint")?.nilIfBlank
    }

    var contentBinding: Binding<String?> {
        nodeResolver.binding(for: "value", defaultValue: nil)
    }

    var body: some View {
        MemriTextField(
            value: contentBinding,
            placeholder: hint,
            textColor: nodeResolver.color()?.uiColor,
            isEditing: editModeBinding,
            isSharedEditingBinding: true,
            secureMode: secureMode
        )
    }
}
