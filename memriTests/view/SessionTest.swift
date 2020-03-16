//
//  SessionTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 27/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri

class SessionTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadEmptySessionFromJson() {
        let session =  try! Session.from_json("empty_session")
        XCTAssert(session.currentSessionView.rendererName == "List")
        XCTAssert(session.currentSessionView.searchResult.data == [])
    }
    
    func testLoadEmptySessionsFromJson(){
        // load multiple
        let sessions =  try! Sessions.from_json("empty_sessions")
        print(sessions.currentSession.currentSessionView.searchResult.data[0].properties)
        XCTAssert(sessions.currentSession.currentSessionView.searchResult.data.count > 0)
        XCTAssert(sessions.currentSession.currentSessionView.actionButton!.actionName == "add")
    }
    
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
