//
//  CacheTest.swift
//  memriTests
//
//  Created by Ruben Daniels on 3/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import XCTest

class CacheTest: XCTestCase {
	var testCache: Cache

	override init() {
		testCache = try! Cache(PodAPI("test"))

		super.init()
	}

	override func setUp() {
		// reset cache
		testCache.scheduleUIUpdate = { _ in }
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func getCountry(_ name: String) -> Country? {
        let realm = DatabaseController.getRealm()
		return realm.objects(Country.self).filter("name = '\(name)'").first
	}

	func testCacheInstall() throws {
		// Also tests getItemById
		try testCache.install("default_database")
        let realm = DatabaseController.getRealm()
		XCTAssertTrue(realm.objects(Country.self).count > 0)
	}

	func testGetItem() throws {
		try testCache.install("default_database")
		XCTAssertEqual(getCountry("Aruba")?.getString("name"), "Aruba")
	}

	func testEmptyQuery() throws {
		try testCache.query(Datasource(query: "")) { _, items in
			XCTAssertEqual(items, nil)
		}
	}

	func testTypeQuery() throws {
		try testCache.install("default_database")

		for dtype in ItemFamily.allCases {
			try testCache.query(Datasource(query: dtype.rawValue)) { _, items in
				if let result = items {
					XCTAssertTrue(result.allSatisfy { item in item.genericType == dtype.rawValue })
				} else {
					XCTFail()
				}
			}
		}
	}

	func testFilteredQuery() {
		// TODO:
	}

	func testSortedQuery() {
		// TODO:
	}

	func testParseQuery() {
		let (type1, filter1) = testCache.parseQuery("note")
		XCTAssertTrue(type1 == "note"); XCTAssertTrue(filter1 == nil)

		let (type2, filter2) = testCache.parseQuery("* x<40")
		XCTAssertTrue(type2 == "*"); XCTAssertTrue(filter2 == "x<40")

		let (type3, filter3) = testCache.parseQuery("note x == 40")
		XCTAssertTrue(type3 == "note"); XCTAssertTrue(filter3 == "x == 40")
	}

	func testGetResultSet() throws {
		try testCache.install("default_database")
		// TODO: not sure what this should test yet
		_ = testCache.getResultSet(Datasource(query: "*"))
	}

	func testAddToCache() throws {
		let note = Note()
		_ = try Cache.addToCache(note)
		// TODO: what to test here
	}

	func testAddToCacheConflicts() throws {
		try testCache.install("default_database")
		// TODO: FIX
		//        let item: Country = testCache.getItemById("country", "Aruba")
		//        let cachedNote = try testCache.addToCache(note)
		//        item.set("starred", true)
//
		//        let item2: Country = testCache.getItemById("country", "Aruba")
		//        // versionnumber 1 higher
		//        item2.uid = note1.uid
		//        item2.syncstate = item1.syncstate +1
		//        item2.set("content", somthing else")
		//        item2.set("starred", true)
		//        item2.set("starred", true)
//
		//        let cachedNote = try testCache.addToCache(note2)
//
//
//
//
//
		//        // 1) has to be cached not partiallyloaded, should have actionNeeded,
		//        // and safeMerge is not possible
//
		//        // should conflict when local and server is changed
//
		//        let note = Note()
		//        let cachedNote = try testCache.addToCache(note)

		// TODO: what to test here
	}

	func testDelete() throws {
		try testCache.install("default_database")
		let item = getCountry("Aruba")
		testCache.delete(item!)
		let item2 = getCountry("Aruba")
		XCTAssertTrue(item2?.deleted == true || item2 == nil)
	}

	func testDeleteMulti() throws {
		try testCache.install("default_database")
		let items = [getCountry("Aruba")!,
					 getCountry("Antarctica")!]

		testCache.delete(items)

		let items2 = [getCountry("Aruba"),
					  getCountry("Antarctica")]

		XCTAssertTrue(items2.allSatisfy { $0?.deleted == true || $0 == nil })
	}

	func testDuplicate() throws {
		try testCache.install("default_database")
		let item = getCountry("Aruba")
		let copy = try testCache.duplicate(item!)
		let cls = item!.getType()

		for prop in item!.objectSchema.properties {
			if prop.name != cls!.primaryKey() {
				_ = item!.isEqualProperty(prop.name, copy)
			}
		}
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
}
