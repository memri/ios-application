////
////  SessionTest.swift
////  memriTests
////
////  Created by Koen van der Veen on 27/02/2020.
////  Copyright © 2020 memri. All rights reserved.
////
//
//import XCTest
//@testable import memri
//
//class SessionTest: XCTestCase {
//
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testLoadEmptySessionFromJson() {
//        let session =  try! Session.from_json("empty_session")
//        XCTAssert(session.currentView.rendererName == "List")
//        XCTAssert(session.currentView.resultSet.data == [])
//    }
//    
//    func testLoadEmptySessionsFromJson(){
//        // load multiple
//        let sessions =  try! Sessions.fromJSONFile("empty_sessions")
//        print(sessions.currentSession.currentView.resultSet.data[0].properties)
//        XCTAssert(sessions.currentSession.currentView.resultSet.data.count > 0)
//        XCTAssert(sessions.currentSession.currentView.actionButton!.actionName == "add")
//    }
//    
//    
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
//}
