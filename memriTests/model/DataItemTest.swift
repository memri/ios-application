//
//  DataItemTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 30/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class DataItemTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testDeserializeDataItem() {
		let data = Data("""
		{
		    "memriID": "0x012345",
		}
		""".utf8
		)
		let item: DataItem = try! JSONDecoder().decode(DataItem.self, from: data)
	}

	func testGetString() {
		let data = Data("""
		{
		    "memriID": "0x012345",
		}
		""".utf8
		)
		let item: DataItem = try! JSONDecoder().decode(DataItem.self, from: data)

		XCTAssertTrue(item.getString("memriID") == "0x012345")
	}

	func testExample() throws {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct results.
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
