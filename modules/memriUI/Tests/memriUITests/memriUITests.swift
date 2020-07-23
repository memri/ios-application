//
// memriUITests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memriUI
import XCTest

final class memriUITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(memriUI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
