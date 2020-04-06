//
//  Loading.swift
//  memri
//
//  Created by Ruben Daniels on 4/6/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct Loading<Content>: View where Content: View {

    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                if self.isShowing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                }
                else {
                    self.content()
//                        .disabled(self.isShowing)
//                        .blur(radius: self.isShowing ? 1 : 0)
//                        .opacity(self.isShowing ? 0.2 : 0)
                }
                    

//                .frame(width: geometry.size.width / 2,
//                       height: geometry.size.height / 5)
//                .background(Color.secondary.colorInvert())
//                .foregroundColor(Color.primary)
//                .cornerRadius(20)
//                .opacity(self.isShowing ? 1 : 0)

            }
        }
    }

}

struct Loading_Previews: PreviewProvider {
    static var previews: some View {
        Loading(isShowing: .constant(true)) {
            NavigationView {
                List(["1", "2", "3", "4", "5"], id: \.self) { row in
                    Text(row)
                }.navigationBarTitle(Text("A List"), displayMode: .large)
            }
        }
    }
}
