//
//  TestVkew.swift
//  memri
//
//  Created by Koen van der Veen on 21/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct TestView: View {
    @ObservedObject var note: Note
    var body: some View {
        VStack{
            Text(self.note.text)
            Text("test view")
            Button(action: {
                self.note.text="IK BEN VERANDERD"
            }) {
                Text("click")
            }
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView(note: DataStore().data[0])
    }
}
