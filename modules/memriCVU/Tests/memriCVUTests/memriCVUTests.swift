//
// memriCVUTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memriCVU
import XCTest

final class memriCVUTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(memriCVU().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
