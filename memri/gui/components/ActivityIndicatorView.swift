//
// ActivityIndicatorView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {
    var isAnimating: Bool = true
    let style: UIActivityIndicatorView.Style = .medium

    func makeUIView(context _: Context)
        -> UIActivityIndicatorView
    {
        UIActivityIndicatorView(style: style)
    }

    func updateUIView(
        _ uiView: UIActivityIndicatorView,
        context _: Context
    ) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct ActivityIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicatorView()
    }
}
