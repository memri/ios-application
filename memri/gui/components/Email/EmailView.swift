//
// EmailView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct EmailView: UIViewRepresentable {
    var emailHTML: String?

    func makeUIView(context: Context) -> EmailViewUIKit {
        EmailViewUIKit()
    }

    func updateUIView(_ emailView: EmailViewUIKit, context: Context) {
        emailView.emailHTML = emailHTML
    }
}
