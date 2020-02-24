//
//  NoteList.swift
//  memri
//
//  Created by Koen van der Veen on 20/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

class DataStore: ObservableObject {
    @Published var data = [Note(uid: "0x0", title: "Show & tell", text:"abc"),
                           Note(uid: "0x1", title: "italian recipes", text:"def"),
                           Note(uid: "0x2", title: "shopping list", text: "qwe")]
        
}

