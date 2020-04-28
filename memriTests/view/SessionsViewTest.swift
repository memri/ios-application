//
//  ViewTest.swift
//  memri
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

protocol Param: Decodable {}

extension Int: Param {}
extension String: Param {}




class ViewTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadSessionViewFromJson() {
//        let sessionView =  try! SessionView.fromJSONFile("empty_sessionview")
//        XCTAssert(sessionView.title == "testtitle")
    }
    
    func testLoadActionFromJson(){
//        var sessions = try! Sessions.fromJSONFile("empty_sessions")
        
//        let backDescription = try! ActionDescription.from_json("back_action")
//        let addDescription = try! ActionDescription.from_json("add_action")
//        let openViewDescription = try! ActionDescription.from_json("openview_action")
        
//        sessions.currentSession.executeAction(action: backDescription)
//        sessions.currentSession.executeAction(action: addDescription)
//        sessions.currentSession.executeAction(action: openViewDescription)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
