//
//  CombineViewFilesTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 23/05/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class CombineViewFilesTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testReadsDefaultViews() throws {
		XCTAssertTrue(getDefaultViewContents() != "")
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
