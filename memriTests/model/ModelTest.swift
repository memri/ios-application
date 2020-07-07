//
//  Model.swift
//  memriTests
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class ModelTest: XCTestCase {
	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testInitSearchResult() throws {
		//        let items = try Item.fromJSONFile("test_dataItems")
		//        let sr = SearchResult.fromItems(items)
		//        XCTAssert(sr.data[0].id == "0x01" && sr.data[1].id == "0x02")
	}

	func testInitCache() {
		//        let key = "mytestkey"
		//        let testPodAPI = PodAPI(key)
		//        let _ = Cache(testPodAPI)
	}

	func testQueryCache() {
		//        let key = "mytestkey"
		//        let testPodAPI = PodAPI(key)
		//        let cache = Cache(testPodAPI)
		//        let sr = cache.getItemByType(type: "note")!
		//        XCTAssert(sr.data[0].id == "0x01" && sr.data[1].id == "0x02")
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
