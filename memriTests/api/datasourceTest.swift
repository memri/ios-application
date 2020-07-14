//
//  installerTest.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

@testable import memri
import RealmSwift
import XCTest

class datasourceTest: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testUnique() throws {
		let ds1 = Datasource(value: ["query": "test", "sortAscending": true, "sortProperty": "foo"])
		let ds2 = Datasource(value: ["query": "test", "sortAscending": false, "sortProperty": "foo"])
		let ds3 = Datasource(value: ["query": "test", "sortAscending": true, "sortProperty": "bar"])
		let ds4 = Datasource(value: ["query": "test", "sortAscending": true, "sortProperty": "foo"])

		XCTAssertNotEqual(ds1.uniqueString, ds2.uniqueString)
		XCTAssertNotEqual(ds1.uniqueString, ds3.uniqueString)
		XCTAssertNotEqual(ds1.uniqueString, ds4.uniqueString)
	}

	func testFromCVU() throws {
		let strDef = """
		[datasource = pod] {
		    query: "test"
		    sortProperty: foo
		    sortAscending: false
		}
		"""

		let def = CVUStoredDefinition(value: ["definition": strDef])

		let root = try RootContext(name: "", key: "")
		try root.boot()

		let parsed = try root.views.parseDefinition(def)
		let ds = try Datasource.fromCVUDefinition(parsed as! CVUParsedDatasourceDefinition)

		XCTAssertEqual(ds.query, "test")
		XCTAssertEqual(ds.sortProperty, "foo")
		XCTAssertEqual(ds.sortAscending.value, false)
	}

	func testCascading() throws {
		let strDef1 = """
		[datasource = pod] {
		    query: "test"
		}
		"""
		let strDef2 = """
		[datasource = pod] {
		    sortProperty: foo
		}
		"""
		let strDef3 = """
		[datasource = pod] {
		    sortAscending: false
		}
		"""

		let def1 = CVUStoredDefinition(value: ["definition": strDef1])
		let def2 = CVUStoredDefinition(value: ["definition": strDef2])
		let def3 = CVUStoredDefinition(value: ["definition": strDef3])

		let root = try RootContext(name: "", key: "")
		try root.boot()

		let parsed = [
			try root.views.parseDefinition(def1) as! CVUParsedDatasourceDefinition,
			try root.views.parseDefinition(def2) as! CVUParsedDatasourceDefinition,
			try root.views.parseDefinition(def3) as! CVUParsedDatasourceDefinition,
		]

		let ds = CascadingDatasource(parsed, nil, Datasource())

		XCTAssertEqual(ds.query, "test")
		XCTAssertEqual(ds.sortProperty, "foo")
		XCTAssertEqual(ds.sortAscending, false)
	}

	//    func testPerformanceExample() throws {
	//        // This is an example of a performance test case.
	//        self.measure {
	//            // Put the code you want to measure the time of here.
	//        }
	//    }
}
