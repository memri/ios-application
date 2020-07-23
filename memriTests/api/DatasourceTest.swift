//
// datasourceTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import RealmSwift
import XCTest

class DatasourceTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUnique() throws {
        let ds1 = Datasource(query: "test", sortProperty: "foo", sortAscending: true)
        let ds2 = Datasource(query: "test", sortProperty: "foo", sortAscending: false)
        let ds3 = Datasource(query: "test", sortProperty: "bar", sortAscending: true)
        let ds4 = Datasource(query: "test", sortProperty: "foo", sortAscending: true)

        XCTAssertNotEqual(ds1.uniqueString, ds2.uniqueString)
        XCTAssertNotEqual(ds1.uniqueString, ds3.uniqueString)
        XCTAssertEqual(ds1.uniqueString, ds4.uniqueString)
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
        try root.boot(isTesting: true)

        let parsed = [
            try root.views.parseDefinition(def1) as! CVUParsedDatasourceDefinition,
            try root.views.parseDefinition(def2) as! CVUParsedDatasourceDefinition,
            try root.views.parseDefinition(def3) as! CVUParsedDatasourceDefinition,
        ]

        let ds = CascadingDatasource(nil, parsed)

        XCTAssertEqual(ds.query, "test")
        XCTAssertEqual(ds.sortProperty, "foo")
        XCTAssertEqual(ds.sortAscending, false)
    }

    func testSubscript() throws {
        let strDef1 = """
        [datasource = pod] {
            query: "test"
            sortProperty: "foo"
            sortAscending: false
        }
        """
        let def1 = CVUStoredDefinition(value: ["definition": strDef1])

        let root = try RootContext(name: "", key: "")
        try root.boot(isTesting: true)
        let head = try root.views.parseDefinition(def1) as! CVUParsedDatasourceDefinition
        let ds = CascadingDatasource(head)

        XCTAssertEqual(ds["query"] as? String, "test")
        XCTAssertEqual(ds["sortProperty"] as? String, "foo")
        XCTAssertEqual(ds["sortAscending"] as? Bool, false)
    }
}
