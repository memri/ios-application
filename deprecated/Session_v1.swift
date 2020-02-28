//
//  Session_v1.swift
//  memri
//
//  Created by Koen van der Veen on 27/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation


//public class Session: Codable {
//    var currentSessionViewIndex: Int
//    var sessionViews: [SessionView]
//    public var currentSessionView: SessionView {
//        if currentSessionViewIndex >= 0 {
//            return sessionViews[currentSessionViewIndex]
//        } else{
//            return sessionViews[0]
//        }
//    }
//
//    public init(currentSessionViewIndex: Int = 0, sessionViews: [SessionView]){
//        self.currentSessionViewIndex = currentSessionViewIndex
//        self.sessionViews = sessionViews
//    }
//
//    public func back(){
//        self.currentSessionViewIndex -= 1
//    }
//    public func forward(){
//        self.currentSessionViewIndex += 1
//    }
//
//    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
//        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
//        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
//        let jsonData = jsonString.data(using: .utf8)!
//        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
//        return session
//    }
//}
