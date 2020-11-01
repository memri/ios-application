//
// SyncTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class SyncTests: XCTestCase {
    var installer = Installer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
//        installer.installForTesting { error, context in
//            guard let _ = context else { throw "Failed to initialize: \(error!)" }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
