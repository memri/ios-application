//
//  ViewTest.swift
//  memri
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

protocol Param: Decodable {}

extension Int: Param {}
extension String: Param {}

class SessionViewTest: XCTestCase {
	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testLoadSessionViewFromJson() throws {
		//        let sessionView =  try SessionView.fromJSONFile("empty_sessionview")
		//        XCTAssert(sessionView.title == "testtitle")
	}

	func testLoadActionFromJson() throws {
		//        var sessions = try Sessions.fromJSONFile("empty_sessions")

		//        let backDescription = try Action.from_json("back_action")
		//        let addDescription = try Action.from_json("add_action")
		//        let openViewDescription = try Action.from_json("openview_action")

		//        sessions.currentSession.executeAction(action: backDescription)
		//        sessions.currentSession.executeAction(action: addDescription)
		//        sessions.currentSession.executeAction(action: openViewDescription)
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
