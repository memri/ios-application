//
//  Note.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation
import Combine

class Note: Identifiable, ObservableObject {
    
    @Published public var uid: String
    @Published public var title: String
    @Published public var text: String

    var id: String {
        return self.uid
    }
    
    init(uid: String, title: String, text: String){
        self.uid=uid
        self.title=title
        self.text=text
    }
}
