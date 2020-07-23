//
// realmTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import RealmSwift
import XCTest

class realmTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRealmCreate() throws {
        _ = DatabaseController.getRealm()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
