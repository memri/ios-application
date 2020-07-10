//
//  contextTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class contextTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testBooting() throws {
		let root = try RootContext(name: "", key: "")
		try root.boot()

		XCTAssertEqual(root.cascadingView?.sessionView.viewDefinition!.selector, "[view]")
	}

	func testSubContext() throws {
		let root = try RootContext(name: "", key: "")
		try root.boot()
		let sub = try root.createSubContext(Session())

		XCTAssertEqual(sub.cascadingView?.sessionView.viewDefinition, nil)
	}

	func testDynamicProperties() throws {
		let root = try RootContext(name: "", key: "")
		try root.boot()

		root.showSessionSwitcher = true
		XCTAssertEqual(root.showSessionSwitcher, true)
		root.showSessionSwitcher = false
		XCTAssertEqual(root.showSessionSwitcher, false)

		root.showNavigation = true
		XCTAssertEqual(root.showNavigation, true)
		root.showNavigation = false
		XCTAssertEqual(root.showNavigation, false)
	}

	//    func testPerformanceExample() throws {
	//        // This is an example of a performance test case.
	//        self.measure {
	//            // Put the code you want to measure the time of here.
	//        }
	//    }
}
